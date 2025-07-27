`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2025 15:39:41
// Design Name: 
// Module Name: ctr_tb
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


`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_aes_128_ctr_engine
// Description: Verifies the single-block AES-CTR engine.
//////////////////////////////////////////////////////////////////////////////////
module tb_aes_128_ctr_engine;

    // Testbench signals
    reg         clk;
    reg         rst_n;
    reg         start;
    reg [127:0] tb_key_in;
    reg [127:0] tb_iv_counter_in;
    reg [127:0] tb_plaintext_in;

    wire [127:0] tb_ciphertext_out;
    wire         tb_done;

    // Instantiate the Device Under Test (DUT)
    aes_128_ctr_engine dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .key_in(tb_key_in),
        .iv_counter_in(tb_iv_counter_in),
        .data_in(tb_plaintext_in),
        .data_out(tb_ciphertext_out),
        .done(tb_done)
    );

    // Clock Generator (100 MHz)
    always #5 clk = ~clk;
// Define the known test vectors
        reg [127:0] VEC_KEY        = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        reg [127:0] VEC_PLAINTEXT  = 128'h3243f6a8885a308d313198a2e0370734;
        reg [127:0] VEC_IV_COUNTER = 128'hf0f1f2f3f4f5f6f7f8f9fafbfcfdfeff;
        //keystream   ec8cdf7398607cb0f2d21675ea9ea1e4

        // Manually calculated expected result
        reg [127:0] VEC_EXPECTED_CIPHERTEXT;
        reg [127:0] VEC_EXPECTED_KEYSTREAM = 128'hec8cdf7398607cb0f2d21675ea9ea1e4;

    // Main Test Sequence
    initial begin
        
        VEC_EXPECTED_CIPHERTEXT = VEC_PLAINTEXT ^ VEC_EXPECTED_KEYSTREAM;
        // 1. Initialize and Reset
        clk = 0;
        rst_n = 1'b0;
        start = 1'b0;
        #20;
        rst_n = 1'b1;
        #10;
        
        $display("--- Starting Single-Block AES-CTR Engine Verification ---");

        // 2. Load inputs and pulse start
        $display("\n[%0t ns] Loading inputs and pulsing 'start'...", $time);
        tb_key_in        = VEC_KEY;
        tb_plaintext_in  = VEC_PLAINTEXT;
        tb_iv_counter_in = VEC_IV_COUNTER;
        start = 1'b1;
        #10; // Pulse for one clock cycle
        start = 1'b0;

        // 3. Wait for the 'done' signal
        $display("[%0t ns] Waiting for CTR operation to complete...", $time);
        wait (tb_done == 1'b1);
        $display("[%0t ns] 'done' signal received.", $time);
        #1; // Settle time

        // 4. Check the result
        $display("\n--- Checking Final Ciphertext ---");
        if (tb_ciphertext_out === VEC_EXPECTED_CIPHERTEXT) begin
            $display("PASS: Final ciphertext matches the expected CTR mode result.");
            $display("      Expected: %h", VEC_EXPECTED_CIPHERTEXT);
            $display("      Got:      %h", tb_ciphertext_out);
            $display("\n--- VERIFICATION SUCCESSFUL ---");
        end else begin
            $display("FAIL: Final ciphertext is incorrect.");
            $display("      Plaintext:   %h", VEC_PLAINTEXT);
            $display("      Keystream:   %h", VEC_EXPECTED_KEYSTREAM);
            $display("      Expected:    %h", VEC_EXPECTED_CIPHERTEXT);
            $display("      Got:         %h", tb_ciphertext_out);
            $display("\n--- VERIFICATION FAILED ---");
        end

        $finish;
    end

endmodule
