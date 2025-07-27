`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2025 11:00:12
// Design Name: 
// Module Name: encrypt_round
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


module encrypt_round (
    input  [127:0] state_in,
    output [127:0] state_out
);

    // Wires to connect the transformation stages
    wire [127:0] after_subBytes;
    wire [127:0] after_shiftRows;
    // The final output of this module is the output of MixColumns
    
    // Stage 1: SubBytes
    // We instantiate the 128-bit wrapper module you already created.
    subBytes dut_sub (
        .in(state_in),
        .out(after_subBytes)
    );
    
    // Stage 2: ShiftRows
    // We instantiate the shiftRows module you created.
    shift_rows dut_shift (
        .in(after_subBytes),
        .shifted(after_shiftRows)
    );
    
    // Stage 3: MixColumns
    // The output of this stage is the final output of the module.
    // We instantiate the mixColumns module you created.
    mixColomns dut_mix (
        .in(after_shiftRows),
        .out(state_out)
    );

endmodule
