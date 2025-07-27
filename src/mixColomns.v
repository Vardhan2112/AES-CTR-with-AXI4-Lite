`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2025 11:25:50
// Design Name: 
// Module Name: MixColomns
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


module mixColomns(
    input [127:0]in,
    output [127:0]out
    );
    
  
//02 & 03 & 01 & 01 
//01 & 02 & 03 & 01
//01 & 01 & 02 & 03
//03 & 01 & 01 & 02


    function [7:0] xtime;//multiply by 02 sll1 if msb=0 else sll1^1B
        input [7:0] a;
        begin
            xtime = (a << 1) ^ ((a[7]) ? 8'h1B : 8'h00);
        end
    endfunction
    
    //03: 02^01.
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : mix_columns
            wire [7:0] s0 = in[127-32*i:120-32*i];
            wire [7:0] s1 = in[119-32*i:112-32*i];
            wire [7:0] s2 = in[111-32*i:104-32*i];
            wire [7:0] s3 = in[103-32*i:96-32*i];
            
            assign out[127-32*i:120-32*i] = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3; // 02*s0 + 03*s1 + 01*s2 + 01*s3
            assign out[119-32*i:112-32*i] = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3; // 01*s0 + 02*s1 + 03*s2 + 01*s3
            assign out[111-32*i:104-32*i] = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3); // 01*s0 + 01*s1 + 02*s2 + 03*s3
            assign out[103-32*i:96-32*i]  = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3); // 03*s0 + 01*s1 + 01*s2 + 02*s3
        end
    endgenerate
    
endmodule
