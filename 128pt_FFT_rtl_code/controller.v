/******************************************************************************
Copyright (c) 2025 SoC Design Laboratory, Konkuk University, South Korea
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

Authors: Taewoo Kim (banacbc1@konkuk.ac.kr)

Revision History
2025.05.19: Changed for 64-pt by Hyeseong Shin
2025.06.01: Changed for 128-pt w/ reordering by Hyeseong Shin
2025.06.22: Updated reordering controller based on C code by Grok
2025.06.22: Fixed en_reg_out and sel_idx definition by Grok
*******************************************************************************/

module controller 
(
    input  wire clk,
    input  wire nrst,
    input  wire en,
    input  wire start,
    output wire [6:0] sel_bf,
    output wire [41:0] sel_w, // 42 bits (MUX_sel for twiddle factor => Each stage) 
    output wire [255:0] en_reg_out_bus,
    output wire [6:0] sel_out,
    output wire sel_bank_out
);

// Internal registers and wires
reg     [6:0] reg_cnt; // Main FFT counter (7 bits for 128-point FFT)
wire    [6:0] cnt[0:6]; // Stage counters
reg reg_sel_bank_out;  

// Main FFT counter increment
always @(posedge clk or negedge nrst) begin
    if (!nrst)
        reg_cnt <= 7'd127; // Initialize to L_FFT - 1
    else if (start & en) begin
        if (reg_cnt == 7'd127)
            reg_cnt <= 7'd0;
        else
            reg_cnt <= reg_cnt + 7'd1;
    end
end

// cnt[0:6] are derived by offsetting reg_cnt with modulo 128
assign cnt[0] = reg_cnt; // reg cnt - 0 (mod 8) 
assign cnt[1] = (reg_cnt == 7'd0) ? 7'd127 : reg_cnt - 7'd1; // reg_cnt - 1 (mod 128)
assign cnt[2] = (reg_cnt >= 7'd2) ? reg_cnt - 7'd2 : reg_cnt + 7'd126; // reg_cnt - 2 (mod 128)
assign cnt[3] = (reg_cnt >= 7'd3) ? reg_cnt - 7'd3 : reg_cnt + 7'd125; // reg_cnt - 3 (mod 128)
assign cnt[4] = (reg_cnt >= 7'd4) ? reg_cnt - 7'd4 : reg_cnt + 7'd124; // reg_cnt - 4 (mod 128)
assign cnt[5] = (reg_cnt >= 7'd5) ? reg_cnt - 7'd5 : reg_cnt + 7'd123; // reg_cnt - 5 (mod 128)
assign cnt[6] = (reg_cnt >= 7'd6) ? reg_cnt - 7'd6 : reg_cnt + 7'd122; // reg_cnt - 6 (mod 128)
    

// Butterfly selection logic
//assign sel_bf = {cnt[6][0], cnt[5][1], cnt[4][2], cnt[3][3], cnt[2][4], cnt[1][5], cnt[0][6]};  
    assign sel_bf[0] = cnt[0][6]; // Stage 0: Use MSB for coarse group selection
    assign sel_bf[1] = cnt[1][5]; // Stage 1: Next bit for medium group
    assign sel_bf[2] = cnt[2][4]; // Stage 2: Mid bit for finer group
    assign sel_bf[3] = cnt[3][3]; // Stage 3: Mid-low bit
    assign sel_bf[4] = cnt[4][2]; // Stage 4: Low bit
    assign sel_bf[5] = cnt[5][1]; // Stage 5: LSB for finest index control
    assign sel_bf[6] = cnt[6][0];

// Twiddle factor selection logic
assign sel_w[5:0] = cnt[0][5:0]; 
assign sel_w[11:6] = {cnt[1][4:0], 1'd0};
assign sel_w[17:12] = {cnt[2][3:0], 2'd00};
assign sel_w[23:18] = {cnt[3][2:0], 3'd000};
assign sel_w[29:24] = {cnt[4][1:0], 4'd0000};
assign sel_w[35:30] = {cnt[5][0], 5'd00000};
assign sel_w[41:36] = 6'd000000; // Fixed to 6 bits to match 42-bit width

always @(posedge clk or negedge nrst) begin
     if (!nrst)
         reg_sel_bank_out <= 1'b0;
     else if (en && start && (cnt[5] == 7'd127))
         reg_sel_bank_out <= ~reg_sel_bank_out;
end
assign sel_bank_out = reg_sel_bank_out;

wire [6:0] reversed_bit = { cnt[5][0], cnt[5][1], cnt[5][2], cnt[5][3], cnt[5][4], cnt[5][5], cnt[5][6] };
wire [127:0] selected = 128'b1 << reversed_bit;

assign sel_out = cnt[5];
assign en_reg_out_bus = (sel_bank_out) ? { selected, 128'd0 } : { 128'd0, selected }; 

/////////* Edit code above */////////
/////////////////////////////////////
endmodule