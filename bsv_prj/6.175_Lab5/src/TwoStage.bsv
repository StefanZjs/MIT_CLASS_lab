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

(* synthesize *)
module mkProc(Proc);
    Reg#(Addr) pc <- mkRegU;
    RFile      rf <- mkRFile;
    IMemory  iMem <- mkIMemory;
    DMemory  dMem <- mkDMemory;
    // Cop       cop <- mkCop;
    CsrFile  csrf <- mkCsrFile;

    Bool memReady = iMem.init.done() && dMem.init.done();


    Fifo#(2, DecodedInst) fd2e <- mkBypassFifo;
    // TODO: Complete the implementation of this processor

    rule test (!memReady);
        let e = tagged InitDone;
        iMem.init.request.put(e);
        dMem.init.request.put(e);
    endrule

    rule fetch(csrf.started);

        Data inst = iMem.req(pc);
        // decode
        DecodedInst dInst = decode(inst);

        // trace - print the instruction
        $display("pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
	    $fflush(stdout);
        
        fd2e.enq(dInst);
    endrule

    rule execute(csrf.started);
        fd2e.deq;
        let d_Inst = fd2e.first;
        let ppc = pc + 4;

        // read general purpose register values 
        Data rVal1 = rf.rd1(fromMaybe(?, d_Inst.src1));
        Data rVal2 = rf.rd2(fromMaybe(?, d_Inst.src2));

        // read CSR values (for CSRR inst)
        Data csrVal = csrf.rd(fromMaybe(?, d_Inst.csr));
        // execute
        ExecInst eInst = exec(d_Inst, rVal1, rVal2, pc, ppc, csrVal);
        if(eInst.mispredict)
            fd2e.clear;

        // update the pc depending on whether the branch is taken or not
        pc <= eInst.mispredict ? eInst.addr : ppc;

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
            $fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", pc);
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
        pc <= startpc;
    endmethod

    interface MemInit iMemInit = iMem.init;
    interface MemInit dMemInit = dMem.init;
endmodule

