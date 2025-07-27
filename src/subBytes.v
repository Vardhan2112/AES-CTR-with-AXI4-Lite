`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2025 12:19:41
// Design Name: 
// Module Name: subBytes
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


module subBytes (
    input [127:0] in,
    output [127:0] out
);
    genvar i;
    generate 
        for (i=127; i>=7; i=i-8) begin : sub_Bytes 
            sbox s(in[i:i-7], out[i:i-7]);
        end
    endgenerate
endmodule
