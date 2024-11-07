// TwoCycle.bsv
//
// This is a two cycle implementation of the SMIPS processor.

import Types::*;
import ProcTypes::*;
import CMemTypes::*;
import RFile::*;
import IMemory::*;
import DMemory::*;
import Decode::*;
import Exec::*;
import CsrFile::*;
import Vector::*;
import Fifo::*;
import Ehr::*;
import GetPut::*;

typedef enum {Fetch, Execute} Stage deriving (Bits, Eq, FShow);
//Exercise 3
(* synthesize *)
module mkProc(Proc);
    Reg#(Addr) pc <- mkRegU;
    RFile      rf <- mkRFile;
    DMemory   mem <- mkDMemory;
    CsrFile  csrf <- mkCsrFile;

    Bool memReady = mem.init.done();
    Reg#(Stage) stage_ctrl <- mkReg(Fetch);
    Reg#(DecodedInst) fd2e <- mkRegU;

    rule test (!memReady);
        let e = tagged InitDone;
        mem.init.request.put(e);
    endrule
    // TODO: Complete the implementation of this processor
    rule fetch_cycle(csrf.started && stage_ctrl == Fetch);
    
    //fetch instruction
        Data inst <- mem.req(MemReq{op: Ld, addr: pc, data: ?});
       
        // decode
        DecodedInst dInst = decode(inst);

        fd2e <= dInst;
        stage_ctrl <= Execute;
        // trace - print the instruction
        $display("pc: %h inst: (%h) expanded: ", pc, inst, showInst(inst));
	    $fflush(stdout);
    endrule
    
    rule exe_cycle(csrf.started && stage_ctrl == Execute);
        
        // read general purpose register values 
        Data rVal1 = rf.rd1(fromMaybe(?, fd2e.src1));
        Data rVal2 = rf.rd2(fromMaybe(?, fd2e.src2));

        // read CSR values (for CSRR inst)
        Data csrVal = csrf.rd(fromMaybe(?, fd2e.csr));
        // execute
        ExecInst eInst = exec(fd2e, rVal1, rVal2, pc, ?, csrVal);  
        // check unsupported instruction at commit time. Exiting
        if(eInst.iType == Unsupported) begin
            $fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", pc);
            $finish;
        end

        //PC .if branch hit ,jump.else PC + 4
        pc <= eInst.brTaken ? eInst.addr : pc + 4;

        // memory
        if(eInst.iType == Ld) begin
            eInst.data <- mem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
        end else if(eInst.iType == St) begin
            let d <- mem.req(MemReq{op: St, addr: eInst.addr, data: eInst.data});
        end
        // write back to reg file
        if(isValid(eInst.dst)) begin
            rf.wr(fromMaybe(?, eInst.dst), eInst.data);
        end

        // CSR write for sending data to host & stats
        csrf.wr(eInst.iType == Csrw ? eInst.csr : Invalid, eInst.data);
        stage_ctrl <= Fetch;

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

