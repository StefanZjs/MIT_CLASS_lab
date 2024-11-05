import FIFO :: *; 
import FixedPoint :: *;
import Vector :: *;

import AudioProcessorTypes :: *;
import FilterCoefficients :: *;
import Multiplier :: *;

// The FIR Filter Module Definition 
// in section 4.2
module mkFIRFilter_42(AudioProcessor);
    FIFO#(Sample) infifo <- mkFIFO();
    FIFO#(Sample) outfifo <- mkFIFO();

    Reg#(Sample) r0 <- mkReg(0);
    Reg#(Sample) r1 <- mkReg(0);
    Reg#(Sample) r2 <- mkReg(0);
    Reg#(Sample) r3 <- mkReg(0);
    Reg#(Sample) r4 <- mkReg(0);
    Reg#(Sample) r5 <- mkReg(0);
    Reg#(Sample) r6 <- mkReg(0);
    Reg#(Sample) r7 <- mkReg(0);

    rule process;
        Sample sample = infifo.first();
        infifo.deq();

        r0 <= sample;
        r1 <= r0;
        r2 <= r1;
        r3 <= r2;
        r4 <= r3;
        r5 <= r4;
        r6 <= r5;
        r7 <= r6;

        FixedPoint#(16, 16) accumulate = 
              c[0] * fromInt(sample) 
            + c[1] * fromInt(r0) 
            + c[2] * fromInt(r1) 
            + c[3] * fromInt(r2) 
            + c[4] * fromInt(r3) 
            + c[5] * fromInt(r4) 
            + c[6] * fromInt(r5) 
            + c[7] * fromInt(r6) 
            + c[8] * fromInt(r7);

        outfifo.enq(fxptGetInt(accumulate));
    endrule

    method Action putSampleInput(Sample in);
        infifo.enq(in);
    endmethod
    method ActionValue#(Sample) getSampleOutput();
        outfifo.deq();
        return outfifo.first();
    endmethod
endmodule

// in section 4.3
module mkFIRFilter_43(AudioProcessor);
    FIFO#(Sample) infifo <- mkFIFO();
    FIFO#(Sample) outfifo <- mkFIFO();

    Vector#(8, Reg#(Sample)) r <- replicateM(mkReg(0));

    rule process;
        Sample sample = infifo.first();
        infifo.deq();

        r[0] <= sample;
        for (Integer i = 1; i < 8; i = i + 1) begin
            r[i] <= r[i - 1];
        end

        function indexedItem(Integer i) = c[i] * fromInt((i == 0) ? sample : r[i - 1]);

        Vector#(9, Integer) v = genVector;
        FixedPoint#(16, 16) accumulate = fold(\+ , map(indexedItem, v));

        outfifo.enq(fxptGetInt(accumulate));
    endrule

    method Action putSampleInput(Sample in);
        infifo.enq(in);
    endmethod
    method ActionValue#(Sample) getSampleOutput();
        outfifo.deq();
        return outfifo.first();
    endmethod
endmodule


// in section 4.4
module mkFIRFilter(AudioProcessor);
    FIFO#(Sample) infifo <- mkFIFO();
    FIFO#(Sample) outfifo <- mkFIFO();

    Vector#(9, Multiplier) multipliers <- replicateM(mkMultiplier());
    Vector#(8, Reg#(Sample)) r <- replicateM(mkReg(0));


    rule process_in;
        Sample sample = infifo.first();
        infifo.deq();

        r[0] <= sample;
        for (Integer i = 1; i < 8; i = i + 1) begin
            r[i] <= r[i - 1];
        end

        multipliers[0].putOperands(c[0],sample);
        for (Integer i = 1; i < 9; i = i + 1) begin
            multipliers[i].putOperands(c[i],r[i-1]);
        end
    endrule

    rule process_out;

        Vector#(9, FixedPoint#(16, 16)) v;
        for (Integer i = 0; i< 9;i =i +1) begin
            v[i] <- multipliers[i].getResult();
        end

        FixedPoint#(16, 16) accumulate = fold(\+ , v);

        outfifo.enq(fxptGetInt(accumulate));
    endrule

    
    method Action putSampleInput(Sample in);
        infifo.enq(in);
    endmethod
    method ActionValue#(Sample) getSampleOutput();
        outfifo.deq();
        return outfifo.first();
    endmethod

endmodule
