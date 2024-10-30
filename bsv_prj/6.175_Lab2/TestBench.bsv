import TestBenchTemplates::*;
import Multipliers::*;

// Example testbenches
(* synthesize *)
module mkTbDumb();
    function Bit#(16) test_function( Bit#(8) a, Bit#(8) b ) = multiply_unsigned( a, b );
    Empty tb <- mkTbMulFunction(test_function, multiply_unsigned, True);
    return tb;
endmodule

(* synthesize *)
module mkTbFoldedMultiplier();
    Multiplier#(8) dut <- mkFoldedMultiplier();
    Empty tb <- mkTbMulModule(dut, multiply_signed, True);
    return tb;
endmodule

//Exercise 1 (2 Points): that test if multiply_signed produces the same output as multiply_unsigned.
(* synthesize *)
module mkTbSignedVsUnsigned();
    // TODO: Implement test bench for Exercise 1
    /*********************** studente code start *********************/
    // Empty tb <- mkTbMulFunction(multiply_signed( Bit#(8) a, Bit#(8) b ), multiply_unsigned( Bit#(8) a, Bit#(8) b ), True);
    function Bit#(TAdd#(8,8)) signed_func( Bit#(8) a, Bit#(8) b ) = multiply_signed( a, b );
    function Bit#(TAdd#(8,8)) unsigned_func( Bit#(8) a, Bit#(8) b ) = multiply_unsigned( a, b );
    Empty tb <- mkTbMulFunction(signed_func, unsigned_func, True);

    return tb;
    /*********************** studente code end  *********************/
endmodule

//test the functionality of multiply_by_adding
(* synthesize *)
module mkTbEx3();
    // TODO: Implement test bench for Exercise 3
    /*********************** studente code start *********************/
    function Bit#(16) add2mul(Bit#(8) a, Bit#(8) b ) = multiply_by_adding(a,b);
    Empty tb <- mkTbMulFunction(add2mul, multiply_unsigned, True);
    return tb;
    /*********************** studente code end  *********************/
endmodule

(* synthesize *)
module mkTbEx5();
    // TODO: Implement test bench for Exercise 5
    /*********************** studente code start *********************/
    Multiplier#(16) dut <- mkFoldedMultiplier();
    Empty tb <- mkTbMulModule(dut, multiply_by_adding, True);
    return tb;
    /*********************** studente code end  *********************/
endmodule

(* synthesize *)
module mkTbEx7a();
    // TODO: Implement test bench for Exercise 7
    /*********************** studente code start *********************/
    Multiplier#(16) dut <- mkBoothMultiplier();
    Empty tb <- mkTbMulModule(dut, multiply_signed, True);
    return tb;
    /*********************** studente code end  *********************/
endmodule

(* synthesize *)
module mkTbEx7b();
    // TODO: Implement test bench for Exercise 7
    /*********************** studente code start *********************/
    Multiplier#(32) dut <- mkBoothMultiplier();
    Empty tb <- mkTbMulModule(dut, multiply_signed, True);
    return tb;
    /*********************** studente code end  *********************/
endmodule

(* synthesize *)
module mkTbEx9a();
    // TODO: Implement test bench for Exercise 9
    /*********************** studente code start *********************/
    Multiplier#(16) dut <- mkBoothMultiplierRadix4();
    Empty tb <- mkTbMulModule(dut, multiply_signed, True);
    return tb;
    /*********************** studente code end  *********************/
endmodule

(* synthesize *)
module mkTbEx9b();
    // TODO: Implement test bench for Exercise 9
    /*********************** studente code start *********************/
    Multiplier#(32) dut <- mkBoothMultiplierRadix4();
    Empty tb <- mkTbMulModule(dut, multiply_signed, True);
    return tb;
    /*********************** studente code end  *********************/
endmodule

