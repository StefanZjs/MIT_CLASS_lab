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
