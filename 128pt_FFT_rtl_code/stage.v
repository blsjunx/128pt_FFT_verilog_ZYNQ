/******************************************************************************
Copyright (c) 2022-2025 SoC Design Laboratory, Konkuk University, South Korea
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met; and provided that prior written permission for any distribution
has been obtained from the copyright holder: redistributions of source
code must retain the above copyright notice, this list of conditions and
the following disclaimer; redistributions in binary form must reproduce 
the above copyright notice, this list of conditions and the following
disclaimer in the documentation and/or other materials provided with 
the distribution; neither the name of the copyright holders nor the 
names of its contributors may be used to endorse or promote products 
derived from this software without specific prior written permission;

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Authors: Taewoo Kim (banacbc1@konkuk.ac.kr),

2025.05.19: Changed for 64-pt by Hyeseong Shin
2025.06.01: Changed for 128-pt by Hyeseong Shin
*******************************************************************************/
 module stage
 #(
    parameter N_SR = 4,                  // Number of Shift register stages
    parameter B_ST_IN   = 14,             // Bit-width of stage input data
    parameter B_ST_OUT  = 14              // Bit-width of stage output data
 )
 (
    input   clk,                          
    input   nrst,                         
    input   en,                           
    input   [2*B_ST_IN-1:0]  din_stage,   
    output  [2*B_ST_OUT-1:0] dout_stage,  
    input   [895:0]   w_bus,            
    input   sel_bf,                       
    input   [5:0]   sel_w                 
 );
/////////////////////////////////////
/////////* Edit code below */////////
reg  [2*B_ST_IN-1:0]   reg_in;
    wire [2*B_ST_OUT-1:0]  dout_reg_in;
    wire [2*B_ST_OUT-1:0]  dout_mux_bf_0;
    wire [2*B_ST_OUT-1:0]  dout_mux_bf_1;
    wire [13:0] dout_mux_w;
    
    wire [2*B_ST_OUT-1:0] dout_sr;
    wire [2*B_ST_OUT-1:0] dout0_bf;
    wire [2*B_ST_OUT-1:0] dout1_bf;
    wire [2*B_ST_OUT-1:0] dout_mult;
    
    always @(posedge clk or negedge nrst) begin
       if (!nrst)
           reg_in <= 0;
       else if (en)
           reg_in <= din_stage;
    end
    
    //Divide reg_in to Real & image
    wire signed [B_ST_IN-1:0] reg_in_re  = reg_in[2*B_ST_IN-1 : B_ST_IN];
    wire signed [B_ST_IN-1:0] reg_in_im  = reg_in[B_ST_IN-1 : 0];
    
    //sign-extension
    wire signed [B_ST_OUT-1:0] reg_in_re_ext = 
         (B_ST_OUT - B_ST_IN > 1) ?
         {reg_in_re[B_ST_IN-1], reg_in_re, {(B_ST_OUT - B_ST_IN - 1){1'b0}}} :
         {reg_in_re[B_ST_IN-1], reg_in_re};  
     
    wire signed [B_ST_OUT-1:0] reg_in_im_ext = 
         (B_ST_OUT - B_ST_IN > 1) ?
         {reg_in_im[B_ST_IN-1], reg_in_im, {(B_ST_OUT - B_ST_IN - 1){1'b0}}} :
         {reg_in_im[B_ST_IN-1], reg_in_im};
    
    assign dout_reg_in = {reg_in_re_ext, reg_in_im_ext};
    
    wire signed [B_ST_OUT-1:0] dout_sr_re = dout_sr[2*B_ST_OUT-1 : B_ST_OUT];
    wire signed [B_ST_OUT-1:0] dout_sr_im = dout_sr[B_ST_OUT-1 : 0];
    
    assign dout_mux_w = w_bus[14 * sel_w +: 14];
    
    assign dout_mux_bf_0 = sel_bf ? dout0_bf : dout_sr;      
    assign dout_mux_bf_1 = sel_bf ? dout1_bf : dout_reg_in;     
    
    shift_reg #(.BW(2*B_ST_OUT), .N(N_SR)) shift_reg (
        .nrst(nrst), .clk(clk), .en(en),
        .din_sr(dout_mux_bf_1), .dout_sr(dout_sr)
    );

    bf #(.BW(B_ST_OUT)) bf (
        .din0_bf_re(dout_sr_re), .din0_bf_im(dout_sr_im),
        .din1_bf_re(reg_in_re_ext), .din1_bf_im(reg_in_im_ext),
        .dout0_bf(dout0_bf), .dout1_bf(dout1_bf)
    );     
    
    wire signed [B_ST_OUT-1:0] bf_re = dout_mux_bf_0[2*B_ST_OUT-1 : B_ST_OUT];
    wire signed [B_ST_OUT-1:0] bf_im = dout_mux_bf_0[B_ST_OUT-1 : 0];

       
    wire signed [6:0] w_re = dout_mux_w[13:7];
    wire signed [6:0] w_im = dout_mux_w[6:0];
    
   
    mult #(.BW(B_ST_OUT)) mult (
          .din0_mult_re(bf_re),
          .din0_mult_im(bf_im),
          .din1_mult_re(w_re),
          .din1_mult_im(w_im),
          .dout_mult(dout_mult)
     );
    
    assign dout_stage = sel_bf ? dout_mux_bf_0 : dout_mult;
/////////* Edit code above */////////
/////////////////////////////////////
 endmodule