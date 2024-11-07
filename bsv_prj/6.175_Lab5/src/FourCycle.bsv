// FourCycle.bsv
//
// This is a four cycle implementation of the SMIPS processor.

import Types::*;
import ProcTypes::*;
// import MemTypes::*;
import CMemTypes::*;
import RFile::*;
import DelayedMemory::*;
import MemInit::*;
import Decode::*;
import Exec::*;
// import Cop::*;
import Vector::*;
import Fifo::*;
import Ehr::*;
import GetPut::*;
import CsrFile::*;

typedef enum {Fetch, Decode, Execute, WriteBack} Stage deriving (Bits, Eq, FShow);

(* synthesize *)
module mkProc(Proc);
    Reg#(Addr)     pc <- mkRegU;
    RFile          rf <- mkRFile;
    DelayedMemory mem <- mkDelayedMemory;
    CsrFile      csrf <- mkCsrFile;

    // MemInitIfc dummyMemInit <- mkDummyMemInit;
    Bool memReady = mem.init.done() ;//&& dummyMemInit.done();
    // Reg#(Data)          f2d <- mkRegU;
    Reg#(DecodedInst)   d2e <- mkRegU;
    Reg#(ExecInst)     e2wb <- mkRegU;

    Reg#(Stage) stage_ctrl <- mkReg(Fetch);
    // TODO: Complete the implementation of this processor
    rule test (!memReady);
        let e = tagged InitDone;
        mem.init.request.put(e);
    endrule

    rule fetch_cycle(csrf.started && stage_ctrl == Fetch);
        stage_ctrl <= Decode;
        mem.req(MemReq{op: Ld, addr: pc, data: ?});
    endrule

    rule decode_cycle(csrf.started && stage_ctrl == Decode);
        stage_ctrl <= Execute;
        Data inst <- mem.resp();
        // trace - print the instruction
        $display("pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
	    $fflush(stdout);

        DecodedInst dInst = decode(inst);
        d2e <= dInst;
    endrule
    rule execute_cycle(csrf.started && stage_ctrl == Execute);
    $display("execute_cycle");

        stage_ctrl <= WriteBack;

        // read CSR values (for CSRR inst)
        Data csrVal = csrf.rd(fromMaybe(?, d2e.csr));
        // read general purpose register values 
        Data rVal1 = rf.rd1(fromMaybe(?, d2e.src1));
        Data rVal2 = rf.rd2(fromMaybe(?, d2e.src2));

        ExecInst eInst = exec(d2e, rVal1, rVal2, pc, ?, csrVal);
        // check unsupported instruction at commit time. Exiting
        if(eInst.iType == Unsupported) begin
            $fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", pc);
            $finish;
        end
        //PC .if branch hit ,jump.else PC + 4
        pc <= eInst.brTaken ? eInst.addr : pc + 4;

        // memory
        if(eInst.iType == Ld) begin
            mem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
        end else if(eInst.iType == St) begin
            let d <- mem.req(MemReq{op: St, addr: eInst.addr, data: eInst.data});
        end

        csrf.wr(eInst.iType == Csrw ? eInst.csr : Invalid, eInst.data);

        e2wb <= eInst;
        
    endrule
    rule wb_cycle(csrf.started && (stage_ctrl == WriteBack));

        stage_ctrl <= Fetch;

        let ld_data = e2wb.data;

        if (e2wb.iType == Ld) begin
            ld_data <- mem.resp();
        end
        // write back to reg file
        if(isValid(e2wb.dst))
            rf.wr(fromMaybe(?, e2wb.dst), ld_data);

        // csrf.wr(e2wb.iType == Csrw ? e2wb.csr : Invalid, e2wb.data);
    endrule

    method ActionValue#(CpuToHostData) cpuToHost;
        let ret <- csrf.cpuToHost;
        return ret;
    endmethod

    method Action hostToCpu(Bit#(32) startpc) if ( !csrf.started && memReady );
        csrf.start(0); // only 1 core, id = 0
	    $display("Start at pc 200\n");
	    $fflush(stdout);
        pc <= startpc;
    endmethod

    interface MemInit iMemInit = mem.init;
    interface MemInit dMemInit = mem.init;
endmodule

