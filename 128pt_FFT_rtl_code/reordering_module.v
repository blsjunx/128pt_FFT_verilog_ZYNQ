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

Authors: Hyeseong Shin (hyeseongshin@konkuk.ac.kr)
*******************************************************************************/
module reordering_module
 #(
   parameter LOG_L_FFT = 7,
   parameter N_REG = 128,
   parameter B_RE = 41  
)
(
    input wire clk,                          
    input wire nrst,
    input wire [2*B_RE-1:0] in,
    input wire [2*N_REG-1:0] en_reg_out_bus,
    input wire [LOG_L_FFT-1:0] sel_out,
    input wire sel_bank_out,
    output wire [2*B_RE-1:0] out
);

/////////////////////////////////////
/////////* Edit code below */////////

wire [N_REG-1:0] bank0 = en_reg_out_bus[2*N_REG-1 : N_REG];
wire [N_REG-1:0] bank1 = en_reg_out_bus[N_REG-1 : 0];

reg [2*B_RE-1:0] reg_out_0 [0:N_REG-1];
reg [2*B_RE-1:0] reg_out_1 [0:N_REG-1];



//write
genvar i;
generate
    for (i = 0; i < N_REG; i = i + 1) begin
        always @(posedge clk or negedge nrst) begin
            if (!nrst) begin
                reg_out_0[i] <= {2*B_RE{1'b0}};
                reg_out_1[i] <= {2*B_RE{1'b0}};
            end 
            
            else begin
                if (bank0[i]) reg_out_0[i] <= in;   
                if (bank1[i]) reg_out_1[i] <= in;   
            end
        end
    end
endgenerate

//read
reg [2*B_RE-1:0] out_reg;
always @(posedge clk) begin
    if (!nrst)
        out_reg <= {(2*B_RE){1'b0}};
    if (sel_bank_out)
        out_reg <= reg_out_1[sel_out];  
    else
        out_reg <= reg_out_0[sel_out];  
end

assign out = out_reg;

/////////* Edit code above */////////
/////////////////////////////////////
endmodule