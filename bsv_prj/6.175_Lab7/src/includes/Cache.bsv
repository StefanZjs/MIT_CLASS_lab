import CacheTypes::*;
import MemUtil::*;
import Fifo::*;
import Vector::*;
import Types::*;
import CMemTypes::*;
import Memory::*;

// function WideMemReq tans2wideMemreq(MemReq req_mem);
//     Bit#(CacheLineWords) word_enable = 0;

//     CacheWordSelect  index = req_mem.addr[valueOf(TLog#(CacheLineWords))+1:2];

//     if(req_mem.op == St) begin  //only store do write
//         //remove lower 2 bit
//         //then move enbale to where we want
//         word_enable = 1<<(index);
//     end

//     Addr addr = req_mem.addr;

//     CacheLine data = newVector;
//     data[index] = req_mem.data;

//     return WideMemReq {
//         write_en: word_enable,
//         addr: addr,
//         data: data
//     };

// endfunction

module mkTranslator(WideMem wideMem, 
                    Cache ifc);

    Fifo#(2, MemReq)  transFIFO <- mkCFFifo;

    method Action req(MemReq r);
        // $display("TranslatorREQ: PC = %x", r.addr);
        if(r.op == Ld)
            transFIFO.enq(r);
        //send req to 
        wideMem.req(toWideMemReq(r));
    endmethod


    method ActionValue#(MemResp) resp;
        //only load has response
        let mem_req = transFIFO.first;
        transFIFO.deq;
        // $display("TranslatorRESP: PC = %x", mem_req.addr);

        CacheWordSelect wordsel = truncate( mem_req.addr >> 2 );

        let cacheLine <- wideMem.resp;

        return cacheLine[wordsel];
    endmethod


endmodule

module mkCache (WideMem wideMem, 
                Cache ifc);

    // RegFile#(CacheIndex, CacheLine)       dataArray <- mkRegFileFull;
    // RegFile#(CacheIndex, Maybe#(CacheTag)) tagArray <- mkRegFileFull;
    // RegFile#(CacheIndex, Bool)           dirtyArray <- mkRegFileFull;

    Vector#(CacheRows, Reg#(CacheLine))       dataArray <- replicateM(mkRegU);
    Vector#(CacheRows, Reg#(Maybe#(CacheTag))) tagArray <- replicateM(mkReg(tagged Invalid));
    Vector#(CacheRows, Reg#(Bool))           dirtyArray <- replicateM(mkReg(False));


    Fifo#(1, Data)          hitQ  <- mkBypassFifo;
    Reg#(MemReq)          missReq <- mkRegU;
    Reg#(CacheStatus)        mshr <- mkReg(Ready);

    // Fifo#(2, MemReq)     memReqQ <-mkCFFifo;
    // Fifo#(2, CacheLine) memRespQ <-mkCFFifo;

    rule startMiss(mshr == StartMiss);
        let idx = getIdx(missReq.addr); 
        let tag = tagArray[idx]; 
        let dirty = dirtyArray[idx];
        if(isValid(tag) && dirty) begin // write-back
            let addr = {fromMaybe(?,tag), idx, 6'b0};
            let data = dataArray[idx];
            // memReqQ.enq(MemReq{op: St, addr: addr, data: data});
            // wideMem.req(toWideMemReq(MemReq{op: St, addr: addr, data: data}));
            wideMem.req(WideMemReq{write_en: 1, addr: addr, data: data});
        end
        mshr <= SendFillReq;

    endrule

    rule sendFillReq(mshr == SendFillReq);
        // memReqQ.enq(missReq);   
        wideMem.req(toWideMemReq(missReq));
        mshr <= WaitFillResp;
    endrule

    rule waitFillResp(mshr == WaitFillResp);
        let idx  = getIdx(missReq.addr);
        let tag  = getTag(missReq.addr);
        // let data = memRespQ.first;
        let data <- wideMem.resp;
        let wOffset = getOffset(missReq.addr);

        tagArray[idx] <= Valid (tag);

        if(missReq.op== Ld) begin
            dirtyArray[idx] <= False;
            dataArray[idx] <=  data;
            hitQ.enq(data[wOffset]); 
        end
        else begin 
            data[wOffset] = missReq.data;    
            dirtyArray[idx] <= True; 
            dataArray[idx] <=  data;
        end
        // memRespQ.deq; 
        mshr<= Ready;
    endrule

    //cache in req
    method Action req(MemReq r) if(mshr == Ready);
        let idx     = getIdx(r.addr); 
        let tag     = getTag(r.addr);
        let wOffset = getOffset(r.addr);
        let currTag = tagArray[idx];
        let hit     = isValid(currTag) ? fromMaybe(?,currTag)==tag : False; 
        if(hit) begin
            let x = dataArray[idx];
            if(r.op == Ld) 
                hitQ.enq(x[wOffset]);
            else begin 
                x[wOffset] = r.data; 
                dataArray[idx] <= x;
                dirtyArray[idx] <= True; 
            end
        end
        // if not hit, start to fetch data
        else begin 
            missReq <= r; 
            mshr    <= StartMiss; 
        end
    endmethod

        //cache out to cpu
    method ActionValue#(MemResp) resp;
        hitQ.deq;
        return hitQ.first;
    endmethod


endmodule