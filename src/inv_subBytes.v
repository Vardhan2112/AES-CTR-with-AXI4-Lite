`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2025 12:38:37
// Design Name: 
// Module Name: inv_subBytes
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module inv_subBytes (
    input [127:0] in,
    output [127:0] out
);
    genvar i;
    generate 
        for (i=127; i>=7; i=i-8) begin : inv_sub_Bytes 
            inv_sbox s (.in(in[i:i-7]), .out(out[i:i-7]));
        end
    endgenerate
endmodule
