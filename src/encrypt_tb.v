`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_aes_128_detailed (Syntactically Correct for Verilog-2001)
// Description: A detailed, white-box testbench that verifies all intermediate
//              round states and keys against FIPS-197 Appendix B.
//              All syntax is compatible with Vivado's Verilog-2001 standard.
//////////////////////////////////////////////////////////////////////////////////
module tb_aes_128_detailed;

    // Testbench signals
    reg         clk;
    reg         rst_n;
    reg         start_encrypt;
    reg [127:0] tb_plaintext_in;
    reg [127:0] tb_key_in;

    wire [127:0] tb_ciphertext_out;
    wire         tb_encrypt_done;

    // Instantiate the Device Under Test (DUT)
    aes_128_encrypt dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_encrypt(start_encrypt),
        .plaintext_in(tb_plaintext_in),
        .key_in(tb_key_in),
        .ciphertext_out(tb_ciphertext_out),
        .encrypt_done(tb_encrypt_done)
    );

    // Clock Generator (100 MHz)
    always #5 clk = ~clk;
reg [127:0] VEC_PLAINTEXT;
        reg [127:0] VEC_KEY;
        reg [127:0] VEC_CIPHERTEXT;
        reg [127:0] VEC_ROUND_STATES[0:10];
        reg [127:0] VEC_ROUND_KEYS[0:10];
        
        integer current_round;
        reg [127:0] current_input_state;
        integer error_count;
    // Main Test Sequence
    initial begin
        //======================================================================
        // ALL DECLARATIONS AT THE TOP OF THE INITIAL BLOCK
        //======================================================================
        

        //======================================================================
        // PROCEDURAL CODE STARTS HERE
        //======================================================================

        // Populate all known vectors from the FIPS-197 Appendix B document
        VEC_PLAINTEXT  = 128'h3243f6a8885a308d313198a2e0370734;
        VEC_KEY        = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        VEC_CIPHERTEXT = 128'h3925841d02dc09fbdc118597196a0b32;

        // VEC_ROUND_STATES[i] is the data state at the *input* to Round i's transformations
        VEC_ROUND_STATES[0] = 128'h3243f6a8885a308d313198a2e0370734;
        VEC_ROUND_STATES[1] = 128'h193de3bea0f4e22b9ac68d2ae9f84808;
        VEC_ROUND_STATES[2] = 128'ha49c7ff2689f352b6b5bea43026a5049;
        VEC_ROUND_STATES[3] = 128'haa8f5f0361dde3ef82d24ad26832469a;
        VEC_ROUND_STATES[4] = 128'h486c4eee671d9d0d4de3b138d65f58e7;
        VEC_ROUND_STATES[5] = 128'he0927fe8c86363c0d9b1355085b8be01;
        VEC_ROUND_STATES[6] = 128'hf1006f55c1924cef7cc88b325db5d50c;
        VEC_ROUND_STATES[7] = 128'h260e2e173d41b77de86472a9fdd28b25;
        VEC_ROUND_STATES[8] = 128'h5a4142b11949dc1fa3e019657a8c040c;
        VEC_ROUND_STATES[9] = 128'hea835cf00445332d655d98ad8596b0c5;
        VEC_ROUND_STATES[10]= 128'heb40f21e592e38848ba113e71bc342d2;
        
        // VEC_ROUND_KEYS[i] is the key that is XORed during Round i
        VEC_ROUND_KEYS[0]  = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        VEC_ROUND_KEYS[1]  = 128'ha0fafe1788542cb123a339392a6c7605;
        VEC_ROUND_KEYS[2]  = 128'hf2c295f27a96b9435935807a7359f67f;
        VEC_ROUND_KEYS[3]  = 128'h3d80477d4716fe3e1e237e446d7a883b;
        VEC_ROUND_KEYS[4]  = 128'hef44a541a8525b7fb671253bdb0bad00;
        VEC_ROUND_KEYS[5]  = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
        VEC_ROUND_KEYS[6]  = 128'h6d88a37a110b3efddbf98641ca0093fd;
        VEC_ROUND_KEYS[7]  = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
        VEC_ROUND_KEYS[8]  = 128'head27321b58dbad2312bf5607f8d292f;
        VEC_ROUND_KEYS[9]  = 128'hac7766f319fadc2128d12941575c006e;
        VEC_ROUND_KEYS[10] = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;
        
        // 1. Initialize and Reset
        clk = 0;
        rst_n = 1'b0;
        start_encrypt = 1'b0;
        error_count = 0;
        #20;
        rst_n = 1'b1;
        #10;
        
        $display("--- Starting Detailed Top-Level AES-128 Verification ---");

        // 2. Load inputs and pulse start
        $display("\n[%0t ns] Loading plaintext and key...", $time);
        tb_plaintext_in = VEC_PLAINTEXT;
        tb_key_in       = VEC_KEY;
        start_encrypt = 1'b1;
        #10;
        start_encrypt = 1'b0;
        
        // 3. Monitor the FSM and verify each round
        wait (dut.state != dut.S_IDLE);

        while (dut.state != dut.S_DONE) begin
            if (dut.state == dut.S_INIT_ADD_KEY || dut.state == dut.S_ENCRYPT_ROUNDS || dut.state == dut.S_FINAL_ROUND) begin
                current_round = dut.round_counter;
                current_input_state = (current_round == 0) ? tb_plaintext_in : dut.state_reg;
                
                $display("\n--- Checking Start of Round %0d ---", current_round);
                
                // Check Data State
                if (current_input_state === VEC_ROUND_STATES[current_round]) begin
                    $display("PASS: Data state at start of round %0d is correct.", current_round);
                end else begin // SYNTAX FIX: This block contains multiple statements
                    $display("FAIL: Data state at start of round %0d is incorrect.", current_round);
                    $display("      Expected: %h", VEC_ROUND_STATES[current_round]);
                    $display("      Got:      %h", current_input_state);
                    error_count = error_count + 1;
                end
                
                // Check Round Key
                if (dut.current_round_key === VEC_ROUND_KEYS[current_round]) begin
                    $display("PASS: Round key for round %0d is correct.", current_round);
                end else begin // SYNTAX FIX: This block contains multiple statements
                    $display("FAIL: Round key for round %0d is incorrect.", current_round);
                    $display("      Expected: %h", VEC_ROUND_KEYS[current_round]);
                    $display("      Got:      %h", dut.current_round_key);
                    error_count = error_count + 1;
                end
            end
            
            @(posedge clk);
        end
        
        // 4. Final check after 'done' signal
        wait (tb_encrypt_done == 1'b1);
        $display("\n[%0t ns] 'encrypt_done' signal is high.", $time);
        #1;
        
        $display("\n--- Checking Final Ciphertext ---");
        if (tb_ciphertext_out === VEC_CIPHERTEXT) begin
            $display("PASS: Final ciphertext matches FIPS-197.");
        end else begin // SYNTAX FIX: This block contains multiple statements
            $display("FAIL: Final ciphertext is incorrect.");
            $display("      Expected: %h", VEC_CIPHERTEXT);
            $display("      Got:      %h", tb_ciphertext_out);
            error_count = error_count + 1;
        end

        // 5. Final Summary
        #20;
        if (error_count == 0) begin
            $display("\n--- VERIFICATION SUCCESSFUL: All intermediate and final values match FIPS-197. ---");
        end else begin
            $display("\n--- VERIFICATION FAILED with %d errors. ---", error_count);
        end

        $display("\n--- Detailed Verification Finished ---");
        $finish;
    end

endmodule