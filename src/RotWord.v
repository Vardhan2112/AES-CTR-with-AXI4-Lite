`timescale 1ns / 1ps

//
// Module: RotWord
// Description: Performs a 1-byte cyclic left shift on a 32-bit word.
// [a0, a1, a2, a3] -> [a1, a2, a3, a0]
//
module RotWord (
    input  [31:0] word_in,
    output [31:0] word_out
);
    assign word_out = {word_in[23:0], word_in[31:24]};
endmodule