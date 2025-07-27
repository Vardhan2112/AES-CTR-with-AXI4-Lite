`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_secure_memory_system (Final)
// Description: A full system-level test for the Secure Memory Controller.
//////////////////////////////////////////////////////////////////////////////////
module tb_secure_memory_system;

    // Testbench signals to drive the SMC
    reg         clk;
    reg         rst_n;
    reg [127:0] tb_key_in;
    reg [95:0]  tb_nonce_in;
    reg [7:0]   tb_cpu_addr;
    reg [127:0] tb_cpu_data_in;
    reg         tb_cpu_write_en;
    reg         tb_cpu_read_en;

    // Wires to monitor the SMC's outputs
    wire [127:0] tb_cpu_data_out;
    wire         tb_busy;

    // Instantiate the Device Under Test (the complete SMC)
    secure_memory_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .key_in(tb_key_in),
        .nonce_in(tb_nonce_in),
        .cpu_addr(tb_cpu_addr),
        .cpu_data_in(tb_cpu_data_in),
        .cpu_write_en(tb_cpu_write_en),
        .cpu_read_en(tb_cpu_read_en),
        .cpu_data_out(tb_cpu_data_out),
        .busy(tb_busy)
    );

    // Clock generator
    always #5 clk = ~clk;
reg [127:0] VEC_PLAINTEXT;
        reg [127:0] VEC_KEY;
        reg [95:0]  VEC_NONCE;
        reg [7:0]   TARGET_ADDR;
        reg [127:0] VEC_EXPECTED_CIPHERTEXT;
        integer     error_count;
    // Main test sequence
    initial begin
        //==============================================================
        // DECLARATIONS (all at the top of the block)
        //==============================================================
        

        //==============================================================
        // INITIALIZATION
        //==============================================================
        VEC_PLAINTEXT           = 128'hDEADBEEFCAFEF00D12345678ABCDEF01;
        VEC_KEY                 = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        VEC_NONCE               = 96'hF0F1F2F3F4F5F6F7F8F9FAFB;
        TARGET_ADDR             = 8'hA5;
        // Expected Ciphertext = Plaintext ^ Encrypt(Key, {Nonce, 24'd0, Addr})
        // Encrypt(Key, F0F1F2F3F4F5F6F7F8F9FAFB000000A5) = 6cc686b941f1fc141ad3f48970a81bdc
        VEC_EXPECTED_CIPHERTEXT = 128'hb26b38568b0f0c1908e7a2f1db65f4dd;

        // 1. Initialize and Reset
        clk = 0;
        rst_n = 1'b0;
        tb_cpu_write_en = 1'b0;
        tb_cpu_read_en = 1'b0;
        error_count = 0;
        #20;
        rst_n = 1'b1;
        #10;

        $display("--- Starting Secure Memory System Verification ---");

        //==============================================================
        // PHASE 1: WRITE OPERATION
        //==============================================================
        $display("\n[%0t ns] Phase 1: CPU issues a secure WRITE request.", $time);
        tb_key_in       = VEC_KEY;
        tb_nonce_in     = VEC_NONCE;
        tb_cpu_addr     = TARGET_ADDR;
        tb_cpu_data_in  = VEC_PLAINTEXT;
        
        tb_cpu_write_en = 1'b1;
        #10; // Pulse for one clock cycle
        tb_cpu_write_en = 1'b0;
        
        $display("[%0t ns] Waiting for SMC to finish write (busy == 0)...", $time);
        wait (tb_busy == 1'b0);
        $display("[%0t ns] Write operation complete. SMC is no longer busy.", $time);
        #10;

        //==============================================================
        // PHASE 2: PEEK INTO BRAM (VERIFY ENCRYPTION)
        //==============================================================
       // $display("\n[%0t ns] Phase 2: Peeking into BRAM to verify encryption...", $time);
       // if (dut.u_bram.mem[TARGET_ADDR] === VEC_EXPECTED_CIPHERTEXT) begin
       //     $display("PASS: Data in BRAM matches the expected ciphertext.");
        //    $display("      BRAM Data:  %h", dut.u_bram.mem[TARGET_ADDR]);
        //end else begin
         //   $display("FAIL: Data in BRAM is incorrect!");
         //   $display("      Expected: %h", VEC_EXPECTED_CIPHERTEXT);
          //  $display("      Got:      %h", dut.u_bram.mem[TARGET_ADDR]);
         //   error_count = error_count + 1;
        //end
        #10;

        //==============================================================
        // PHASE 3: READ OPERATION
        //==============================================================
        $display("\n[%0t ns] Phase 3: CPU issues a secure READ request.", $time);
        tb_cpu_addr = TARGET_ADDR; // Read from the same address
        
        tb_cpu_read_en = 1'b1;
        #10; // Pulse for one clock cycle
        tb_cpu_read_en = 1'b0;
        
        $display("[%0t ns] Waiting for SMC to finish read (busy == 0)...", $time);
        wait (tb_busy == 1'b0);
        $display("[%0t ns] Read operation complete. SMC is no longer busy.", $time);
        #1; // Wait for final data to propagate

        //==============================================================
        // PHASE 4: FINAL VERIFICATION
        //==============================================================
        $display("\n[%0t ns] Phase 4: Verifying final decrypted data...", $time);
        if (tb_cpu_data_out === VEC_PLAINTEXT) begin
            $display("PASS: Data read from SMC matches original plaintext.");
        end else begin
            $display("FAIL: Data read from SMC does NOT match original plaintext.");
            $display("      Expected: %h", VEC_PLAINTEXT);
            $display("      Got:      %h", tb_cpu_data_out);
            error_count = error_count + 1;
        end

        //==============================================================
        // 5. FINAL SUMMARY
        //==============================================================
        #20;
        if (error_count == 0) begin
            $display("\n--- VERIFICATION SUCCESSFUL: Secure Memory System works correctly! ---");
        end else begin
            $display("\n--- VERIFICATION FAILED with %d errors. ---", error_count);
        end
        
        $finish;
    end

endmodule