`timescale 1ns / 1ps
//
// Module: SubWord
// Description: Applies the S-Box to each of the 4 bytes in a 32-bit word.
// Note: This module requires your sbox.v file to be in the project.
//
module SubWord (
    input  [31:0] word_in,
    output [31:0] word_out
);
    // Instantiate 4 S-Boxes, one for each byte
    sbox s3 (word_in[31:24], word_out[31:24]);
    sbox s2 (word_in[23:16], word_out[23:16]);
    sbox s1 (word_in[15:8], word_out[15:8]);
    sbox s0 (word_in[7:0],  word_out[7:0]);
endmodule