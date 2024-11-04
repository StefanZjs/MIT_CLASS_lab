import Ehr::*;
import Vector::*;

//////////////////
// Fifo interface 

interface Fifo#(numeric type n, type t);
    method Bool notFull;
    method Action enq(t x);
    method Bool notEmpty;
    method Action deq;
    method t first;
    method Action clear;
endinterface

//Exercise 1 (5 points): Implement mkMyConflictFifo
/////////////////
// Conflict FIFO

module mkMyConflictFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
    Vector#(n, Reg#(t))     data     <- replicateM(mkRegU());
    Reg#(Bit#(TLog#(n)))    enqP     <- mkReg(0);
    Reg#(Bit#(TLog#(n)))    deqP     <- mkReg(0);
    Reg#(Bool)              empty    <- mkReg(True);
    Reg#(Bool)              full     <- mkReg(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);

    Reg#(Bit#(TLog#(n)))    fifo_cnt <- mkReg(0);

    // TODO: Implement all the methods for this module
    rule empty_gen;
        if(enqP == deqP && fifo_cnt == 0) begin
            empty <= True;
        end else begin
            empty <= False;
        end
    endrule

    rule full_gen;
        if(enqP == deqP  && fifo_cnt == max_index) begin
            full <= True;
        end else begin
            full <= False;
        end
    endrule

    method Action clear;
        enqP <= 0;
        deqP <= 0;
        fifo_cnt <= 0;
    endmethod

    method Action enq(t x);
        enqP        <= enqP + 1;
        fifo_cnt    <= fifo_cnt + 1;
        data(enqP)  <= x;
    endmethod

    method Bool notFull();
        return !full;
    endmethod

    method Bool notEmpty();
        return !empty;
    endmethod

    method Action deq ;
        deqP     <= deqP + 1;
        fifo_cnt <= fifo_cnt - 1;
    endmethod

    method t first;
        return data(deqP);
    endmethod

endmodule

/////////////////
// Pipeline FIFO

// Intended schedule:
//      {notEmpty, first, deq} < {notFull, enq} < clear
module mkMyPipelineFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
endmodule

/////////////////////////////
// Bypass FIFO without clear

// Intended schedule:
//      {notFull, enq} < {notEmpty, first, deq} < clear
module mkMyBypassFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
endmodule

//////////////////////
// Conflict free fifo

// Intended schedule:
//      {notFull, enq} CF {notEmpty, first, deq}
//      {notFull, enq, notEmpty, first, deq} < clear
module mkMyCFFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
endmodule

