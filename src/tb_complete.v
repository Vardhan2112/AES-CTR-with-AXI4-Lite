`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_aes_loopback
// Description: A full, end-to-end loopback test for the AES core.
//              1. Encrypts a known plaintext using the encryption core.
//              2. Feeds the resulting ciphertext to the decryption core.
//              3. Verifies that the final output matches the original plaintext.
//////////////////////////////////////////////////////////////////////////////////
module tb_aes_loopback;

    // Testbench signals
    reg         clk;
    reg         rst_n;
    
    // Signals for the Encryption Core
    reg         start_encrypt;
    reg [127:0] plaintext_in;
    wire [127:0] ciphertext_out;
    wire         encrypt_done;

    // Signals for the Decryption Core
    reg         start_decrypt;
    // The input to the decryptor is the output of the encryptor
    wire [127:0] ciphertext_in_for_decrypt; 
    wire [127:0] plaintext_out;
    wire         decrypt_done;

    // Common key for both cores
    reg [127:0] key_in;

    // Latch the ciphertext after encryption is done
    reg [127:0] latched_ciphertext;
    assign ciphertext_in_for_decrypt = latched_ciphertext;

    //==============================================================
    // DUT Instantiations
    //==============================================================
    
    // Instantiate the Encryption Core
    aes_128_encrypt u_encrypt (
        .clk(clk),
        .rst_n(rst_n),
        .start_encrypt(start_encrypt),
        .plaintext_in(plaintext_in),
        .key_in(key_in),
        .ciphertext_out(ciphertext_out),
        .encrypt_done(encrypt_done)
    );

    // Instantiate the Decryption Core
    aes_128_decrypt u_decrypt (
        .clk(clk),
        .rst_n(rst_n),
        .start_decrypt(start_decrypt),
        .ciphertext_in(ciphertext_in_for_decrypt),
        .key_in(key_in),
        .plaintext_out(plaintext_out),
        .decrypt_done(decrypt_done)
    );

    //==============================================================
    // Test Sequence
    //==============================================================
    
    // Clock Generator (100 MHz)
    always #5 clk = ~clk;
reg [127:0] VEC_PLAINTEXT = 128'h3243f6a8885a308d313198a2e0370734;
        reg [127:0] VEC_KEY       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    initial begin
        // Use the FIPS-197 Appendix B vectors as our starting point
        

        // 1. Initialize and Reset
        clk = 0;
        rst_n = 1'b0; // Assert reset
        start_encrypt = 1'b0;
        start_decrypt = 1'b0;
        #20;
        rst_n = 1'b1; // De-assert reset
        #10;

        $display("--- Starting AES Encrypt/Decrypt Loopback Verification ---");

        //-----------------------------------------------------
        // PHASE 1: ENCRYPTION
        //-----------------------------------------------------
        $display("\n[%0t ns] Starting Encryption Phase...", $time);
        plaintext_in = VEC_PLAINTEXT;
        key_in       = VEC_KEY;
        start_encrypt = 1'b1;
        #10; // Pulse for one clock cycle
        start_encrypt = 1'b0;
        
        $display("[%0t ns] Waiting for encryption to complete...", $time);
        wait (encrypt_done == 1'b1);
        $display("[%0t ns] Encryption Done. Ciphertext is: %h", $time, ciphertext_out);
        #1; // Give a small delay for signals to settle
        
        // Latch the ciphertext to feed into the decryption core
        latched_ciphertext = ciphertext_out;
        #10; // Wait a clock cycle before starting decryption

        //-----------------------------------------------------
        // PHASE 2: DECRYPTION
        //-----------------------------------------------------
        $display("\n[%0t ns] Starting Decryption Phase...", $time);
        start_decrypt = 1'b1;
        #10; // Pulse for one clock cycle
        start_decrypt = 1'b0;
        

        $display("[%0t ns] Waiting for decryption to complete...", $time);
        wait (decrypt_done == 1'b1);
        $display("[%0t ns] Decryption Done. Final plaintext is: %h", $time, plaintext_out);
        #1;
        
        //-----------------------------------------------------
        // PHASE 3: FINAL VERIFICATION
        //-----------------------------------------------------
        $display("\n--- Final Verification ---");
        if (plaintext_out === VEC_PLAINTEXT) begin
            $display("PASS: Decrypted output matches the original plaintext.");
            $display("      Original:  %h", VEC_PLAINTEXT);
            $display("      Final:     %h", plaintext_out);
            $display("\n--- VERIFICATION SUCCESSFUL: Encrypt and Decrypt cores are perfect inverses. ---");
        end else begin
            $display("FAIL: Decrypted output DOES NOT match the original plaintext.");
            $display("      Original:  %h", VEC_PLAINTEXT);
            $display("      Final:     %h", plaintext_out);
            $display("\n--- VERIFICATION FAILED ---");
        end

        $finish;
    end

endmodule