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
    Vector#(n, Reg#(t))     data     <- replicateM(mkRegU());
    Ehr#(3, Bit#(TLog#(n))) enqP     <- mkEhr(0);
    Ehr#(3, Bit#(TLog#(n))) deqP     <- mkEhr(0);
    Ehr#(3, Bool)           empty    <- mkEhr(True);
    Ehr#(3, Bool)           full     <- mkEhr(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);

    method Bool notFull();
        return !full[1];
    endmethod

    method Action enq(t x) if (!full[1]);
        data[enqP[1]] <= x;
        let next_enqP = enqP[1] + 1;
        if (next_enqP > max_index) begin
            next_enqP = 0;
        end
        if (next_enqP == deqP[1]) begin
            full[1] <= True;
        end
        enqP[1] <= next_enqP;
        empty[1] <= False;
    endmethod

    method Bool notEmpty();
        return !empty[0];
    endmethod

    method Action deq() if (!empty[0]);
        let next_deqP = deqP[0] + 1;
        if (next_deqP > max_index) begin
            next_deqP = 0;
        end
        if (next_deqP == enqP[0]) begin
            empty[0] <= True;
        end
        deqP[0] <= next_deqP;
        full[0] <= False;
    endmethod

    method t first() if (!empty[0]);
        return data[deqP[0]];
    endmethod

    method Action clear();
        enqP[2] <= 0;
        deqP[2] <= 0;
        empty[2] <= True;
        full[2] <= False;
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

