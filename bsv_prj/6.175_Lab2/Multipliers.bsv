// Reference functions that use Bluespec's '*' operator
function Bit#(TAdd#(n,n)) multiply_unsigned( Bit#(n) a, Bit#(n) b );
    UInt#(n) a_uint = unpack(a);
    UInt#(n) b_uint = unpack(b);
    UInt#(TAdd#(n,n)) product_uint = zeroExtend(a_uint) * zeroExtend(b_uint);
    return pack( product_uint );
endfunction

function Bit#(TAdd#(n,n)) multiply_signed( Bit#(n) a, Bit#(n) b );
    Int#(n) a_int = unpack(a);
    Int#(n) b_int = unpack(b);
    Int#(TAdd#(n,n)) product_int = signExtend(a_int) * signExtend(b_int);
    return pack( product_int );
endfunction

//insert addn

function Bit#(1) fa_sum( Bit#(1) a, Bit#(1) b, Bit#(1) c_in );
    return  ((a^b)^c_in);
endfunction

function Bit#(1) fa_carry( Bit#(1) a, Bit#(1) b, Bit#(1) c_in );
    return ((a&b)|((a^b)&c_in));
endfunction

function Bit#(TAdd#(n,1)) add_n( Bit#(n) a, Bit#(n) b, Bit#(1) c_in );
    Bit#(n) sum_out;
    Bit#(n) carr_out=0;
    for (Integer i = 0; i < valueOf(n); i=i+1) begin
        if(i == 0) begin
            sum_out[i]  = fa_sum(a[i],b[i],c_in);
            carr_out[i] = fa_carry(a[i],b[i],c_in);
        end
        else begin
            sum_out[i]  = fa_sum(a[i],b[i],carr_out[i-1]);
            carr_out[i] = fa_carry(a[i],b[i],carr_out[i-1]);
        end
    end
    return {carr_out[valueOf(n)-1],sum_out};
endfunction

// Multiplication by repeated addition
function Bit#(TAdd#(n,n)) multiply_by_adding( Bit#(n) a, Bit#(n) b );
    // TODO: Implement this function in Exercise 2
    /*********************** studente code start *********************/
    Bit#(n)  tp     = 0;
    Bit#(n)  prod   = 0;

    for (Integer i = 0; i < valueOf(n); i=i+1) begin
        Bit#(n)   m   = (a[i] == 0) ? 0 :b;
        Bit#(TAdd#(n,1)) sum = add_n(m,tp,0);
        prod[i]       = sum[0];
        tp            = sum[valueOf(n):1];
    end

    return {tp,prod};
    /*********************** studente code end  *********************/
endfunction



// Multiplier Interface
interface Multiplier#( numeric type n );
    method Bool start_ready();
    method Action start( Bit#(n) a, Bit#(n) b );
    method Bool result_ready();
    method ActionValue#(Bit#(TAdd#(n,n))) result();
endinterface



// Folded multiplier by repeated addition
module mkFoldedMultiplier( Multiplier#(n) );
    // You can use these registers or create your own if you want
    Reg#(Bit#(n)) a <- mkRegU();
    Reg#(Bit#(n)) b <- mkRegU();
    Reg#(Bit#(n)) prod <- mkRegU();
    Reg#(Bit#(n)) tp <- mkRegU();
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)+1) );

    //computation going on and the rule mul_step should be doing work and incrementing i
    rule mulStep( i < fromInteger(valueOf(n)) );
        // TODO: Implement this in Exercise 4
        i <= i + 1;

        Bit#(n)   m   = (a[i] == 0) ? 0 :b;
        Bit#(TAdd#(n,1)) sum = add_n(m,tp,0);
        prod[i]       <= sum[0];
        tp            <= sum[valueOf(n):1];

    endrule

    //i == n+1 denotes that the module is ready to start again, so start_ready should return true
    method Bool start_ready();
        // TODO: Implement this in Exercise 4
        return (i == fromInteger(valueOf(n)+1)) ? True : False;
    endmethod

    method Action start( Bit#(n) aIn, Bit#(n) bIn );
        // TODO: Implement this in Exercise 4
        if(i == fromInteger(valueOf(n)+1)) begin
            a    <= aIn;
            b    <= bIn;
            prod <= 0;
            tp   <= 0;
            i    <= 0;
        end
    endmethod

    //When i reaches n, there is a result ready for reading, so result_ready should return true
    method Bool result_ready();
        // TODO: Implement this in Exercise 4
        return (i == fromInteger(valueOf(n))) ? True : False;
    endmethod

    //When the action value method result is called, the state of i should increase by 1 to n+1
    method ActionValue#(Bit#(TAdd#(n,n))) result();
        // TODO: Implement this in Exercise 4
        Bit#(TAdd#(n,n)) result_w = 0;
        if(i == fromInteger(valueOf(n))) begin 
            i <= i + 1;
            result_w = {tp,prod};
        end
        return result_w;
    endmethod
endmodule



// Booth Multiplier
module mkBoothMultiplier( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) m_neg <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) m_pos <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) p <- mkRegU;
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)+1) );

    rule mul_step( i < fromInteger(valueOf(n)) );
        // TODO: Implement this in Exercise 6
        i <= i + 1;

        Bit#(2) pr = p[1:0];
        Int#(TAdd#(TAdd#(n,n),1)) p_tmp = unpack(p);
        
        if ( pr == 2'b01 ) begin
            p_tmp = unpack(p + m_pos);
        end
        if ( pr == 2'b10 ) begin
            p_tmp = unpack(p + m_neg);
        end
        p <= pack(p_tmp >> 1);

    endrule

    method Bool start_ready();
        // TODO: Implement this in Exercise 6
        return (i == fromInteger(valueOf(n)+1)) ? True : False;
    endmethod

    method Action start( Bit#(n) m, Bit#(n) r );
        // TODO: Implement this in Exercise 6

        Bit#(n) cmp_m = ~m + 1;
        if(i == fromInteger(valueOf(n) + 1)) begin
            m_pos <= {      m     ,  'b0};
            m_neg <= {      cmp_m ,  'b0};
            p     <= {'b0 , r     , 1'b0};
            i     <= 0;
        end

    endmethod

    method Bool result_ready();
        // TODO: Implement this in Exercise 6
        return (i == fromInteger(valueOf(n))) ? True : False;
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        // TODO: Implement this in Exercise 6
        Bit#(TAdd#(n,n)) result_w = 0;
        if(i == fromInteger(valueOf(n))) begin
            i <= i + 1;
            result_w = p[valueOf(TAdd#(n,n)) : 1];
        end
        return result_w;
    endmethod
endmodule



// Radix-4 Booth Multiplier
module mkBoothMultiplierRadix4( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) m_neg <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) m_pos <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) p <- mkRegU;
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)/2+1) );

    rule mul_step( i < fromInteger(valueOf(n)/2) );
        // TODO: Implement this in Exercise 8
        i <= i + 1;

        Bit#(3) pr = p[2:0];
        Int#(TAdd#(TAdd#(n,n),2)) p_tmp = unpack(p);

        case(pr)
            'b001 : p_tmp   = unpack(p + m_pos);
            'b010 : p_tmp   = unpack(p + m_pos);
            'b011 : p_tmp   = unpack(p + (m_pos << 1));
            'b100 : p_tmp   = unpack(p + (m_neg << 1));
            'b101 : p_tmp   = unpack(p + m_neg);
            'b110 : p_tmp   = unpack(p + m_neg);
            default : p_tmp = unpack(p);
        endcase
        p <= pack(p_tmp >> 2);

    endrule

    method Bool start_ready();
        // TODO: Implement this in Exercise 8
        return (i == fromInteger(valueOf(n)/2+1)) ? True : False;
    endmethod

    method Action start( Bit#(n) m, Bit#(n) r );
        // TODO: Implement this in Exercise 8
        Bit#(n) cmp_m = ~m + 1;

        if(i == fromInteger(valueOf(n)/2 + 1)) begin
            m_pos <= {     m[valueOf(n)-1] ,      m ,  'b0};
            m_neg <= { cmp_m[valueOf(n)-1] ,  cmp_m ,  'b0};
            p     <= {                 'd0 ,      r , 1'b0};
            i     <= 0;
        end
    endmethod

    method Bool result_ready();
        // TODO: Implement this in Exercise 8
        return (i == fromInteger(valueOf(n)/2)) ? True : False;
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        // TODO: Implement this in Exercise 8
        Bit#(TAdd#(n,n)) result_w = 0;
        if(i == fromInteger(valueOf(n)/2)) begin
            i <= i + 1;
            //with MSB and LSB chopped off
            result_w =  p[valueOf(TAdd#(n,n)) : 1];
        end
        return result_w;
    endmethod
endmodule

