`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: decrypt_round (Corrected)
// Description: Performs one standard round of AES decryption.
//              Implements: InvMixColumns(AddRoundKey(InvSubBytes(InvShiftRows(state)), key))
//////////////////////////////////////////////////////////////////////////////////

module decrypt_round (
    input  [127:0] state_in,
    input  [127:0] round_key,
    output [127:0] state_out
);

    // Wires to connect the transformation stages
    wire [127:0] after_inv_shiftRows;
    wire [127:0] after_inv_subBytes;
    wire [127:0] after_add_key;

    // Stage 1: Inverse ShiftRows
    inv_shift_rows u_inv_shift (
        .in(state_in),
        .shifted(after_inv_shiftRows)
    );
    
    // Stage 2: Inverse SubBytes
    inv_subBytes u_inv_sub (
        .in(after_inv_shiftRows),
        .out(after_inv_subBytes)
    );
    
    // Stage 3: AddRoundKey
    addRoundKey u_add_key (
        .in(after_inv_subBytes),
        .key(round_key),
        .out(after_add_key)
    );
    
    // Stage 4: Inverse MixColumns
    inv_mixColumns u_inv_mix (
        .in(after_add_key),
        .out(state_out)
    );

endmodule