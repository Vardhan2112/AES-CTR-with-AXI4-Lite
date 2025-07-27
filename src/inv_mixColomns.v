`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2025 12:04:39
// Design Name: 
// Module Name: inv_mixColomns
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


module inv_mixColumns (
    input [127:0] in,
    output [127:0] out
);


//0E & 0B & 0D & 09
//09 & 0E & 0B & 0D 
//0D & 09 & 0E & 0B
//0B & 0D & 09 & 0E

    // Helper function for GF(2^8) multiplication
    function [7:0] xtime;
        input [7:0] a;
        begin
            xtime = (a << 1) ^ ((a[7]) ? 8'h1B : 8'h00);
        end
    endfunction

    function [7:0] mul09;
        input [7:0] a;
        begin
            mul09 = xtime(xtime(xtime(a))) ^ a; // 08*a ^ 01*a = 09*a
        end
    endfunction

    function [7:0] mul0B;
        input [7:0] a;
        begin
            mul0B = xtime(xtime(xtime(a))) ^ xtime(a) ^ a; // 08*a ^ 02*a ^ 01*a = 0B*a
        end
    endfunction

    function [7:0] mul0D;
        input [7:0] a;
        begin
            mul0D = xtime(xtime(xtime(a))) ^ xtime(xtime(a)) ^ a; // 08*a ^ 04*a ^ 01*a = 0D*a
        end
    endfunction

    function [7:0] mul0E;
        input [7:0] a;
        begin
            mul0E = xtime(xtime(xtime(a))) ^ xtime(xtime(a)) ^ xtime(a); // 08*a ^ 04*a ^ 02*a = 0E*a
        end
    endfunction

    // Process each column
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : inv_mix_columns
            wire [7:0] s0 = in[127-32*i:120-32*i];
            wire [7:0] s1 = in[119-32*i:112-32*i];
            wire [7:0] s2 = in[111-32*i:104-32*i];
            wire [7:0] s3 = in[103-32*i:96-32*i];
            
            assign out[127-32*i:120-32*i] = mul0E(s0) ^ mul0B(s1) ^ mul0D(s2) ^ mul09(s3); // 0E*s0 + 0B*s1 + 0D*s2 + 09*s3
            assign out[119-32*i:112-32*i] = mul09(s0) ^ mul0E(s1) ^ mul0B(s2) ^ mul0D(s3); // 09*s0 + 0E*s1 + 0B*s2 + 0D*s3
            assign out[111-32*i:104-32*i] = mul0D(s0) ^ mul09(s1) ^ mul0E(s2) ^ mul0B(s3); // 0D*s0 + 09*s1 + 0E*s2 + 0B*s3
            assign out[103-32*i:96-32*i]  = mul0B(s0) ^ mul0D(s1) ^ mul09(s2) ^ mul0E(s3); // 0B*s0 + 0D*s1 + 09*s2 + 0E*s3
        end
    endgenerate
endmodule