function Bit#(1) and1(Bit#(1) a, Bit#(1) b);
    return a & b;
endfunction

function Bit#(1) or1(Bit#(1) a, Bit#(1) b);
    return a | b;
endfunction

function Bit#(1) xor1( Bit#(1) a, Bit#(1) b );
    return a ^ b;
endfunction

function Bit#(1) not1(Bit#(1) a);
    return ~ a;
endfunction
// Exercise 1 (4 Points): Using the and, or, and not gates, re-implement the function multiplexer1 in Multiplexer.bsv. 
// How many gates are needed? 4 gates,2 and ,1 not, 1or
function Bit#(1) multiplexer1(Bit#(1) sel, Bit#(1) a, Bit#(1) b);
    // return (sel == 0)? a : b; //class provided
    /*********************** studente code start *********************/
    //when 'sel==1', select out'b'
    Bit#(1) b_temp = and1(sel,b);
    //when 'sel==0', select out'a'
    Bit#(1) sel_eq_0 = not1(sel);
    Bit#(1) a_temp   = and1(sel_eq_0,a);
    //out is 'a_temp' or 'b_temp'
    return or1(a_temp,b_temp);
    /*********************** studente code end  *********************/
endfunction
//Exercise 2 (1 Point): Complete the implementation of the function multiplexer5 in Multiplexer.bsv using for loops and multiplexer1.
function Bit#(5) multiplexer5(Bit#(1) sel, Bit#(5) a, Bit#(5) b);
    // return (sel == 0)? a : b;  //class provided
    /*********************** studente code start *********************/
    Bit#(5) result;
    for(Integer i = 0; i < 5; i=i+1) begin
        // return multiplexer1(sel,a[i],b[i]);
        result[i] = multiplexer1(sel,a[i],b[i]);
    end
    return result;
    /*********************** studente code end  *********************/
endfunction

//Exercise 3 (2 Points): Complete the definition of the function multiplexer_n
typedef 5 N;
function Bit#(N) multiplexerN(Bit#(1) sel, Bit#(N) a, Bit#(N) b);
    // return (sel == 0)? a : b;  //class provided
    /*********************** studente code start *********************/
    Bit#(N) result;
    for(Integer i = 0; i < valueOf(N); i=i+1) begin
        // return multiplexer1(sel,a[i],b[i]);
        result[i] = multiplexer1(sel,a[i],b[i]);
    end
    return result;
    /*********************** studente code end  *********************/
endfunction

// typedef 32 n; // Not needed
function Bit#(n) multiplexer_n(Bit#(1) sel, Bit#(n) a, Bit#(n) b);
    return (sel == 0)? a : b; 
endfunction
