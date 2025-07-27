`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_key_expansion_128
// Description: Verifies the provided key_expansion_128 module against the
//              official FIPS-197 Appendix A.1 test vectors.
//////////////////////////////////////////////////////////////////////////////////
module tb_key_expansion_128;

    // Testbench Signals
    reg         clk;
    reg         rst_n;
    reg         start;
    reg [127:0] tb_key_in;
    reg [3:0]   tb_round;
    
    wire [127:0] tb_round_key_out;
    wire         tb_ready;
    
    // Instantiate the Device Under Test (DUT)
    key_expansion_128 dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .key_in(tb_key_in),
        .round(tb_round),
        .round_key_out(tb_round_key_out),
        .ready(tb_ready)
    );

    // Clock generator (100 MHz)
    always #5 clk = ~clk;
    reg [127:0] expected_keys[0:10];
       integer error_count;
        integer i;
    // Main test sequence
    initial begin
        // Store all 11 expected round keys from FIPS-197 Appendix A.1
        

        // Populate the expected keys array with official FIPS-197 vectors
        expected_keys[0]  = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        expected_keys[1]  = 128'ha0fafe1788542cb123a339392a6c7605;
        expected_keys[2]  = 128'hf2c295f27a96b9435935807a7359f67f;
        expected_keys[3]  = 128'h3d80477d4716fe3e1e237e446d7a883b;
        expected_keys[4]  = 128'hef44a541a8525b7fb671253bdb0bad00;
        expected_keys[5]  = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
        expected_keys[6]  = 128'h6d88a37a110b3efddbf98641ca0093fd;
        expected_keys[7]  = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
        expected_keys[8]  = 128'head27321b58dbad2312bf5607f8d292f;
        expected_keys[9]  = 128'hac7766f319fadc2128d12941575c006e;
        expected_keys[10] = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;
        
        // 1. Initialize and Reset
        clk = 0;
        rst_n = 1'b0; // Assert reset (active-low)
        start = 1'b0;
        tb_key_in = 128'b0;
        tb_round = 4'b0;
        error_count = 0;
        
        #20;
        rst_n = 1'b1; // De-assert reset
        #10;
        
        $display("--- Starting Key Expansion Verification using FIPS-197 ---");

        // 2. Load the key and start the generation
        $display("[%0t ns] Pulsing 'start' signal to load key...", $time);
        tb_key_in = expected_keys[0];
        start = 1'b1;
        #10; // Pulse 'start' for one full clock cycle (10ns)
        start = 1'b0;

        // 3. Wait for the 'ready' signal to go high
        $display("[%0t ns] Waiting for key schedule generation to complete...", $time);
        wait (tb_ready == 1'b1);
        $display("[%0t ns] 'ready' signal is high. Key schedule is generated.", $time);
        #10; // Settle after ready goes high

        // 4. Loop through and check all 11 round keys
        $display("\n--- Verifying all 11 round keys ---");
        for (i = 0; i <= 10; i = i + 1) begin
            tb_round = i;
            #1; // Give a small combinational delay for the output mux to update
            
            if (tb_round_key_out === expected_keys[i]) begin
                $display("PASS: Round %0d key is correct.", i);
            end else begin
                $display("FAIL: Round %0d key is incorrect.", i);
                $display("      Expected: %h", expected_keys[i]);
                $display("      Got:      %h", tb_round_key_out);
                error_count = error_count + 1;
            end
        end
        
        // 5. Final Summary
        #20;
        if (error_count == 0) begin
            $display("\n--- VERIFICATION SUCCESSFUL: All round keys match FIPS-197. ---");
        end else begin
            $display("\n--- VERIFICATION FAILED with %d errors. ---", error_count);
        end

        $finish;
    end

endmodule