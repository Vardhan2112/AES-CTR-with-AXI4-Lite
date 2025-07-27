/*`timescale 1ns / 1ps
module tb_SMC_AXI_Top_Detailed;
    // Testbench signals
    reg         clk;
    reg         rst_n;
    // AXI Interface Signals
    reg  [5:0]  tb_awaddr;
    reg         tb_awvalid;
    wire        tb_awready;
    reg  [31:0] tb_wdata;
    reg  [3:0]  tb_wstrb;
    reg         tb_wvalid;
    wire        tb_wready;
    wire [1:0]  tb_bresp;
    wire        tb_bvalid;
    reg         tb_bready;
    reg  [5:0]  tb_araddr;
    reg         tb_arvalid;
    wire        tb_arready;
    wire [31:0] tb_rdata;
    wire [1:0]  tb_rresp;
    wire        tb_rvalid;
    reg         tb_rready;
    
    // Instantiate the DUT
    SMC_AXI_Top #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(6)
    ) dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(tb_awaddr), .S_AXI_AWVALID(tb_awvalid), .S_AXI_AWREADY(tb_awready),
        .S_AXI_WDATA(tb_wdata), .S_AXI_WSTRB(tb_wstrb), .S_AXI_WVALID(tb_wvalid), .S_AXI_WREADY(tb_wready),
        .S_AXI_BRESP(tb_bresp), .S_AXI_BVALID(tb_bvalid), .S_AXI_BREADY(tb_bready),
        .S_AXI_ARADDR(tb_araddr), .S_AXI_ARVALID(tb_arvalid), .S_AXI_ARREADY(tb_arready),
        .S_AXI_RDATA(tb_rdata), .S_AXI_RRESP(tb_rresp), .S_AXI_RVALID(tb_rvalid), .S_AXI_RREADY(tb_rready)
    );
    
    // Clock Generator
    always #5 clk = ~clk;
    
    // Test Vectors
    reg [127:0] VEC_PLAINTEXT = 128'hDEADBEEFCAFEF00D12345678ABCDEF01;
    reg [127:0] VEC_KEY       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    reg [95:0]  VEC_NONCE     = 96'hF0F1F2F3F4F5F6F7F8F9FAFB;
    reg [7:0]   TARGET_ADDR   = 8'hA5;
    reg [127:0] received_plaintext;
    
    // Parameter for Polling Delay
    parameter POLL_DELAY = 50;
    
    // Waveform Dumping
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_SMC_AXI_Top_Detailed);
    end
    
    // Signal Monitoring
    initial begin
        $monitor("Time=%t, Busy=%b, RDATA=%h", $time, tb_rdata[0], tb_rdata);
    end
    
    // Main Test Sequence
    initial begin
        // 1. Initialize and Reset
        clk = 0; rst_n = 1'b0;
        tb_awvalid = 0; tb_wvalid = 0; tb_bready = 0;
        tb_arvalid = 0; tb_rready = 0;
        #20; rst_n = 1'b1; #10;
        $display("--- Starting Detailed AXI-based System Verification ---");
        
        // PHASE 1: Configure SMC via AXI Writes
        $display("\n[%0t ns] PHASE 1: Configuring SMC registers via AXI...", $time);
        
        // Write Key (128-bit) - ADDRESSES CORRECT
        axil_write(6'h2C, VEC_KEY[31:0]);     // 0x2C -> slv_reg11
        axil_write(6'h30, VEC_KEY[63:32]);    // 0x30 -> slv_reg12
        axil_write(6'h34, VEC_KEY[95:64]);    // 0x34 -> slv_reg13
        axil_write(6'h38, VEC_KEY[127:96]);   // 0x38 -> slv_reg14
        
        // Write Nonce (96-bit) - ADDRESSES CORRECT
        axil_write(6'h3C, VEC_NONCE[31:0]);   // 0x3C -> slv_reg15
        axil_write(6'h40, VEC_NONCE[63:32]);  // 0x40 -> slv_reg16
        axil_write(6'h44, VEC_NONCE[95:64]);  // 0x44 -> slv_reg17
        
        // Write Target Address - CORRECT
        axil_write(6'h08, {24'b0, TARGET_ADDR}); // 0x08 -> slv_reg2
        
        // Write Input Data (128-bit) - ADDRESSES CORRECT
        axil_write(6'h0C, VEC_PLAINTEXT[31:0]);   // 0x0C -> slv_reg3
        axil_write(6'h10, VEC_PLAINTEXT[63:32]);  // 0x10 -> slv_reg4
        axil_write(6'h14, VEC_PLAINTEXT[95:64]);  // 0x14 -> slv_reg5
        axil_write(6'h18, VEC_PLAINTEXT[127:96]); // 0x18 -> slv_reg6
        
        // PHASE 2: Start Write Operation
        $display("\n[%0t ns] PHASE 2: Issuing Secure Write command...", $time);
        axil_write(6'h00, 32'h0000_0001); // Write enable bit
        
        // PHASE 3: Poll for Completion
        $display("\n[%0t ns] PHASE 3: Polling Status Register until not busy...", $time);
        axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        while (tb_rdata[0] == 1'b1) begin
            #POLL_DELAY;
            axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        end
        $display("[%0t ns] SMC is no longer busy. Write complete.", $time);
        
        // PHASE 4 & 5: Start Read and Poll
        $display("\n[%0t ns] PHASE 4/5: Issuing Secure Read command and polling...", $time);
        // FIXED: Removed unnecessary address register rewrite
        axil_write(6'h00, 32'h0000_0002); // Read enable bit
        
        axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        while (tb_rdata[0] == 1'b1) begin
            #POLL_DELAY;
            axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        end
        $display("[%0t ns] SMC is no longer busy. Read complete.", $time);
        
        // PHASE 6: Read back the result
        $display("\n[%0t ns] PHASE 6: Reading decrypted data from output registers...", $time);
        
        // FIXED: Corrected addresses for output registers
        axil_read(6'h1C, "Reading DATA_OUT_REG_0"); received_plaintext[31:0]   = tb_rdata;  // 0x1C
        axil_read(6'h20, "Reading DATA_OUT_REG_1"); received_plaintext[63:32]  = tb_rdata;  // 0x20
        axil_read(6'h24, "Reading DATA_OUT_REG_2"); received_plaintext[95:64]  = tb_rdata;  // 0x24
        axil_read(6'h28, "Reading DATA_OUT_REG_3"); received_plaintext[127:96] = tb_rdata;  // 0x28
        
        // Final Verification
        #20;
        $display("\n--- Final Verification ---");
        if (received_plaintext === VEC_PLAINTEXT) begin
            $display("PASS: Data read via AXI matches original plaintext.");
        end else begin
            $display("FAIL: Data read via AXI does NOT match!");
            $display("      Expected: %h", VEC_PLAINTEXT);
            $display("      Got:      %h", received_plaintext);
        end
        $finish;
    end
    
    // Enhanced AXI Write Task
    task axil_write(input [5:0] addr, input [31:0] data);
        begin
            $display("          AXI WRITE: Addr=0x%h, Data=0x%h", addr, data);
            fork
                begin
                    @(posedge clk);
                    tb_awvalid <= 1'b1; tb_awaddr <= addr;
                    wait (tb_awready == 1'b1);
                    @(posedge clk);
                    tb_awvalid <= 1'b0;
                end
                begin
                    @(posedge clk);
                    tb_wvalid <= 1'b1; tb_wdata <= data; tb_wstrb <= 4'hF;
                    wait (tb_wready == 1'b1);
                    @(posedge clk);
                    tb_wvalid <= 1'b0;
                end
            join
            tb_bready <= 1'b1;
            wait (tb_bvalid == 1'b1);
            if (tb_bresp != 2'b00) begin
                $display("          ERROR: Write response not OKAY (RESP=0x%h)", tb_bresp);
            end
            @(posedge clk);
            tb_bready <= 1'b0;
        end
    endtask
    
    // Enhanced AXI Read Task
    task axil_read(input [5:0] addr, input [127:0] description);
        begin
            $display("          AXI READ:  Addr=0x%h (%s)", addr, description);
            @(posedge clk);
            tb_arvalid <= 1'b1; tb_araddr <= addr;
            wait (tb_arready == 1'b1);
            @(posedge clk);
            tb_arvalid <= 1'b0;
            tb_rready <= 1'b1;
            wait (tb_rvalid == 1'b1);
            if (tb_rresp != 2'b00) begin
                $display("          ERROR: Read response not OKAY (RESP=0x%h)", tb_rresp);
            end
            @(posedge clk);
            tb_rready <= 1'b0;
        end
    endtask
    
endmodule*/
/*
`timescale 1ns / 1ps
module tb_SMC_AXI_Top_Detailed_cl;
    // Testbench signals
    reg         clk;
    reg         rst_n;
    // AXI Interface Signals
    reg  [7:0]  tb_awaddr;
    reg         tb_awvalid;
    wire        tb_awready;
    reg  [31:0] tb_wdata;
    reg  [3:0]  tb_wstrb;
    reg         tb_wvalid;
    wire        tb_wready;
    wire [1:0]  tb_bresp;
    wire        tb_bvalid;
    reg         tb_bready;
    reg  [7:0]  tb_araddr;
    reg         tb_arvalid;
    wire        tb_arready;
    wire [31:0] tb_rdata;
    wire [1:0]  tb_rresp;
    wire        tb_rvalid;
    reg         tb_rready;
    
    // Instantiate the DUT
    SMC_AXI_Top #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(8)
    ) dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(tb_awaddr), .S_AXI_AWVALID(tb_awvalid), .S_AXI_AWREADY(tb_awready),
        .S_AXI_WDATA(tb_wdata), .S_AXI_WSTRB(tb_wstrb), .S_AXI_WVALID(tb_wvalid), .S_AXI_WREADY(tb_wready),
        .S_AXI_BRESP(tb_bresp), .S_AXI_BVALID(tb_bvalid), .S_AXI_BREADY(tb_bready),
        .S_AXI_ARADDR(tb_araddr), .S_AXI_ARVALID(tb_arvalid), .S_AXI_ARREADY(tb_arready),
        .S_AXI_RDATA(tb_rdata), .S_AXI_RRESP(tb_rresp), .S_AXI_RVALID(tb_rvalid), .S_AXI_RREADY(tb_rready)
    );
    
    // Clock Generator
    always #5 clk = ~clk;
    
    // Test Vectors
    reg [127:0] VEC_PLAINTEXT = 128'hDEADBEEFCAFEF00D12345678ABCDEF01;
    reg [127:0] VEC_KEY       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    reg [95:0]  VEC_NONCE     = 96'hF0F1F2F3F4F5F6F7F8F9FAFB;
    reg [7:0]   TARGET_ADDR   = 8'hA5;
    reg [127:0] received_plaintext;
    
    // Parameter for Polling Delay
    parameter POLL_DELAY = 50;
    
    // Waveform Dumping
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_SMC_AXI_Top_Detailed_c);
    end
    
    // Signal Monitoring
    initial begin
        $monitor("Time=%t, Busy=%b, RDATA=%h", $time, tb_rdata[0], tb_rdata);
    end
    
    // Main Test Sequence
    initial begin
        // 1. Initialize and Reset
        clk = 0; rst_n = 1'b0;
        tb_awvalid = 0; tb_wvalid = 0; tb_bready = 0;
        tb_arvalid = 0; tb_rready = 0;
        #20; rst_n = 1'b1; #10;
        $display("--- Starting Detailed AXI-based System Verification ---");
        
        // PHASE 1: Configure SMC via AXI Writes
        $display("\n[%0t ns] PHASE 1: Configuring SMC registers via AXI...", $time);
        
        // Write Key (128-bit) - ADDRESSES CORRECT
        axil_write(8'h2C, VEC_KEY[31:0]);     // 0x2C -> slv_reg11
        axil_write(8'h30, VEC_KEY[63:32]);    // 0x30 -> slv_reg12
        axil_write(8'h34, VEC_KEY[95:64]);    // 0x34 -> slv_reg13
        axil_write(8'h38, VEC_KEY[127:96]);   // 0x38 -> slv_reg14
                   
        // Write No8ce (96-bit) - ADDRESSES CORRECT
        axil_write(8'h3C, VEC_NONCE[31:0]);   // 0x3C -> slv_reg15
        axil_write(8'h40, VEC_NONCE[63:32]);  // 0x40 -> slv_reg16
        axil_write(8'h44, VEC_NONCE[95:64]);  // 0x44 -> slv_reg17
                   
        // Write Ta8get Address - CORRECT
        axil_write(8'h08, {24'b0, TARGET_ADDR}); // 0x08 -> slv_reg2
                   
        // Write In8ut Data (128-bit) - ADDRESSES CORRECT
        axil_write(8'h0C, VEC_PLAINTEXT[31:0]);   // 0x0C -> slv_reg3
        axil_write(8'h10, VEC_PLAINTEXT[63:32]);  // 0x10 -> slv_reg4
        axil_write(8'h14, VEC_PLAINTEXT[95:64]);  // 0x14 -> slv_reg5
        axil_write(8'h18, VEC_PLAINTEXT[127:96]); // 0x18 -> slv_reg6
        
        // PHASE 2: Start Write Operation
        $display("\n[%0t ns] PHASE 2: Issuing Secure Write command...", $time);
        axil_write(6'h00, 32'h0000_0001); // Write enable bit
        
        // PHASE 3: Poll for Completion
        $display("\n[%0t ns] PHASE 3: Polling Status Register until not busy...", $time);
        axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        while (tb_rdata[0] == 1'b1) begin
            #POLL_DELAY;
            axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        end
        $display("[%0t ns] SMC is no longer busy. Write complete.", $time);
        
        // PHASE 4 & 5: Start Read and Poll
        $display("\n[%0t ns] PHASE 4/5: Issuing Secure Read command and polling...", $time);
        // FIXED: Removed unnecessary address register rewrite
        axil_write(6'h00, 32'h0000_0002); // Read enable bit
        
        axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        while (tb_rdata[0] == 1'b1) begin
            #POLL_DELAY;
            axil_read(6'h04, "Polling busy flag"); // FIXED: Changed from 6'h01 to 6'h04
        end
        $display("[%0t ns] SMC is no longer busy. Read complete.", $time);
        
        // PHASE 6: Read back the result
        $display("\n[%0t ns] PHASE 6: Reading decrypted data from output registers...", $time);
        
        // FIXED: Corrected addresses for output registers
        axil_read(6'h1C, "Reading DATA_OUT_REG_0"); received_plaintext[31:0]   = tb_rdata;  // 0x1C
        axil_read(6'h20, "Reading DATA_OUT_REG_1"); received_plaintext[63:32]  = tb_rdata;  // 0x20
        axil_read(6'h24, "Reading DATA_OUT_REG_2"); received_plaintext[95:64]  = tb_rdata;  // 0x24
        axil_read(6'h28, "Reading DATA_OUT_REG_3"); received_plaintext[127:96] = tb_rdata;  // 0x28
        
        // Final Verification
        #20;
        $display("\n--- Final Verification ---");
        if (received_plaintext === VEC_PLAINTEXT) begin
            $display("PASS: Data read via AXI matches original plaintext.");
        end else begin
            $display("FAIL: Data read via AXI does NOT match!");
            $display("      Expected: %h", VEC_PLAINTEXT);
            $display("      Got:      %h", received_plaintext);
        end
        $finish;
    end
    
    // Enhanced AXI Write Task
    task axil_write(input [7:0] addr, input [31:0] data);
        begin
            $display("          AXI WRITE: Addr=0x%h, Data=0x%h", addr, data);
            fork
                begin
                    @(posedge clk);
                    tb_awvalid <= 1'b1; tb_awaddr <= addr;
                    wait (tb_awready == 1'b1);
                    @(posedge clk);
                    tb_awvalid <= 1'b0;
                end
                begin
                    @(posedge clk);
                    tb_wvalid <= 1'b1; tb_wdata <= data; tb_wstrb <= 4'hF;
                    wait (tb_wready == 1'b1);
                    @(posedge clk);
                    tb_wvalid <= 1'b0;
                end
            join
            tb_bready <= 1'b1;
            wait (tb_bvalid == 1'b1);
            if (tb_bresp != 2'b00) begin
                $display("          ERROR: Write response not OKAY (RESP=0x%h)", tb_bresp);
            end
            @(posedge clk);
            tb_bready <= 1'b0;
        end
    endtask
    
    // Enhanced AXI Read Task
    task axil_read(input [7:0] addr, input [127:0] description);
        begin
            $display("          AXI READ:  Addr=0x%h (%s)", addr, description);
            @(posedge clk);
            tb_arvalid <= 1'b1; tb_araddr <= addr;
            wait (tb_arready == 1'b1);
            @(posedge clk);
            tb_arvalid <= 1'b0;
            tb_rready <= 1'b1;
            wait (tb_rvalid == 1'b1);
            if (tb_rresp != 2'b00) begin
                $display("          ERROR: Read response not OKAY (RESP=0x%h)", tb_rresp);
            end
            @(posedge clk);
            tb_rready <= 1'b0;
        end
    endtask
    
endmodule*/

`timescale 1ns / 1ps
module tb_SMC_AXI_Top_Detailed_cl;
    reg         clk;
    reg         rst_n;
    reg  [7:0]  tb_awaddr;
    reg         tb_awvalid;
    wire        tb_awready;
    reg  [31:0] tb_wdata;
    reg  [3:0]  tb_wstrb;
    reg         tb_wvalid;
    wire        tb_wready;
    wire [1:0]  tb_bresp;
    wire        tb_bvalid;
    reg         tb_bready;
    reg  [7:0]  tb_araddr;
    reg         tb_arvalid;
    wire        tb_arready;
    wire [31:0] tb_rdata;
    wire [1:0]  tb_rresp;
    wire        tb_rvalid;
    reg         tb_rready;
    
    SMC_AXI_Top #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(8)
    ) dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rst_n),
        .S_AXI_AWADDR(tb_awaddr), .S_AXI_AWVALID(tb_awvalid), .S_AXI_AWREADY(tb_awready),
        .S_AXI_WDATA(tb_wdata), .S_AXI_WSTRB(tb_wstrb), .S_AXI_WVALID(tb_wvalid), .S_AXI_WREADY(tb_wready),
        .S_AXI_BRESP(tb_bresp), .S_AXI_BVALID(tb_bvalid), .S_AXI_BREADY(tb_bready),
        .S_AXI_ARADDR(tb_araddr), .S_AXI_ARVALID(tb_arvalid), .S_AXI_ARREADY(tb_arready),
        .S_AXI_RDATA(tb_rdata), .S_AXI_RRESP(tb_rresp), .S_AXI_RVALID(tb_rvalid), .S_AXI_RREADY(tb_rready)
    );
    
    always #5 clk = ~clk;
    
    reg [127:0] VEC_PLAINTEXT = 128'hDEADBEEFCAFEF00D12345678ABCDEF01;
    reg [127:0] VEC_KEY       = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    reg [95:0]  VEC_NONCE     = 96'hF0F1F2F3F4F5F6F7F8F9FAFB;
    reg [7:0]   TARGET_ADDR   = 8'hA5;
    reg [127:0] received_plaintext;
    
    parameter POLL_DELAY = 50;
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_SMC_AXI_Top_Detailed_cl);
    end
    
    initial begin
        $monitor("Time=%t, Done=%b, RDATA=%h", $time, tb_rdata[1], tb_rdata);
    end
    
    initial begin
        clk = 0; rst_n = 1'b0;
        tb_awvalid = 0; tb_wvalid = 0; tb_bready = 0;
        tb_arvalid = 0; tb_rready = 0;
        #20; rst_n = 1'b1; #10;
        $display("--- Starting Detailed AXI-based System Verification ---");
        
        $display("\n[%0t ns] PHASE 1: Configuring SMC registers via AXI...", $time);
        axil_write(8'h2C, VEC_KEY[31:0]);
        axil_write(8'h30, VEC_KEY[63:32]);
        axil_write(8'h34, VEC_KEY[95:64]);
        axil_write(8'h38, VEC_KEY[127:96]);
        axil_write(8'h3C, VEC_NONCE[31:0]);
        axil_write(8'h40, VEC_NONCE[63:32]);
        axil_write(8'h44, VEC_NONCE[95:64]);
        axil_write(8'h08, {24'b0, TARGET_ADDR});
        axil_write(8'h0C, VEC_PLAINTEXT[31:0]);
        axil_write(8'h10, VEC_PLAINTEXT[63:32]);
        axil_write(8'h14, VEC_PLAINTEXT[95:64]);
        axil_write(8'h18, VEC_PLAINTEXT[127:96]);
        
        $display("\n[%0t ns] PHASE 2: Issuing Secure Write command...", $time);
        axil_write(8'h00, 32'h0000_0001);
        
        $display("\n[%0t ns] PHASE 3: Polling Status Register until done...", $time);
        axil_read(8'h04, "Polling done flag");
        while (tb_rdata[1] == 1'b0) begin
            #POLL_DELAY;
            axil_read(8'h04, "Polling done flag");
        end
        $display("[%0t ns] SMC operation is done. Write complete.", $time);
        
        $display("\n[%0t ns] PHASE 4/5: Issuing Secure Read command and polling...", $time);
        axil_write(8'h00, 32'h0000_0002);
        
        axil_read(8'h04, "Polling done flag");
        while (tb_rdata[1] == 1'b0) begin
            #POLL_DELAY;
            axil_read(8'h04, "Polling done flag");
        end
        $display("[%0t ns] SMC operation is done. Read complete.", $time);
        
        $display("\n[%0t ns] PHASE 6: Reading decrypted data from output registers...", $time);
        axil_read(8'h1C, "Reading DATA_OUT_REG_0"); received_plaintext[31:0]   = tb_rdata;
        axil_read(8'h20, "Reading DATA_OUT_REG_1"); received_plaintext[63:32]  = tb_rdata;
        axil_read(8'h24, "Reading DATA_OUT_REG_2"); received_plaintext[95:64]  = tb_rdata;
        axil_read(8'h28, "Reading DATA_OUT_REG_3"); received_plaintext[127:96] = tb_rdata;
        
        #20;
        $display("\n--- Final Verification ---");
        if (received_plaintext === VEC_PLAINTEXT) begin
            $display("PASS: Data read via AXI matches original plaintext.");
        end else begin
            $display("FAIL: Data read via AXI does NOT match!");
            $display("      Expected: %h", VEC_PLAINTEXT);
            $display("      Got:      %h", received_plaintext);
        end
        $finish;
    end
    
    task axil_write(input [7:0] addr, input [31:0] data);
        begin
            $display("          AXI WRITE: Addr=0x%h, Data=0x%h", addr, data);
            fork
                begin
                    @(posedge clk);
                    tb_awvalid <= 1'b1; tb_awaddr <= addr;
                    wait (tb_awready == 1'b1);
                    @(posedge clk);
                    tb_awvalid <= 1'b0;
                end
                begin
                    @(posedge clk);
                    tb_wvalid <= 1'b1; tb_wdata <= data; tb_wstrb <= 4'hF;
                    wait (tb_wready == 1'b1);
                    @(posedge clk);
                    tb_wvalid <= 1'b0;
                end
            join
            tb_bready <= 1'b1;
            wait (tb_bvalid == 1'b1);
            if (tb_bresp != 2'b00) begin
                $display("          ERROR: Write response not OKAY (RESP=0x%h)", tb_bresp);
            end
            @(posedge clk);
            tb_bready <= 1'b0;
        end
    endtask
    
    task axil_read(input [7:0] addr, input [127:0] description);
        begin
            $display("          AXI READ:  Addr=0x%h (%s)", addr, description);
            @(posedge clk);
            tb_arvalid <= 1'b1; tb_araddr <= addr;
            wait (tb_arready == 1'b1);
            @(posedge clk);
            tb_arvalid <= 1'b0;
            tb_rready <= 1'b1;
            wait (tb_rvalid == 1'b1);
            if (tb_rresp != 2'b00) begin
                $display("          ERROR: Read response not OKAY (RESP=0x%h)", tb_rresp);
            end
            @(posedge clk);
            tb_rready <= 1'b0;
        end
    endtask
    
endmodule