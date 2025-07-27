`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2025 11:55:16
// Design Name: 
// Module Name: shift_rows
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


module shift_rows(
    input [127:0]in,
    output [127:0]shifted
    );
    
    //in[127:120] in[95:88] in[63:56] in[31:24]   // Row 0
//in[119:112] in[87:80] in[55:48] in[23:16]   // Row 1
//in[111:104] in[79:72] in[47:40] in[15:8]    // Row 2
//in[103:96]  in[71:64] in[39:32] in[7:0]     // Row 3
    // Row 0: No shift
    assign shifted[127:120] = in[127:120]; // s[0,0]
    assign shifted[95:88]   = in[95:88];   // s[0,1]
    assign shifted[63:56]   = in[63:56];   // s[0,2]
    assign shifted[31:24]   = in[31:24];   // s[0,3]
    
    // Row 1: Left shift by 1 byte
    assign shifted[119:112] = in[87:80];   // s[1,1] → s'[1,0]
    assign shifted[87:80]   = in[55:48];   // s[1,2] → s'[1,1]
    assign shifted[55:48]   = in[23:16];   // s[1,3] → s'[1,2]
    assign shifted[23:16]   = in[119:112]; // s[1,0] → s'[1,3]
    
    // Row 2: Left shift by 2 bytes
    assign shifted[111:104] = in[47:40];   // s[2,2] → s'[2,0]
    assign shifted[79:72]   = in[15:8];    // s[2,3] → s'[2,1]
    assign shifted[47:40]   = in[111:104]; // s[2,0] → s'[2,2]
    assign shifted[15:8]    = in[79:72];   // s[2,1] → s'[2,3]
    
    // Row 3: Left shift by 3 bytes
    assign shifted[103:96]  = in[7:0];     // s[3,3] → s'[3,0]
    assign shifted[71:64]   = in[103:96];  // s[3,0] → s'[3,1]
    assign shifted[39:32]   = in[71:64];   // s[3,1] → s'[3,2]
    assign shifted[7:0]     = in[39:32];   // s[3,2] → s'[3,3]
endmodule
