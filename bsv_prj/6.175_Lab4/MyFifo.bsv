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


    // TODO: Implement all the methods for this module
    method Action clear;
        enqP <= 0;
        deqP <= 0;
        empty <= True;
        full <= False;
    endmethod

    method Action enq(t x) if( !full );
        Bit#(TLog#(n)) next_enqP;

        next_enqP = (enqP == max_index) ? 0 : enqP + 1;
        enqP        <= next_enqP;
        if(next_enqP == deqP) 
            full <= True;

        empty <= False;
        data[enqP]  <= x;
    endmethod

    method Bool notFull();
        return !full;
    endmethod

    method Bool notEmpty();
        return !empty;
    endmethod

    method Action deq if( !empty );
        Bit#(TLog#(n)) next_deqP;
        next_deqP = (deqP == max_index) ? 0 : deqP + 1;

        full <= False;
        if( next_deqP == enqP ) begin
            empty <= True;
        end
        
        deqP <= next_deqP;
    endmethod

    method t first if( !empty );
        return data[deqP];
    endmethod

endmodule

//Exercise 2
/////////////////
// Pipeline FIFO

// Intended schedule:
//      {notEmpty, first, deq} < {notFull, enq} < clear
module mkMyPipelineFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
    Vector#(n, Reg#(t))              data       <- replicateM(mkRegU());
    Ehr#(3, Bit#(TLog#(TAdd#(n,1)))) elem_count <- mkEhr(0);
    Ehr#(3, Bit#(TLog#(n)))          enq_p      <- mkEhr(0);
    Ehr#(3, Bit#(TLog#(n)))          deq_p      <- mkEhr(0);

    method Action clear;
        enq_p[2]      <= 0;
        deq_p[2]      <= 0;
        elem_count[2] <= 0;
    endmethod

    method Action enq(t x) if(elem_count[1] != fromInteger(valueOf(n)));
        enq_p[1]       <= enq_p[1] + 1;
        elem_count[1]  <= elem_count[1] + 1;
        data[enq_p[1]] <= x;
    endmethod

    method Bool notFull();
        return elem_count[1] != fromInteger(valueOf(n));
    endmethod

    method Bool notEmpty();
        return elem_count[0] != 0;
    endmethod

    method Action deq if(elem_count[0] != 0);
        deq_p[0]       <= deq_p[0] + 1;
        elem_count[0]  <= elem_count[0] - 1;
    endmethod

    method t first if (elem_count[0] != 0);
        return data[deq_p[0]];
    endmethod

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

