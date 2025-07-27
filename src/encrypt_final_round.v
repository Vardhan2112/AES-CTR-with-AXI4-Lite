`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2025 11:13:20
// Design Name: 
// Module Name: encrypt_final_round
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


module encrypt_final_round (
    input  [127:0] state_in,
    output [127:0] state_out
);

    // Wire to connect the transformation stages
    wire [127:0] after_subBytes;
    
    // Stage 1: SubBytes
    subBytes dut_sub (
        .in(state_in),
        .out(after_subBytes)
    );
    
    // Stage 2: ShiftRows
    // The output of this stage is the final output of the module.
    shift_rows dut_shift (
        .in(after_subBytes),
        .shifted(state_out)
    );

endmodule
