// TwoStage.bsv
//
// This is a two stage pipelined implementation of the SMIPS processor.

import Types::*;
import ProcTypes::*;
// import MemTypes::*;
import CMemTypes::*;
import RFile::*;
import IMemory::*;
import DMemory::*;
import Decode::*;
import Exec::*;
// import Cop::*;
import Vector::*;
import Fifo::*;
import Ehr::*;
import CsrFile::*;
import GetPut::*;

typedef struct {
    DecodedInst dInst;
    Addr pc;
} F2e deriving (Bits, Eq);

(* synthesize *)
module mkProc(Proc);
    Ehr#(2, Addr) pc <- mkEhr(0);
    // Reg#(Addr) pc <- mkRegU;
    RFile      rf <- mkRFile;
    IMemory  iMem <- mkIMemory;
    DMemory  dMem <- mkDMemory;
    // Cop       cop <- mkCop;
    CsrFile  csrf <- mkCsrFile;

    Bool memReady = iMem.init.done() && dMem.init.done();


    Fifo#(2, F2e) fd2e <- mkCFFifo;
    // TODO: Complete the implementation of this processor

    rule test (!memReady);
        let e = tagged InitDone;
        iMem.init.request.put(e);
        dMem.init.request.put(e);
    endrule

    rule fetch(csrf.started);

        Data inst = iMem.req(pc[0]);
        // decode
        DecodedInst dInst = decode(inst);

        // trace - print the instruction
        $display("pc: %h inst: (%h) expanded: ", pc[0], inst, showInst(inst));
	    $fflush(stdout);
        pc[0] <= pc[0] + 4;
        fd2e.enq(F2e{
            dInst: dInst, 
            pc: pc[0]
        });
    endrule

    rule execute(csrf.started);
        
        let f2e_data = fd2e.first;
        let d_Inst   = f2e_data.dInst;
        let d_pc     = f2e_data.pc;
        let ppc      = d_pc + 4;

        // read general purpose register values 
        Data rVal1 = rf.rd1(fromMaybe(?, d_Inst.src1));
        Data rVal2 = rf.rd2(fromMaybe(?, d_Inst.src2));

        // read CSR values (for CSRR inst)
        Data csrVal = csrf.rd(fromMaybe(?, d_Inst.csr));
        // execute
        ExecInst eInst = exec(d_Inst, rVal1, rVal2, d_pc, ppc, csrVal);
        if(eInst.mispredict) begin
            fd2e.clear;
            pc[1] <= eInst.addr;
        end
        else fd2e.deq;

        // memory
        if(eInst.iType == Ld) begin
            eInst.data <- dMem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
        end else if(eInst.iType == St) begin
            let d <- dMem.req(MemReq{op: St, addr: eInst.addr, data: eInst.data});
        end

        // write back to reg file
        if(isValid(eInst.dst)) begin
            rf.wr(fromMaybe(?, eInst.dst), eInst.data);
        end

        // CSR write for sending data to host & stats
        csrf.wr(eInst.iType == Csrw ? eInst.csr : Invalid, eInst.data);

        // check unsupported instruction at commit time. Exiting
        if(eInst.iType == Unsupported) begin
            $fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", d_pc);
            $finish;
        end
    endrule


    method ActionValue#(CpuToHostData) cpuToHost;
        let ret <- csrf.cpuToHost;
        return ret;
    endmethod

    method Action hostToCpu(Bit#(32) startpc) if ( !csrf.started && memReady );
        csrf.start(0); // only 1 core, id = 0
	$display("Start at pc 200\n");
	$fflush(stdout);
        pc[0] <= startpc;
    endmethod

    interface MemInit iMemInit = iMem.init;
    interface MemInit dMemInit = dMem.init;
endmodule

