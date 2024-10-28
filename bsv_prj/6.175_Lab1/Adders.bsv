import Multiplexer::*;

// Full adder functions

function Bit#(1) fa_sum( Bit#(1) a, Bit#(1) b, Bit#(1) c_in );
    return xor1( xor1( a, b ), c_in );
endfunction

function Bit#(1) fa_carry( Bit#(1) a, Bit#(1) b, Bit#(1) c_in );
    return or1( and1( a, b ), and1( xor1( a, b ), c_in ) );
endfunction

// 4 Bit full adder
//Exercise 4 (2 Points): Complete the code for add4 by using a for loop to properly connect all the uses of fa_sum and fa_carry.
function Bit#(5) add4( Bit#(4) a, Bit#(4) b, Bit#(1) c_in );
    // ripple-carry adder
    Bit#(4) sum_out;
    Bit#(4) carr_out = 0;
    /*********************** studente code start *********************/
    for (Integer i = 0; i < 4; i=i+1) begin
        if(i == 0) begin
            sum_out[i]  = fa_sum(  a[i],b[i],c_in);
            carr_out[i] = fa_carry(a[i],b[i],c_in);
        end
        else begin
            sum_out[i]  = fa_sum(  a[i],b[i],carr_out[i-1]);
            carr_out[i] = fa_carry(a[i],b[i],carr_out[i-1]);
        end
    end
    return {carr_out[3],sum_out};
    /*********************** studente code end  *********************/
endfunction

// Adder interface

interface Adder8;
    method ActionValue#( Bit#(9) ) sum( Bit#(8) a, Bit#(8) b, Bit#(1) c_in );
endinterface

// Adder modules

// RC = Ripple Carry
module mkRCAdder( Adder8 );
    method ActionValue#( Bit#(9) ) sum( Bit#(8) a, Bit#(8) b, Bit#(1) c_in );
        Bit#(5) lower_result = add4( a[3:0], b[3:0], c_in );
        Bit#(5) upper_result = add4( a[7:4], b[7:4], lower_result[4] );
        return { upper_result , lower_result[3:0] };
    endmethod
endmodule

//Exercise 5 (5 Points): Complete the code for the carry-select adder in the module mkCSAdder
// CS = Carry Select
module mkCSAdder( Adder8 );
    method ActionValue#( Bit#(9) ) sum( Bit#(8) a, Bit#(8) b, Bit#(1) c_in );
        Bit#(5) lower_result  = add4( a[3:0], b[3:0], c_in );
        Bit#(5) upper_result0 = add4( a[7:4], b[7:4], 0 );
        Bit#(5) upper_result1 = add4( a[7:4], b[7:4], 1 );
        Bool    lower_carry   = unpack(lower_result[4]);
        Bit#(1) carry_out     = lower_carry ? upper_result1[4]   : upper_result0[4];
        Bit#(4) upper_sum     = lower_carry ? upper_result1[3:0] : upper_result0[3:0];

        return {carry_out,upper_sum,lower_result[3:0]};
    endmethod
endmodule

