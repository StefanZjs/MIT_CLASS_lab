import Ehr::*;
import Vector::*;

interface Fifo#(numeric type n, type t);
    method Bool notFull;
    method Action enq(t x);
    method Bool notEmpty;
    method Action deq;
    method t first;
endinterface

// Two element conflict-free fifo from lecture
module mkCFFifo( Fifo#(2, t) ) provisos (Bits#(t, tSz));
    Ehr#(2, t) da <- mkEhr(?);
    Ehr#(2, Bool) va <- mkEhr(False);
    Ehr#(2, t) db <- mkEhr(?);
    Ehr#(2, Bool) vb <- mkEhr(False);

    rule canonicalize;
        if( vb[1] && !va[1] ) begin
            da[1] <= db[1];
            va[1] <= True;
            vb[1] <= False;
        end
    endrule

    method Bool notFull();
        return !vb[0];
    endmethod

    method Bool notEmpty();
        return va[0];
    endmethod
//Exercise 1 (5 Points): As a warmup, add guards to the enq, deq, and first methods of the two-element conflict-free FIFO
    method Action enq(t x) if(!vb[0]); // not full , be able to write in 
        db[0] <= x;
        vb[0] <= True;
    endmethod

    method Action deq() if(va[0]); // not empty ,be able to read out
        va[0] <= False;
    endmethod

    method t first if(va[0]); // not empty 
        return da[0];
    endmethod
endmodule

