`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.07.2025 13:24:23
// Design Name: 
// Module Name: SMC_AXI_Top
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
// Module: SMC_AXI_Top
// Description: An AXI4-Lite slave wrapper for the Secure Memory Controller.
//              Provides a memory-mapped register interface for CPU control.
//////////////////////////////////////////////////////////////////////////////////

/*module SMC_AXI_Top #(
    // Parameters for the AXI interface
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6 // 2^6 = 64 addresses, enough for our map
)(
    // AXI4-Lite Slave Ports
    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,
    // Write Channels
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                          S_AXI_AWVALID,
    output wire                          S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input  wire                          S_AXI_WVALID,
    output wire                          S_AXI_WREADY,
    output wire [1:0]                    S_AXI_BRESP,
    output wire                          S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,
    // Read Channels
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                          S_AXI_ARVALID,
    output wire                          S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,
    output wire                          S_AXI_RVALID,
    input  wire                          S_AXI_RREADY
);

    //==============================================================
    // 1. AXI Protocol Logic Signals
    //==============================================================
    // Internal registers to drive the AXI output ports
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg                          axi_awready;
    reg                          axi_wready;
    reg [1:0]                    axi_bresp;
    reg                          axi_bvalid;

    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg                          axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0]                    axi_rresp;
    reg                          axi_rvalid;

    // Connect internal registers to the output ports
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    //==============================================================
    // 2. Memory-Mapped Slave Registers
    //==============================================================
    reg [31:0] slv_reg0;  // Control
    reg [31:0] slv_reg1;  // Status
    reg [31:0] slv_reg2;  // Address
    reg [31:0] slv_reg3, slv_reg4, slv_reg5, slv_reg6; // Data In
    reg [31:0] slv_reg7, slv_reg8, slv_reg9, slv_reg10; // Data Out
    reg [31:0] slv_reg11, slv_reg12, slv_reg13, slv_reg14; // Key
    reg [31:0] slv_reg15, slv_reg16, slv_reg17; // Nonce

    //==============================================================
    // 3. Wires to connect to our internal SMC
    //==============================================================
    wire [127:0] smc_key_in    = {slv_reg14, slv_reg13, slv_reg12, slv_reg11};
    wire [95:0]  smc_nonce_in  = {slv_reg17[31:0], slv_reg16, slv_reg15}; // Assuming slv_reg17 holds upper bits
    wire [7:0]   smc_cpu_addr  = slv_reg2[7:0];
    wire [127:0] smc_cpu_data_in = {slv_reg6, slv_reg5, slv_reg4, slv_reg3};
    wire         smc_write_en  = slv_reg0[0]; // Bit 0 of control reg
    wire         smc_read_en   = slv_reg0[1]; // Bit 1 of control reg
    
    wire [127:0] smc_cpu_data_out;
    wire         smc_busy;

    //==============================================================
    // 4. Instantiate our verified Secure Memory Controller
    //==============================================================
    secure_memory_controller u_smc (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .key_in(smc_key_in),
        .nonce_in(smc_nonce_in),
        .cpu_addr(smc_cpu_addr),
        .cpu_data_in(smc_cpu_data_in),
        .cpu_write_en(smc_write_en),
        .cpu_read_en(smc_read_en),
        .cpu_data_out(smc_cpu_data_out),
        .busy(smc_busy)
    );

    //==============================================================
    // AXI LOGIC IMPLEMENTATION WILL GO HERE...
    //==============================================================

    // The AXI protocol requires us to latch the address and data when a valid
    // transaction occurs. 'slv_reg_wren' will be our signal for this.
    wire slv_reg_wren;
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    //--------------------------------------------------------------
    // Block 1: AXI Write Handshake Logic (awready, wready, bvalid)
    //--------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_bresp   <= 2'b0;
        end else begin
            // --- AWREADY Logic ---
            // We are ready to accept an address if we are not already processing one.
            if (~axi_awready && S_AXI_AWVALID) begin
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end
            
            // --- WREADY Logic ---
            // We are ready to accept data if we are not already processing one.
            if (~axi_wready && S_AXI_WVALID) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
            
            // --- BVALID Logic ---
            // Assert bvalid for one cycle after a successful write.
            if (slv_reg_wren) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00; // 'OKAY' response
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end
    
    //--------------------------------------------------------------
    // Block 2: Slave Register Write Logic
    //--------------------------------------------------------------
    // This block updates our internal memory-mapped registers when a
    // valid write transaction occurs.
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            // Reset all slave registers
            slv_reg0 <= 32'b0; slv_reg1 <= 32'b0; slv_reg2 <= 32'b0;
            slv_reg3 <= 32'b0; slv_reg4 <= 32'b0; slv_reg5 <= 32'b0;
            slv_reg6 <= 32'b0; slv_reg7 <= 32'b0; slv_reg8 <= 32'b0;
            slv_reg9 <= 32'b0; slv_reg10 <= 32'b0; slv_reg11 <= 32'b0;
            slv_reg12 <= 32'b0; slv_reg13 <= 32'b0; slv_reg14 <= 32'b0;
            slv_reg15 <= 32'b0; slv_reg16 <= 32'b0; slv_reg17 <= 32'b0;
        end else begin
            if (slv_reg_wren) begin
                // Use a case statement on the address to write to the correct register
                case (S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH-1:2]) // Use upper bits of address
                    // Note: We divide by 4 (shift by 2) because each register is 32-bits (4 bytes)
                    'h0: slv_reg0 <= S_AXI_WDATA; // CONTROL_REG at 0x00
                    'h1: slv_reg1 <= S_AXI_WDATA; // Reserved for Status
                    'h2: slv_reg2 <= S_AXI_WDATA; // ADDR_REG at 0x08
                    'h3: slv_reg3 <= S_AXI_WDATA; // DATA_IN_REG[31:0] at 0x0C
                    'h4: slv_reg4 <= S_AXI_WDATA; // DATA_IN_REG[63:32] at 0x10
                    'h5: slv_reg5 <= S_AXI_WDATA; // DATA_IN_REG[95:64] at 0x14
                    'h6: slv_reg6 <= S_AXI_WDATA; // DATA_IN_REG[127:96] at 0x18
                    // Registers 7-10 are for reading data out, so they are not writable
                    'hB: slv_reg11 <= S_AXI_WDATA; // KEY_REG[31:0] at 0x2C
                    'hC: slv_reg12 <= S_AXI_WDATA; // KEY_REG[63:32] at 0x30
                    'hD: slv_reg13 <= S_AXI_WDATA; // KEY_REG[95:64] at 0x34
                    'hE: slv_reg14 <= S_AXI_WDATA; // KEY_REG[127:96] at 0x38
                    'hF: slv_reg15 <= S_AXI_WDATA; // NONCE_REG[31:0] at 0x3C
                    'h10: slv_reg16 <= S_AXI_WDATA; // NONCE_REG[63:32] at 0x40
                    'h11: slv_reg17 <= S_AXI_WDATA; // NONCE_REG[95:64] at 0x44
                    default: ; // Do nothing for unmapped addresses
                endcase
            end
        end
    end

    //--------------------------------------------------------------
    // Block 3: AXI Read Handshake Logic (arready, rvalid)
    //--------------------------------------------------------------
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rresp   <= 2'b0;
            axi_araddr  <= 0; // Internal latched address
        end else begin
            // --- ARREADY Logic ---
            // We are ready to accept a read address if we are not already processing one.
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR; // Latch the read address
            end else begin
                axi_arready <= 1'b0;
            end
            
            // --- RVALID Logic ---
            // Assert rvalid for one cycle after arready has been asserted.
            // This indicates the data will be valid on the next cycle.
            if (axi_arready && S_AXI_ARVALID) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0; // 'OKAY' response
            end else if (S_AXI_RREADY && axi_rvalid) begin
                // De-assert when the master has taken the data.
                axi_rvalid <= 1'b0;
            end
        end
    end

    //--------------------------------------------------------------
    // Block 4: Slave Register Read Logic (Mux)
    //--------------------------------------------------------------
    // This block combinationally selects which internal register's data
    // to place on the read data bus.
    always @(*) begin
        // The read data is selected based on the latched read address
        case (axi_araddr[C_S_AXI_ADDR_WIDTH-1:2])
            'h0: axi_rdata <= slv_reg0; // Read Control Reg (mostly for debug)
            'h1: axi_rdata <= {31'b0, smc_busy}; // STATUS_REG at 0x04
            // Registers 2-6 are Write-Only
            'h7: axi_rdata <= smc_cpu_data_out[31:0];   // DATA_OUT_REG[31:0] at 0x1C
            'h8: axi_rdata <= smc_cpu_data_out[63:32];  // DATA_OUT_REG[63:32] at 0x20
            'h9: axi_rdata <= smc_cpu_data_out[95:64];  // DATA_OUT_REG[95:64] at 0x24
            'hA: axi_rdata <= smc_cpu_data_out[127:96]; // DATA_OUT_REG[127:96] at 0x28
            // Registers 11-17 are Write-Only
            default: axi_rdata <= 32'b0; // Return 0 for unmapped addresses
        endcase
    end

//==============================================================
// End of module
//==============================================================
endmodule*/
/*

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: SMC_AXI_Top (Fixed Version)
// Description: An AXI4-Lite slave wrapper for the Secure Memory Controller.
//              All timing issues, protocol violations, and synthesizability 
//              problems have been addressed.
//////////////////////////////////////////////////////////////////////////////////
module SMC_AXI_Top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8//changed to 8 from 6
)(
    // AXI4-Lite Slave Ports
    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                          S_AXI_AWVALID,
    output wire                          S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input  wire                          S_AXI_WVALID,
    output wire                          S_AXI_WREADY,
    output wire [1:0]                    S_AXI_BRESP,
    output wire                          S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,
    // Read Ports
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                          S_AXI_ARVALID,
    output wire                          S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,
    output wire                          S_AXI_RVALID,
    input  wire                          S_AXI_RREADY
);

    //==============================================================
    // 1. AXI Protocol Internal Signals
    //==============================================================
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;
    
    // Connect internal regs to AXI ports
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    //==============================================================
    // 2. Write Transaction State Machine
    //==============================================================
    localparam [1:0] WRITE_IDLE   = 2'b00;
    localparam [1:0] WRITE_DATA   = 2'b01;
    localparam [1:0] WRITE_RESP   = 2'b10;
    
    reg [1:0] write_state;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg write_reg_en;
    reg write_error;
    
    //==============================================================
    // 3. Memory-Mapped Slave Registers
    //==============================================================
    reg [31:0] slv_reg0;  // Control register
    reg [31:0] slv_reg1;  // Status register (read-only)
    reg [31:0] slv_reg2;  // CPU address
    reg [31:0] slv_reg3, slv_reg4, slv_reg5, slv_reg6;   // CPU data in (128-bit)
    reg [127:0] slv_data_out_reg; // CPU data out (128-bit)
    reg [31:0] slv_reg11, slv_reg12, slv_reg13, slv_reg14; // Key (128-bit)
    reg [31:0] slv_reg15, slv_reg16, slv_reg17;           // Nonce (96-bit)
    
    // Control signal generation with proper pulse behavior
    reg [2:0] write_pulse_counter;
    reg [2:0] read_pulse_counter;
    reg cpu_write_pulse;
    reg cpu_read_pulse;
    
    // Integer for loops (Verilog-2001 compliant)
    integer i;

    //==============================================================
    // 4. SMC Connection Wires (with synchronizers for safety)
    //==============================================================
    wire         smc_busy;
    wire [127:0] smc_cpu_data_out;
    
    // Synchronizer for SMC outputs (assuming same clock domain, but safer)
    reg smc_busy_sync;
    reg [127:0] smc_cpu_data_out_sync;
    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            smc_busy_sync <= 1'b0;
            smc_cpu_data_out_sync <= 128'b0;
        end else begin
            smc_busy_sync <= smc_busy;
            smc_cpu_data_out_sync <= smc_cpu_data_out;
        end
    end

    //==============================================================
    // 5. SMC Instantiation
    //==============================================================
    secure_memory_controller u_smc (
        .clk(S_AXI_ACLK), 
        .rst_n(S_AXI_ARESETN),
        .key_in({slv_reg14, slv_reg13, slv_reg12, slv_reg11}),
        .nonce_in({slv_reg17, slv_reg16, slv_reg15}),
        .cpu_addr(slv_reg2[7:0]),
        .cpu_data_in({slv_reg6, slv_reg5, slv_reg4, slv_reg3}),
        .cpu_write_en(cpu_write_pulse),
        .cpu_read_en(cpu_read_pulse),
        .cpu_data_out(smc_cpu_data_out),
        .busy(smc_busy)
    );

    //==============================================================
    // 6. AXI Write State Machine
    //==============================================================
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            write_state <= WRITE_IDLE;
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_bresp   <= 2'b00;
            axi_awaddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            write_reg_en <= 1'b0;
            write_error <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    axi_awready <= 1'b0;
                    axi_wready  <= 1'b0;
                    axi_bvalid  <= 1'b0;
                    write_reg_en <= 1'b0;
                    write_error <= 1'b0;
                    
                    if (S_AXI_AWVALID) begin
                        axi_awready <= 1'b1;
                        axi_awaddr <= S_AXI_AWADDR;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    axi_awready <= 1'b0;
                    
                    if (S_AXI_WVALID) begin
                        axi_wready <= 1'b1;
                        write_reg_en <= 1'b1;
                        
                        // Check for write to read-only register
                        case (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2])
                            6'h01: write_error <= 1'b1; // Status register is read-only
                            6'h07, 6'h08, 6'h09, 6'h0A: write_error <= 1'b1; // Data out registers are read-only
                            default: write_error <= 1'b0;
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    axi_wready <= 1'b0;
                    write_reg_en <= 1'b0;
                    axi_bvalid <= 1'b1;
                    axi_bresp <= write_error ? 2'b10 : 2'b00; // SLVERR or OKAY
                    
                    if (S_AXI_BREADY) begin
                        axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end

    //==============================================================
    // 7. Register Writing Logic
    //==============================================================
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 32'b0; slv_reg2 <= 32'b0; slv_reg3 <= 32'b0; slv_reg4 <= 32'b0;
            slv_reg5 <= 32'b0; slv_reg6 <= 32'b0; slv_reg11 <= 32'b0; slv_reg12 <= 32'b0;
            slv_reg13 <= 32'b0; slv_reg14 <= 32'b0; slv_reg15 <= 32'b0; slv_reg16 <= 32'b0;
            slv_reg17 <= 32'b0;
        end else begin
            if (write_reg_en && !write_error) begin
                case (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2])
                    6'h00: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg0[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h02: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg2[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h03: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg3[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h04: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg4[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h05: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg5[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h06: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg6[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0B: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg11[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0C: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg12[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0D: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg13[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0E: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg14[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0F: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg15[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h10: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg16[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h11: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg17[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    default: ; // Ignore writes to undefined addresses
                endcase
            end
        end
    end

    //==============================================================
    // 8. Control Signal Pulse Generation
    //==============================================================
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            write_pulse_counter <= 3'b0;
            read_pulse_counter <= 3'b0;
            cpu_write_pulse <= 1'b0;
            cpu_read_pulse <= 1'b0;
        end else begin
            // Write pulse generation
            if (write_reg_en && !write_error && (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2] == 6'h00) && slv_reg0[0]) begin
                write_pulse_counter <= 3'b100; // 4 clock pulse width
                cpu_write_pulse <= 1'b1;
            end else if (write_pulse_counter > 0) begin
                write_pulse_counter <= write_pulse_counter - 1'b1;
                cpu_write_pulse <= 1'b1;
            end else begin
                cpu_write_pulse <= 1'b0;
            end
            
            // Read pulse generation
            if (write_reg_en && !write_error && (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2] == 6'h00) && slv_reg0[1]) begin
                read_pulse_counter <= 3'b100; // 4 clock pulse width
                cpu_read_pulse <= 1'b1;
            end else if (read_pulse_counter > 0) begin
                read_pulse_counter <= read_pulse_counter - 1'b1;
                cpu_read_pulse <= 1'b1;
            end else begin
                cpu_read_pulse <= 1'b0;
            end
        end
    end

    //==============================================================
    // 9. Status and Data Output Register Updates
    //==============================================================
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg1 <= 32'b0;
            slv_data_out_reg <= 128'b0;
        end else begin
            // Update status register with busy flag
            slv_reg1[0] <= smc_busy_sync;
            slv_reg1[31:1] <= 31'b0; // Clear unused bits
            
            // Capture output data when SMC is not busy (edge detection)
            if (!smc_busy_sync && smc_busy) begin // Falling edge of busy
                slv_data_out_reg <= smc_cpu_data_out_sync;
            end
        end
    end

    //==============================================================
    // 10. AXI Read Logic
    //==============================================================
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg read_reg_en;
    
    // Read state machine
    localparam [1:0] READ_IDLE = 2'b00;
    localparam [1:0] READ_DATA = 2'b01;
    
    reg [1:0] read_state;
    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            read_state <= READ_IDLE;
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rresp <= 2'b00;
            axi_araddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            read_reg_en <= 1'b0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    axi_arready <= 1'b0;
                    axi_rvalid <= 1'b0;
                    read_reg_en <= 1'b0;
                    
                    if (S_AXI_ARVALID) begin
                        axi_arready <= 1'b1;
                        axi_araddr <= S_AXI_ARADDR;
                        read_reg_en <= 1'b1;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    axi_arready <= 1'b0;
                    read_reg_en <= 1'b0;
                    axi_rvalid <= 1'b1;
                    axi_rresp <= 2'b00; // OKAY response
                    
                    if (S_AXI_RREADY) begin
                        axi_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end

    //==============================================================
    // 11. Read Data Multiplexer
    //==============================================================
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 32'b0;
        end else begin
            if (read_reg_en) begin
                case (axi_araddr[C_S_AXI_ADDR_WIDTH-1:2])
                    6'h00: axi_rdata <= slv_reg0;  // Control register
                    6'h01: axi_rdata <= slv_reg1;  // Status register
                    6'h02: axi_rdata <= slv_reg2;  // CPU address
                    6'h03: axi_rdata <= slv_reg3;  // CPU data in [31:0]
                    6'h04: axi_rdata <= slv_reg4;  // CPU data in [63:32]
                    6'h05: axi_rdata <= slv_reg5;  // CPU data in [95:64]
                    6'h06: axi_rdata <= slv_reg6;  // CPU data in [127:96]
                    6'h07: axi_rdata <= slv_data_out_reg[31:0];   // Data out [31:0]
                    6'h08: axi_rdata <= slv_data_out_reg[63:32];  // Data out [63:32]
                    6'h09: axi_rdata <= slv_data_out_reg[95:64];  // Data out [95:64]
                    6'h0A: axi_rdata <= slv_data_out_reg[127:96]; // Data out [127:96]
                    6'h0B: axi_rdata <= 32'b0;  // Key registers are write-only
                    6'h0C: axi_rdata <= 32'b0;  // Key registers are write-only
                    6'h0D: axi_rdata <= 32'b0;  // Key registers are write-only
                    6'h0E: axi_rdata <= 32'b0;  // Key registers are write-only
                    6'h0F: axi_rdata <= 32'b0;  // Nonce registers are write-only
                    6'h10: axi_rdata <= 32'b0;  // Nonce registers are write-only
                    6'h11: axi_rdata <= 32'b0;  // Nonce registers are write-only
                    default: axi_rdata <= 32'b0; // Return 0 for unmapped addresses
                endcase
            end
        end
    end

endmodule*/

//////////////////////////////////////////////////////////////////////////////////
// Register Map Documentation:
// 0x00: Control Register (R/W)
//       [0] - Write Enable (triggers write operation)
//       [1] - Read Enable (triggers read operation)
//       [31:2] - Reserved
//
// 0x04: Status Register (R/O)
//       [0] - Busy flag from SMC
//       [31:1] - Reserved
//
// 0x08: CPU Address Register (R/W)
//       [7:0] - Memory address for SMC
//       [31:8] - Reserved
//
// 0x0C-0x18: CPU Data Input Registers (R/W)
//       128-bit data input to SMC (little-endian)
//
// 0x1C-0x28: CPU Data Output Registers (R/O)
//       128-bit data output from SMC (little-endian)
//
// 0x2C-0x38: Key Registers (W/O)
//       128-bit encryption key (write-only for security)
//
// 0x3C-0x44: Nonce Registers (W/O)
//       96-bit nonce value (write-only for security)
/////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
module SMC_AXI_Top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8
)(
    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                          S_AXI_AWVALID,
    output wire                          S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] S_AXI_WSTRB,
    input  wire                          S_AXI_WVALID,
    output wire                          S_AXI_WREADY,
    output wire [1:0]                    S_AXI_BRESP,
    output wire                          S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                          S_AXI_ARVALID,
    output wire                          S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,
    output wire                          S_AXI_RVALID,
    input  wire                          S_AXI_RREADY
);


    //reset high dynamic power consumption
    /*
    //reset high dynamic power consumption
    reg rst_sync1, rst_sync2;
        always @(posedge S_AXI_ACLK) begin
            rst_sync1 <= S_AXI_ARESETN;
            rst_sync2 <= rst_sync1;
        end
        
        wire rst_n_sync = rst_sync2;
    */

    // AXI Protocol Internal Signals
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;
    
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // Write Transaction State Machine
    localparam [1:0] WRITE_IDLE   = 2'b00;
    localparam [1:0] WRITE_DATA   = 2'b01;
    localparam [1:0] WRITE_RESP   = 2'b10;
    
    reg [1:0] write_state;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg write_reg_en;
    reg write_error;
    
    // Memory-Mapped Slave Registers
    reg [31:0] slv_reg0;
    reg [31:0] slv_reg1;
    reg [31:0] slv_reg2;
    reg [31:0] slv_reg3, slv_reg4, slv_reg5, slv_reg6;
    reg [127:0] slv_data_out_reg;
    reg [31:0] slv_reg11, slv_reg12, slv_reg13, slv_reg14;
    reg [31:0] slv_reg15, slv_reg16, slv_reg17;
    
    reg [2:0] write_pulse_counter;
    reg [2:0] read_pulse_counter;
    reg cpu_write_pulse;
    reg cpu_read_pulse;
    
    integer i;

    // SMC Connection Wires
    wire         smc_busy;
    wire [127:0] smc_cpu_data_out;
    wire         smc_done;          // New done signal
    
    reg smc_busy_sync;
    reg [127:0] smc_cpu_data_out_sync;
    reg smc_done_sync;              // Synchronizer for done
    reg done_flag;                  // Sticky done flag
    
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (S_AXI_ARESETN == 1'b0) begin
            smc_busy_sync <= 1'b0;
            smc_cpu_data_out_sync <= 128'b0;
            smc_done_sync <= 1'b0;
        end else begin
            smc_busy_sync <= smc_busy;
            smc_cpu_data_out_sync <= smc_cpu_data_out;
            smc_done_sync <= smc_done;
        end
    end

    // SMC Instantiation
    secure_memory_controller u_smc (
        .clk(S_AXI_ACLK), 
        .rst_n(S_AXI_ARESETN),
        .key_in({slv_reg14, slv_reg13, slv_reg12, slv_reg11}),
        .nonce_in({slv_reg17, slv_reg16, slv_reg15}),
        .cpu_addr(slv_reg2[7:0]),
        .cpu_data_in({slv_reg6, slv_reg5, slv_reg4, slv_reg3}),
        .cpu_write_en(cpu_write_pulse),
        .cpu_read_en(cpu_read_pulse),
        .cpu_data_out(smc_cpu_data_out),
        .busy(smc_busy),
        .done(smc_done)
    );

    // AXI Write State Machine
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (S_AXI_ARESETN == 1'b0) begin
            write_state <= WRITE_IDLE;
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_bresp   <= 2'b00;
            axi_awaddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            write_reg_en <= 1'b0;
            write_error <= 1'b0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    axi_awready <= 1'b0;
                    axi_wready  <= 1'b0;
                    axi_bvalid  <= 1'b0;
                    write_reg_en <= 1'b0;
                    write_error <= 1'b0;
                    
                    if (S_AXI_AWVALID) begin
                        axi_awready <= 1'b1;
                        axi_awaddr <= S_AXI_AWADDR;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    axi_awready <= 1'b0;
                    
                    if (S_AXI_WVALID) begin
                        axi_wready <= 1'b1;
                        write_reg_en <= 1'b1;
                        case (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2])
                            6'h01: write_error <= 1'b1;
                            6'h07, 6'h08, 6'h09, 6'h0A: write_error <= 1'b1;
                            default: write_error <= 1'b0;
                        endcase
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    axi_wready <= 1'b0;
                    write_reg_en <= 1'b0;
                    axi_bvalid <= 1'b1;
                    axi_bresp <= write_error ? 2'b10 : 2'b00;
                    if (S_AXI_BREADY) begin
                        axi_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end

    // Register Writing Logic
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 32'b0; slv_reg2 <= 32'b0; slv_reg3 <= 32'b0; slv_reg4 <= 32'b0;
            slv_reg5 <= 32'b0; slv_reg6 <= 32'b0; slv_reg11 <= 32'b0; slv_reg12 <= 32'b0;
            slv_reg13 <= 32'b0; slv_reg14 <= 32'b0; slv_reg15 <= 32'b0; slv_reg16 <= 32'b0;
            slv_reg17 <= 32'b0;
        end else begin
            if (write_reg_en && !write_error) begin
                case (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2])
                    6'h00: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg0[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h02: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg2[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h03: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg3[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h04: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg4[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h05: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg5[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h06: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg6[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0B: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg11[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0C: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg12[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0D: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg13[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0E: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg14[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h0F: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg15[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h10: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg16[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    6'h11: for (i=0; i<4; i=i+1) if (S_AXI_WSTRB[i]) slv_reg17[i*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
                    default: ;
                endcase
            end
        end
    end

    // Control Signal Pulse Generation
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (S_AXI_ARESETN == 1'b0) begin
            write_pulse_counter <= 3'b0;
            read_pulse_counter <= 3'b0;
            cpu_write_pulse <= 1'b0;
            cpu_read_pulse <= 1'b0;
        end else begin
            if (write_reg_en && !write_error && (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2] == 6'h00) && S_AXI_WDATA[0]) begin
                write_pulse_counter <= 3'b100;
                cpu_write_pulse <= 1'b1;
            end else if (write_pulse_counter > 0) begin
                write_pulse_counter <= write_pulse_counter - 1'b1;
                cpu_write_pulse <= 1'b1;
            end else begin
                cpu_write_pulse <= 1'b0;
            end
            
            if (write_reg_en && !write_error && (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2] == 6'h00) && S_AXI_WDATA[1]) begin
                read_pulse_counter <= 3'b100;
                cpu_read_pulse <= 1'b1;
            end else if (read_pulse_counter > 0) begin
                read_pulse_counter <= read_pulse_counter - 1'b1;
                cpu_read_pulse <= 1'b1;
            end else begin
                cpu_read_pulse <= 1'b0;
            end
        end
    end

    // Status and Data Output Register Updates
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg1 <= 32'b0;
            slv_data_out_reg <= 128'b0;
            done_flag <= 1'b0;
        end else begin
            slv_reg1[0] <= smc_busy_sync;
            slv_reg1[1] <= done_flag;
            slv_reg1[31:2] <= 30'b0;
            
            if (cpu_write_pulse || cpu_read_pulse) begin
                done_flag <= 1'b0;      // Clear done_flag on new operation
            end else if (smc_done_sync) begin
                done_flag <= 1'b1;      // Set done_flag when done is asserted
                slv_data_out_reg <= smc_cpu_data_out_sync; // Capture data on done
            end
        end
    end

    // AXI Read Logic
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg read_reg_en;
    localparam [1:0] READ_IDLE = 2'b00;
    localparam [1:0] READ_DATA = 2'b01;
    reg [1:0] read_state;
    
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (S_AXI_ARESETN == 1'b0) begin
            read_state <= READ_IDLE;
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            axi_rresp <= 2'b00;
            axi_araddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            read_reg_en <= 1'b0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    axi_arready <= 1'b0;
                    axi_rvalid <= 1'b0;
                    read_reg_en <= 1'b0;
                    if (S_AXI_ARVALID) begin
                        axi_arready <= 1'b1;
                        axi_araddr <= S_AXI_ARADDR;
                        read_reg_en <= 1'b1;
                        read_state <= READ_DATA;
                    end
                end
                READ_DATA: begin
                    axi_arready <= 1'b0;
                    read_reg_en <= 1'b0;
                    axi_rvalid <= 1'b1;
                    axi_rresp <= 2'b00;
                    if (S_AXI_RREADY) begin
                        axi_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                default: read_state <= READ_IDLE;
            endcase
        end
    end

    // Read Data Multiplexer
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 32'b0;
        end else begin
            if (read_reg_en) begin
                case (axi_araddr[C_S_AXI_ADDR_WIDTH-1:2])
                    6'h00: axi_rdata <= slv_reg0;
                    6'h01: axi_rdata <= slv_reg1;
                    6'h02: axi_rdata <= slv_reg2;
                    6'h03: axi_rdata <= slv_reg3;
                    6'h04: axi_rdata <= slv_reg4;
                    6'h05: axi_rdata <= slv_reg5;
                    6'h06: axi_rdata <= slv_reg6;
                    6'h07: axi_rdata <= slv_data_out_reg[31:0];
                    6'h08: axi_rdata <= slv_data_out_reg[63:32];
                    6'h09: axi_rdata <= slv_data_out_reg[95:64];
                    6'h0A: axi_rdata <= slv_data_out_reg[127:96];
                    6'h0B: axi_rdata <= 32'b0;
                    6'h0C: axi_rdata <= 32'b0;
                    6'h0D: axi_rdata <= 32'b0;
                    6'h0E: axi_rdata <= 32'b0;
                    6'h0F: axi_rdata <= 32'b0;
                    6'h10: axi_rdata <= 32'b0;
                    6'h11: axi_rdata <= 32'b0;
                    default: axi_rdata <= 32'b0;
                endcase
            end
        end
    end

endmodule