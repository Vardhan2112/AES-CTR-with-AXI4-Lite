`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_aes_128_decrypt_detailed
// Description: A detailed, white-box testbench for the aes_128_decrypt core.
//              It verifies all intermediate round states and keys against
//              the FIPS-197 Appendix B example, in reverse order.
//////////////////////////////////////////////////////////////////////////////////
module tb_aes_128_decrypt_detailed;

    // Testbench signals
    reg         clk;
    reg         rst_n;
    reg         start_decrypt;
    reg [127:0] tb_ciphertext_in;
    reg [127:0] tb_key_in;

    wire [127:0] tb_plaintext_out;
    wire         tb_decrypt_done;

    // Instantiate the Device Under Test (DUT)
    aes_128_decrypt dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_decrypt(start_decrypt),
        .ciphertext_in(tb_ciphertext_in),
        .key_in(tb_key_in),
        .plaintext_out(tb_plaintext_out),
        .decrypt_done(tb_decrypt_done)
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
        // DECLARATIONS
        //======================================================================
        

        //======================================================================
        // VECTORS INITIALIZATION
        //======================================================================
        VEC_PLAINTEXT  = 128'h3243f6a8885a308d313198a2e0370734;
        VEC_KEY        = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        VEC_CIPHERTEXT = 128'h3925841d02dc09fbdc118597196a0b32;

        // Note: These are the states at the *end* of the corresponding encryption round,
        // which are the states at the *beginning* of the decryption round.
        VEC_ROUND_STATES[10] = 128'h3925841d02dc09fbdc118597196a0b32; // This is the ciphertext
        VEC_ROUND_STATES[9]  = 128'he9317db5cb322c723d2e895faf090794;
        VEC_ROUND_STATES[8]  = 128'h876e46a6f24ce78c4d904ad897ecc395;
        VEC_ROUND_STATES[7]  = 128'hbe3bd4fed4e1f2c80a642cc0da83864d;
        VEC_ROUND_STATES[6]  = 128'hf783403f27433df09bb531ff54aba9d3;
        VEC_ROUND_STATES[5]  = 128'ha14f3dfe78e803fc10d5a8df4c632923;
        VEC_ROUND_STATES[4]  = 128'he1fb967ce8c8ae9b356cd2ba974ffb53;
        VEC_ROUND_STATES[3]  = 128'h52a4c89485116a28e3cf2fd7f6505e07;
        VEC_ROUND_STATES[2]  = 128'hacc1d6b8efb55a7b1323cfdf457311b5;
        VEC_ROUND_STATES[1]  = 128'h49db873b453953897f02d2f177de961a;
        VEC_ROUND_STATES[0]  = 128'hd4bf5d30e0b452aeb84111f11e2798e5;
        
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
        start_decrypt = 1'b0;
        error_count = 0;
        #20;
        rst_n = 1'b1;
        #10;
        
        $display("--- Starting Detailed Top-Level AES-128 Decryption Verification ---");

        // 2. Load inputs and pulse start
        $display("\n[%0t ns] Loading ciphertext and key...", $time);
        tb_ciphertext_in = VEC_CIPHERTEXT;
        tb_key_in        = VEC_KEY;
        start_decrypt = 1'b1;
        #10;
        start_decrypt = 1'b0;
        
        // 3. Monitor the FSM and verify each round
        wait (dut.state != dut.S_IDLE);

        while (dut.state != dut.S_DONE) begin
            // Check at the beginning of the initial AddKey and the standard decrypt rounds
            if (dut.state == dut.S_INIT_ADD_KEY || dut.state == dut.S_DECRYPT_ROUNDS) begin
                current_round = dut.round_counter;
                current_input_state = (current_round == 10) ? tb_ciphertext_in : dut.state_reg;
                
                $display("\n--- Checking Start of Decryption Round %0d ---", current_round);
                
                // Check Data State
                if (current_input_state === VEC_ROUND_STATES[current_round]) begin
                    $display("PASS: Data state for round %0d is correct.", current_round);
                end else begin
                    $display("FAIL: Data state for round %0d is incorrect.", current_round);
                    $display("      Expected: %h", VEC_ROUND_STATES[current_round]);
                    $display("      Got:      %h", current_input_state);
                    error_count = error_count + 1;
                end
                
                // Check Round Key
                if (dut.current_round_key === VEC_ROUND_KEYS[current_round]) begin
                    $display("PASS: Round key for round %0d is correct.", current_round);
                end else begin
                    $display("FAIL: Round key for round %0d is incorrect.", current_round);
                    $display("      Expected: %h", VEC_ROUND_KEYS[current_round]);
                    $display("      Got:      %h", dut.current_round_key);
                    error_count = error_count + 1;
                end
            end
            
            @(posedge clk);
        end
        
        // 4. Final check after 'done' signal
        wait (tb_decrypt_done == 1'b1);
        $display("\n[%0t ns] 'decrypt_done' signal is high.", $time);
        #1;
        
        $display("\n--- Checking Final Plaintext ---");
        if (tb_plaintext_out === VEC_PLAINTEXT) begin
            $display("PASS: Final plaintext matches the original plaintext.");
        end else begin
            $display("FAIL: Final plaintext is incorrect.");
            $display("      Expected: %h", VEC_PLAINTEXT);
            $display("      Got:      %h", tb_plaintext_out);
            error_count = error_count + 1;
        end

        // 5. Final Summary
        #20;
        if (error_count == 0) begin
            $display("\n--- VERIFICATION SUCCESSFUL: All decryption values match FIPS-197. ---");
        end else begin
            $display("\n--- VERIFICATION FAILED with %d errors. ---", error_count);
        end

        $display("\n--- Detailed Verification Finished ---");
        $finish;
    end

endmodule