// Six stage

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
import Btb::*;
import Scoreboard::*;
import FPGAMemory::*;
import DelayedMemory::*;

typedef struct {
    Addr pc;
    Addr predPc;
    // Data inst;
    Bool epoch;
} Fetch2Decode deriving (Bits, Eq);
typedef struct {
    Addr pc;
    Addr predPc;
    DecodedInst dInst;
    Bool epoch;
} Decode2RegF deriving (Bits, Eq);
typedef struct {
    Addr pc;
    Addr predPc;
    DecodedInst dInst;
    Data rVal1;
    Data rVal2;
    Data csrVal;
    Bool epoch;
} RegF2Execute deriving (Bits, Eq);
typedef struct {
    ExecInst    eInst;
} Execute2Mem deriving (Bits, Eq);
typedef struct {
    ExecInst    eInst;
} Mem2Wb deriving (Bits, Eq);


// redirect msg from Execute stage
typedef struct {
	Addr pc;
	Addr nextPc;
} ExeRedirect deriving (Bits, Eq);
(* synthesize *)
module mkProc(Proc);
    Ehr#(2, Addr) pcReg <- mkEhr(?);
    RFile            rf <- mkRFile;
	Scoreboard#(6)   sb <- mkCFScoreboard;
	FPGAMemory        iMem <- mkFPGAMemory;
    FPGAMemory        dMem <- mkFPGAMemory;
    CsrFile        csrf <- mkCsrFile;
    Btb#(6)         btb <- mkBtb; // 64-entry BTB

    // global epoch for redirection from Execute stage
	Reg#(Bool) exeEpoch <- mkReg(False);

	// EHR for redirection
	Ehr#(2, Maybe#(ExeRedirect)) exeRedirect <- mkEhr(Invalid);

    // FIFO between two stages
	Fifo#(1, Fetch2Decode)  f2dFifo <- mkBypassFifo;
    Fifo#(2, Decode2RegF)  d2rfFifo <- mkBypassFifo;
    Fifo#(2, RegF2Execute) rf2eFifo <- mkBypassFifo;
    Fifo#(2, Execute2Mem)  e2mmFifo <- mkBypassFifo;
    Fifo#(2, Mem2Wb)      mm2wbFifo <- mkBypassFifo;
    
    Bool memReady = iMem.init.done && dMem.init.done;
    rule test (!memReady);
        let e = tagged InitDone;
        iMem.init.request.put(e);
        dMem.init.request.put(e);
    endrule
    rule fetch_stage(csrf.started);
        // fetch
		// Data inst = iMem.req(pcReg[0]);
        iMem.req(MemReq{op: Ld, addr: pcReg[0], data: ?});
        Addr predPc = btb.predPc(pcReg[0]);
        pcReg[0] <= predPc;
        Fetch2Decode f2d = Fetch2Decode{
            pc:pcReg[0],
            predPc:predPc,
            // inst:inst,
            epoch:exeEpoch
        };
        f2dFifo.enq(f2d);
        $display("Fetch: PC = %x", pcReg[0]);
    endrule
    rule decode_stage(csrf.started);
        f2dFifo.deq;
        let f_inst = f2dFifo.first;
        let inst <- iMem.resp;

            // decode
        DecodedInst dInst = decode(inst);

        Decode2RegF d2rf = Decode2RegF{
            pc: f_inst.pc,
            predPc: f_inst.predPc,
            dInst: dInst, 
            epoch: f_inst.epoch
        };

        // search scoreboard to determine stall
        if(!sb.search1(dInst.src1) && !sb.search2(dInst.src2)) begin
            // enq & update PC, sb
            d2rfFifo.enq(d2rf);
            // pcReg[0] <= btb.predPc(pcReg[0]);//f_inst.predPc;
            sb.insert(dInst.dst);
            
            $display("Decode: PC = %x, inst = %x, expanded = ", f_inst.pc, inst, showInst(inst));
        end
        else begin
            $display("Decode: Stalled: PC = %x", f_inst.pc);
        end
        
    endrule
    rule regf_stage(csrf.started);
        d2rfFifo.deq;
        let d_inst = d2rfFifo.first;

        // reg read
		Data rVal1 = rf.rd1(fromMaybe(?, d_inst.dInst.src1));
		Data rVal2 = rf.rd2(fromMaybe(?, d_inst.dInst.src2));
		Data csrVal = csrf.rd(fromMaybe(?, d_inst.dInst.csr));

        RegF2Execute rf2e = RegF2Execute{
            pc: d_inst.pc,
            predPc: d_inst.predPc,
            dInst: d_inst.dInst, 
            rVal1: rVal1,
            rVal2: rVal2,
            csrVal: csrVal,
            epoch: d_inst.epoch
        };
        rf2eFifo.enq(rf2e);
        $display("Reg_f: PC = %x", d_inst.pc);
    endrule
    rule execute_stage(csrf.started);
        rf2eFifo.deq;
        let ctrl_inst = rf2eFifo.first;

        if(ctrl_inst.epoch != exeEpoch) begin
			// kill wrong-path inst, just deq sb
			sb.remove;
			$display("Execute: Kill instruction, PC = %x",ctrl_inst.pc);
		end
		else begin
            // execute
            ExecInst eInst = exec(ctrl_inst.dInst, ctrl_inst.rVal1, ctrl_inst.rVal2, ctrl_inst.pc, ctrl_inst.predPc, ctrl_inst.csrVal);  
                        
            // csrf.wr(eInst.iType == Csrw ? eInst.csr : Invalid, eInst.data);

            // memory
            e2mmFifo.enq(Execute2Mem{eInst:eInst});

            // check unsupported instruction at commit time. Exiting
            if(eInst.iType == Unsupported) begin
                $fwrite(stderr, "ERROR: Executing unsupported instruction at pc: %x. Exiting\n", ctrl_inst.pc);
                $finish;
            end

            if(eInst.mispredict) begin
				$display("Execute finds misprediction: PC = %x, DST_ADDR = %x", ctrl_inst.pc,eInst.addr);
				exeRedirect[0] <= Valid (ExeRedirect {
					pc: ctrl_inst.pc,
					nextPc: eInst.addr
				});
			end
			else begin
				$display("Execute: PC = %x", ctrl_inst.pc);
			end
        end
        
    endrule
    rule mem_stage(csrf.started);
        e2mmFifo.deq();
        let e_inst = e2mmFifo.first;

        if(e_inst.eInst.iType == Ld) begin
            // e_inst.eInst.data <- dMem.req(MemReq{op: Ld, addr: e_inst.eInst.addr, data: ?});
            dMem.req(MemReq{op: Ld, addr: e_inst.eInst.addr, data: ?});
        end else if(e_inst.eInst.iType == St) begin
            dMem.req(MemReq{op: St, addr: e_inst.eInst.addr, data: e_inst.eInst.data});
        end

        mm2wbFifo.enq(Mem2Wb{eInst:e_inst.eInst});
    endrule
    rule wb_stage(csrf.started);
        mm2wbFifo.deq();
        let e_inst = mm2wbFifo.first;

        if(e_inst.eInst.iType == Ld)
            e_inst.eInst.data <- dMem.resp;
        // write back to reg file
        if(isValid(e_inst.eInst.dst)) begin
            rf.wr(fromMaybe(?, e_inst.eInst.dst), e_inst.eInst.data);
        end

        csrf.wr(e_inst.eInst.iType == Csrw ? e_inst.eInst.csr : Invalid, e_inst.eInst.data);
        $display("wb_stage");
        // remove from scoreboard
			sb.remove;
    endrule

    (* fire_when_enabled *)
	(* no_implicit_conditions *)
	rule cononicalizeRedirect(csrf.started);
		if(exeRedirect[1] matches tagged Valid .r) begin
			// fix mispred
			pcReg[1] <= r.nextPc;
			exeEpoch <= !exeEpoch; // flip epoch
			btb.update(r.pc, r.nextPc); // train BTB
			$display("Fetch: Mispredict, redirected by Execute");
		end
		// reset EHR
		exeRedirect[1] <= Invalid;
	endrule

    method ActionValue#(CpuToHostData) cpuToHost;
        let ret <- csrf.cpuToHost;
        return ret;
    endmethod

    method Action hostToCpu(Bit#(32) startpc) if ( !csrf.started && memReady );
		csrf.start(0); // only 1 core, id = 0
		$display("Start at pc 200\n");
		$fflush(stdout);
        pcReg[0] <= startpc;
    endmethod

	interface iMemInit = iMem.init;
    interface dMemInit = dMem.init;
endmodule