import Vector::*;
import Complex::*;

import FftCommon::*;
import Fifo::*;

interface Fft;
    method Action enq(Vector#(FftPoints, ComplexData) in);
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
endinterface

(* synthesize *)
module mkFftCombinational(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction
  
    rule doFft;
        if( inFifo.notEmpty && outFifo.notFull ) begin
            inFifo.deq;
            Vector#(4, Vector#(FftPoints, ComplexData)) stage_data;
            stage_data[0] = inFifo.first;
      
            for (StageIdx stage = 0; stage < 3; stage = stage + 1) begin
                stage_data[stage+1] = stage_f(stage, stage_data[stage]);
            end
            outFifo.enq(stage_data[3]);
        end
    endrule
    
    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

(* synthesize *)
module mkFftFolded(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(16, Bfly4) bfly <- replicateM(mkBfly4);

    /*===================== insert by stefan ===========================*/
    Reg#(Vector#(FftPoints, ComplexData)) stage_reg <- mkRegU; //insert a reg to store data
    Reg#(StageIdx) stage_ctrl <- mkReg(0); //sync ctrl

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction
    /*===================== end ===========================*/

    rule doFft;
        //TODO: Implement the rest of this module
            let stage_in = ?;
            if(stage_ctrl == 0) begin
                inFifo.deq;
                stage_in = inFifo.first;
            end 
            else begin
                stage_in = stage_reg; 
            end
            let stage_out = stage_f(stage_ctrl, stage_in);
    
            if(stage_ctrl == 2) begin 
                stage_ctrl <= 0;
                outFifo.enq(stage_out); //write to outFifo in 3rd cycle
            end else begin
                stage_ctrl <= stage_ctrl + 1;
                stage_reg <= stage_out;
            end

    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in) if( inFifo.notFull );
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq if( outFifo.notEmpty );
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

//Exercise 3 (5 Points): In mkFftInelasticPipeline, create an inelastic pipeline FFT implementation. 
//This implementation should make use of 48 butterflies and 2 large registers, each carrying 64 complex numbers. 
//The latency of this pipelined unit must also be exactly 3 cycles, though its throughput would be 1 FFT operation every cycle.
(* synthesize *)
module mkFftInelasticPipeline(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(3, Vector#(16, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    /*===================== insert by stefan ===========================*/
    Reg#(Vector#(FftPoints, ComplexData)) stage_reg0 <- mkRegU;
    Reg#(Vector#(FftPoints, ComplexData)) stage_reg1 <- mkRegU;
    Reg#(Bit#(1)) pipe_en0 <- mkRegU;
    Reg#(Bit#(1)) pipe_en1 <- mkRegU;

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction

    /*============================= end ===============================*/
    rule doFft;
        //TODO: Implement the rest of this module
        if( inFifo.notEmpty && outFifo.notFull) begin
            inFifo.deq;
            stage_reg0 <= stage_f(0, inFifo.first);
            pipe_en0   <= 1;
        end
        else pipe_en0   <= 0;

        stage_reg1 <= stage_f(1, stage_reg0);
        pipe_en1   <= pipe_en0;

        if(pipe_en1 == 1) begin
            outFifo.enq(stage_f(2, stage_reg1));
        end


    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

//Exercise 4 (10 Points):
//In mkFftElasticPipeline, create an elastic pipeline FFT implementation. 
//This implementation should make use of 48 butterflies and two large FIFOs. 
//The stages between the FIFOs should be in their own rules that can fire independently. 
//The latency of this pipelined unit must also be exactly 3 cycles, though its throughput would be 1 FFT operation every cycle.

(* synthesize *)
module mkFftElasticPipeline(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(3, Vector#(16, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    //TODO: Implement the rest of this module
    // You should use more than one rule
    /*===================== insert by stefan ===========================*/
    Fifo#(2,Vector#(FftPoints, ComplexData)) elastic_Fifo0 <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) elastic_Fifo1 <- mkCFFifo;

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction

    /*============================= end ===============================*/
    rule doFft_stage0;
        if(inFifo.notEmpty && elastic_Fifo0.notFull) begin
            inFifo.deq;
            elastic_Fifo0.enq(stage_f(0,inFifo.first));
        end
    endrule
    rule doFft_stage1;
        if(elastic_Fifo0.notEmpty && elastic_Fifo1.notFull) begin
            elastic_Fifo0.deq;
            elastic_Fifo1.enq(stage_f(1,elastic_Fifo0.first));
        end
    endrule
    rule doFft_stage2;
        if(elastic_Fifo1.notEmpty && outFifo.notFull) begin
            elastic_Fifo1.deq;
            outFifo.enq(stage_f(2,elastic_Fifo1.first));
        end
    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

interface SuperFoldedFft#(numeric type radix);
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
    method Action enq(Vector#(FftPoints, ComplexData) in);
endinterface

module mkFftSuperFolded(SuperFoldedFft#(radix)) provisos(Div#(TDiv#(FftPoints, 4), radix, times), Mul#(radix, times, TDiv#(FftPoints, 4)));
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(radix, Bfly4) bfly <- replicateM(mkBfly4);

    rule doFft;
        //TODO: Implement the rest of this module
    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

function Fft getFft(SuperFoldedFft#(radix) f);
    return (interface Fft;
        method enq = f.enq;
        method deq = f.deq;
    endinterface);
endfunction

(* synthesize *)
module mkFftSuperFolded4(Fft);
    SuperFoldedFft#(4) sfFft <- mkFftSuperFolded;
    return (getFft(sfFft));
endmodule
