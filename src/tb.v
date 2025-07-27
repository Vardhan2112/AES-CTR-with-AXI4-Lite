`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2025 12:56:53
// Design Name: 
// Module Name: tb
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


module tb_aes_full_round;

    // Testbench Registers for inputs
    reg [127:0] tb_initial_state_in;
    reg [127:0] tb_round_key_in;

    // Wires to connect the components in a chain
    wire [127:0] after_subBytes;
    wire [127:0] after_shiftRows;
    wire [127:0] after_mixColumns;
    wire [127:0] final_state_out; // The output of the full round

    // Declare test vectors at module level
    reg [127:0] r1_start_state;
    reg [127:0] r1_key;
    reg [127:0] r2_start_state_expected;

    //-----------------------------------------------------
    // Instantiate the chain of DUTs for one full round
    //-----------------------------------------------------

    // Stage 1: SubBytes
    subBytes dut_sub (
        .in(tb_initial_state_in),
        .out(after_subBytes)
    );

    // Stage 2: ShiftRows
    shift_rows dut_shift (
        .in(after_subBytes),
        .shifted(after_shiftRows)
    );

    // Stage 3: MixColumns
    mixColomns dut_mix (
        .in(after_shiftRows),
        .out(after_mixColumns)
    );

    // Stage 4: AddRoundKey
    addRoundKey dut_add_key (
        .in(after_mixColumns),
        .key(tb_round_key_in),
        .out(final_state_out)
    );

    //-----------------------------------------------------
    // Test Sequence using FIPS-197, Appendix C.1 data
    //-----------------------------------------------------
    initial begin
        $display("--- Starting Full AES Encryption Round 1 Verification ---");

        // Initialize test vectors (AES-128, Appendix C.1)
        r1_start_state = 128'h00102030405060708090a0b0c0d0e0f0;
        r1_key = 128'hd6aa74fdd2af72fadaa678f1d6ab76fe;
        r2_start_state_expected = 128'h89d810e8855ace682d1843d8cb128fe4;

        // Apply inputs
        tb_initial_state_in = r1_start_state;
        tb_round_key_in = r1_key;

        #1; // Minimal delay for combinational logic to propagate

        // Check the final output
        $display("\n[TEST] Verifying the output of the full round...");
        if (final_state_out === r2_start_state_expected) begin
            $display("PASS: Full round output matches the FIPS-197 vector for the start of Round 2.");
            $display("   Expected: %h", r2_start_state_expected);
            $display("   Got:      %h", final_state_out);
        end else begin
            $display("FAIL: Full round output is incorrect.");
            $display("   Expected: %h", r2_start_state_expected);
            $display("   Got:      %h", final_state_out);
        end

        // Display intermediate values for debugging
        $display("\n--- Intermediate Values for Debugging ---");
        $display("After SubBytes:  %h", after_subBytes);
        $display("After ShiftRows: %h", after_shiftRows);
        $display("After MixCols:   %h", after_mixColumns);
        $display("Final Output:    %h", final_state_out);
        $display("-----------------------------------------\n");

        $display("--- Verification Finished ---");
        $finish;
    end

endmodule
