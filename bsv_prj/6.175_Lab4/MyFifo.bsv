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
    Vector#(n, Ehr#(3, t)) data     <- replicateM(mkEhrU());
    Ehr#(3, Bit#(TLog#(n))) enqP     <- mkEhr(0);
    Ehr#(3, Bit#(TLog#(n))) deqP     <- mkEhr(0);
    Ehr#(3, Bool)           empty    <- mkEhr(True);
    Ehr#(3, Bool)           full     <- mkEhr(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);

    method Bool notFull();
        return !full[0];
    endmethod   

    method Action enq(t x) if (!full[0]);
        data[enqP[0]][0] <= x;
        let next_enqP = enqP[0] + 1;
        if (next_enqP > max_index) begin
            next_enqP = 0;
        end
        if (next_enqP == deqP[0]) begin
            full[0] <= True;
        end
        enqP[0] <= next_enqP;
        empty[0] <= False;
    endmethod

    method Bool notEmpty();
        return !empty[1];
    endmethod

    method Action deq() if (!empty[1]);
        let next_deqP = deqP[1] + 1;
        if (next_deqP > max_index) begin
            next_deqP = 0;
        end
        if (next_deqP == enqP[1]) begin
            empty[1] <= True;
        end
        deqP[1] <= next_deqP;
        full[1] <= False;
    endmethod

    method t first() if (!empty[1]);
        return data[deqP[1]][1];
    endmethod

    method Action clear();
        enqP[2] <= 0;
        deqP[2] <= 0;
        empty[2] <= True;
        full[2] <= False;
    endmethod
endmodule

//////////////////////
// Conflict free fifo

// Intended schedule:
//      {notFull, enq} CF {notEmpty, first, deq}
//      {notFull, enq, notEmpty, first, deq} < clear
module mkMyCFFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
    Vector#(n, Reg#(t))     data     <- replicateM(mkRegU());
    Reg#(Bit#(TLog#(n)))    enqP     <- mkReg(0);
    Reg#(Bit#(TLog#(n)))    deqP     <- mkReg(0);
    Reg#(Bool)              empty    <- mkReg(True);
    Reg#(Bool)              full     <- mkReg(False);

    Ehr#(2, Maybe#(t))         enqEhr   <- mkEhr(tagged Invalid);
    Ehr#(2, Maybe#(Bit#(0)))   deqEhr   <- mkEhr(tagged Invalid);
    Ehr#(2, Bool)              clearEhr <- mkEhr(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);
    (* no_implicit_conditions *)
    (* fire_when_enabled *)
    rule process_ctrl;
        if( clearEhr[1] ) begin
            enqP <= 0;
            deqP <= 0;
            full <= False;
            empty <= True;
        end else begin
            let next_enqP = enqP;
            let next_deqP = deqP;
            let next_full = full;
            let next_empty = empty;

            if( isValid(enqEhr[1]) ) begin
                data[enqP] <= fromMaybe(?, enqEhr[1]);
                next_enqP = (enqP == max_index) ? 0 : enqP + 1;
            end
            if( isValid(deqEhr[1]) ) begin
                next_deqP = (deqP == max_index) ? 0 : deqP + 1;
            end

            if( next_deqP == next_enqP ) begin
                if( isValid(enqEhr[1]) ) begin
                    next_full = True;
                end else if( isValid(deqEhr[1]) ) begin
                    next_empty = True;
                end 
            end else begin
                next_full = False;
                next_empty = False;
            end

            enqP <= next_enqP;
            deqP <= next_deqP;
            full <= next_full;
            empty <= next_empty;
        end
        enqEhr[1] <= tagged Invalid;
        deqEhr[1] <= tagged Invalid;
    endrule

    method Bool notFull = !full;

    method Action enq(t x) if( !full );
        enqEhr[0] <= tagged Valid x;
    endmethod

    method Bool notEmpty = !empty;

    method Action deq if( !empty );
        deqEhr[0] <= tagged Valid 0;
    endmethod

    method t first if( !empty );
        return data[deqP];
    endmethod

    method Action clear;
        enqEhr[1] <= tagged Invalid;
        deqEhr[1] <= tagged Invalid;
        clearEhr[0] <= True;
    endmethod

endmodule

