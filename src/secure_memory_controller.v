`timescale 1ns / 1ps

module secure_memory_controller (
    // CPU-Facing Interface
    input               clk,
    input               rst_n,
    input      [127:0]  key_in,
    input      [95:0]   nonce_in,
    input      [7:0]    cpu_addr,
    input      [127:0]  cpu_data_in,
    input               cpu_write_en,
    input               cpu_read_en,
    output reg [127:0]  cpu_data_out,
    output              busy,
    output reg          done        // New done signal
);

    // FSM State Definition
    localparam S_IDLE            = 4'h0;
    localparam S_LATCH_CPU_DATA  = 4'h1;
    localparam S_CTR_START_ENC   = 4'h2;
    localparam S_CTR_WAIT_ENC    = 4'h3;
    localparam S_BRAM_WRITE      = 4'h4;
    localparam S_BRAM_READ_FETCH = 4'h5;
    localparam S_BRAM_WAIT_READ  = 4'h6;
    localparam S_CTR_START_DEC   = 4'h7;
    localparam S_CTR_WAIT_DEC    = 4'h8;

    reg [3:0] state;

    // Internal Registers and Wires
    reg [7:0]   latched_addr;
    reg [127:0] latched_cpu_data_in;
    reg [127:0] latched_bram_data_out;

    reg         ctr_start;
    wire        ctr_done;
    wire [127:0]ctr_data_out_from_engine;

    reg         bram_we;
    wire [127:0]bram_data_out;
    
    wire [127:0] iv_counter = {nonce_in, 24'b0, latched_addr};
    assign busy = (state != S_IDLE);

    // Sub-module Instantiations
    aes_128_ctr_engine u_ctr_engine (
        .clk(clk),
        .rst_n(rst_n),
        .start(ctr_start),
        .key_in(key_in),
        .iv_counter_in(iv_counter),
        .data_in(latched_cpu_data_in),
        .data_out(ctr_data_out_from_engine),
        .done(ctr_done)
    );
    
    bram_memory u_bram (
        .clk(clk),
        .we(bram_we),
        .addr(latched_addr),
        .data_in(ctr_data_out_from_engine),
        .data_out(bram_data_out)
    );

    // FSM and Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            ctr_start <= 1'b0;
            bram_we <= 1'b0;
            cpu_data_out <= 128'b0;
            latched_addr <= 8'b0;
            latched_cpu_data_in <= 128'b0;
            latched_bram_data_out <= 128'b0;
            done <= 1'b0;           // Reset done
        end else begin
            // Default assignments
            ctr_start <= 1'b0;
            bram_we <= 1'b0;
            done <= 1'b0;           // Default done to 0

            case (state)
                S_IDLE: begin
                    if (cpu_write_en) begin
                        latched_addr <= cpu_addr;
                        state <= S_LATCH_CPU_DATA;
                    end else if (cpu_read_en) begin
                        latched_addr <= cpu_addr;
                        state <= S_BRAM_READ_FETCH;
                    end
                end
                
                S_LATCH_CPU_DATA: begin
                    latched_cpu_data_in <= cpu_data_in;
                    state <= S_CTR_START_ENC;
                end

                S_CTR_START_ENC: begin
                    ctr_start <= 1'b1;
                    state <= S_CTR_WAIT_ENC;
                end
                
                S_CTR_WAIT_ENC: begin
                    if (ctr_done) begin
                        state <= S_BRAM_WRITE;
                    end
                end

                S_BRAM_WRITE: begin
                    bram_we <= 1'b1;
                    state <= S_IDLE;
                    done <= 1'b1;       // Assert done when write completes
                end

                S_BRAM_READ_FETCH: begin
                    state <= S_BRAM_WAIT_READ;
                end

                S_BRAM_WAIT_READ: begin
                    latched_cpu_data_in <= bram_data_out;
                    state <= S_CTR_START_DEC;
                end

                S_CTR_START_DEC: begin
                    ctr_start <= 1'b1;
                    state <= S_CTR_WAIT_DEC;
                end

                S_CTR_WAIT_DEC: begin
                    if (ctr_done) begin
                        cpu_data_out <= ctr_data_out_from_engine;
                        state <= S_IDLE;
                        done <= 1'b1;   // Assert done when read completes
                    end
                end
            endcase
        end
    end

endmodule

/*`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2025 11:43:26
// Design Name: 
// Module Name: secure_memory_controller
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
// Module: secure_memory_controller (Final, Corrected Version)
// Description: The top-level controller for the AES-based memory system.
//              This version includes a dedicated latch state to prevent
//              data path timing issues.
//////////////////////////////////////////////////////////////////////////////////

module secure_memory_controller (
    // CPU-Facing Interface
    input               clk,
    input               rst_n,
    input      [127:0]  key_in,
    input      [95:0]   nonce_in,
    input      [7:0]    cpu_addr,
    input      [127:0]  cpu_data_in,
    input               cpu_write_en,
    input               cpu_read_en,
    output reg [127:0]  cpu_data_out,
    output              busy
);

    //==============================================================
    // 1. FSM State Definition (with one new state)
    //==============================================================
    localparam S_IDLE            = 4'h0;
    localparam S_LATCH_CPU_DATA  = 4'h1; // *** NEW STATE TO FIX TIMING ***
    localparam S_CTR_START_ENC   = 4'h2;
    localparam S_CTR_WAIT_ENC    = 4'h3;
    localparam S_BRAM_WRITE      = 4'h4;
    localparam S_BRAM_READ_FETCH = 4'h5;
    localparam S_BRAM_WAIT_READ  = 4'h6;
    localparam S_CTR_START_DEC   = 4'h7;
    localparam S_CTR_WAIT_DEC    = 4'h8;

    reg [3:0] state;

    //==============================================================
    // 2. Internal Registers and Wires
    //==============================================================
    // Registers to latch inputs
    reg [7:0]   latched_addr;
    reg [127:0] latched_cpu_data_in; // This is the critical latch
    reg [127:0] latched_bram_data_out;

    // Control signals for sub-modules
    reg         ctr_start;
    wire        ctr_done;
    wire [127:0]ctr_data_out_from_engine; // Renamed for clarity

    reg         bram_we;
    wire [127:0]bram_data_out;
    
    wire [127:0] iv_counter = {nonce_in, 24'b0, latched_addr};
    assign busy = (state != S_IDLE);

    //==============================================================
    // 3. SUB-MODULE INSTANTIATIONS
    //==============================================================
    
    // THE FIX: The CTR engine's data input is now always a stable, latched value.
    aes_128_ctr_engine u_ctr_engine (
        .clk(clk),
        .rst_n(rst_n),
        .start(ctr_start),
        .key_in(key_in),
        .iv_counter_in(iv_counter),
        .data_in(latched_cpu_data_in), // Always use our internal register
        .data_out(ctr_data_out_from_engine),
        .done(ctr_done)
    );
    
    bram_memory u_bram (
        .clk(clk),
        .we(bram_we),
        .addr(latched_addr),
        .data_in(ctr_data_out_from_engine), // BRAM still gets data from engine
        .data_out(bram_data_out)
    );

    //==============================================================
    // 4. FSM AND SEQUENTIAL LOGIC
    //==============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            ctr_start <= 1'b0;
            bram_we <= 1'b0;
            cpu_data_out <= 128'b0;
            latched_addr <= 8'b0;
            latched_cpu_data_in <= 128'b0;
            latched_bram_data_out <= 128'b0;
        end else begin
            // Default assignments
            ctr_start <= 1'b0;
            bram_we <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (cpu_write_en) begin
                        // Latch the address now
                        latched_addr <= cpu_addr;
                        // Move to a dedicated state to latch the data
                        state <= S_LATCH_CPU_DATA;
                    end else if (cpu_read_en) begin
                        latched_addr <= cpu_addr;
                        state <= S_BRAM_READ_FETCH;
                    end
                end
                
                // *** NEW STATE LOGIC ***
                S_LATCH_CPU_DATA: begin
                    // In this state, we securely latch the plaintext from the CPU.
                    latched_cpu_data_in <= cpu_data_in;
                    // Now that the data is stable inside our SMC, we can start the engine.
                    state <= S_CTR_START_ENC;
                end

                S_CTR_START_ENC: begin
                    ctr_start <= 1'b1; // Pulse start for one cycle
                    state <= S_CTR_WAIT_ENC;
                end
                
                S_CTR_WAIT_ENC: begin
                    if (ctr_done) begin
                        state <= S_BRAM_WRITE;
                    end
                end

                S_BRAM_WRITE: begin
                    bram_we <= 1'b1; // Write the ciphertext to BRAM
                    state <= S_IDLE;
                end

                S_BRAM_READ_FETCH: begin
                    // The address is set, just wait for BRAM's read latency.
                    state <= S_BRAM_WAIT_READ;
                end

                S_BRAM_WAIT_READ: begin
                    // Latch the ciphertext from BRAM into our internal register
                    latched_cpu_data_in <= bram_data_out;
                    state <= S_CTR_START_DEC;
                end

                S_CTR_START_DEC: begin
                    ctr_start <= 1'b1;
                    state <= S_CTR_WAIT_DEC;
                end

                S_CTR_WAIT_DEC: begin
                    if (ctr_done) begin
                        // The engine's output is now our plaintext.
                        cpu_data_out <= ctr_data_out_from_engine;
                        state <= S_IDLE;
                    end
                end

            endcase
        end
    end

endmodule
/*`timescale 1ns / 1ps

module secure_memory_controller (
    input clk, rst_n,
    input [127:0] key_in,
    input [95:0]  nonce_in,
    input [7:0]   cpu_addr,
    input [127:0] cpu_data_in,
    input         cpu_write_en,
    input         cpu_read_en,
    output reg [127:0] cpu_data_out,
    output        busy
);

    // FSM States
    localparam S_IDLE        = 3'b000;
    localparam S_READ_FETCH  = 3'b001; // For reads: get data from BRAM first
    localparam S_CTR_SETUP   = 3'b010; // Setup inputs for the CTR engine
    localparam S_CTR_START   = 3'b011; // Pulse start to the CTR engine
    localparam S_CTR_WAIT    = 3'b100; // Wait for CTR engine to finish
    localparam S_WRITE_BRAM  = 3'b101; // For writes: store the result

    reg [2:0] state;

    // Internal Registers
    reg [7:0]   latched_addr;
    reg [127:0] data_for_ctr; // Holds either plaintext from CPU or ciphertext from BRAM
    reg         is_write_op;  // Flag to remember the operation type

    // Wires and Control Signals
    reg         ctr_start;
    wire        ctr_done;
    wire [127:0]ctr_result;
    reg         bram_we;
    wire [127:0]bram_data_out;
    
    wire [127:0] iv_counter = {nonce_in, 24'b0, latched_addr};
    assign busy = (state != S_IDLE);

    // Sub-Module Instantiations
    aes_128_ctr_engine u_ctr_engine (
        .clk(clk), .rst_n(rst_n), .start(ctr_start),
        .key_in(key_in), .iv_counter_in(iv_counter),
        .data_in(data_for_ctr),
        .data_out(ctr_result),
        .done(ctr_done)
    );
    
    bram_memory u_bram (
        .clk(clk), .we(bram_we), .addr(latched_addr),
        .data_in(ctr_result),
        .data_out(bram_data_out)
    );

    // FSM and Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            ctr_start <= 1'b0;
            bram_we <= 1'b0;
            cpu_data_out <= 128'b0;
        end else begin
            ctr_start <= 1'b0; // Default pulse to low
            bram_we <= 1'b0;   // Default to no write

            case (state)
                S_IDLE: begin
                    if (cpu_write_en) begin
                        latched_addr <= cpu_addr;
                        data_for_ctr <= cpu_data_in; // Latch plaintext
                        is_write_op <= 1'b1;
                        state <= S_CTR_SETUP;
                    end else if (cpu_read_en) begin
                        latched_addr <= cpu_addr;
                        is_write_op <= 1'b0;
                        state <= S_READ_FETCH;
                    end
                end

                S_READ_FETCH: begin
                    // One-cycle delay for BRAM read
                    data_for_ctr <= bram_data_out;
                    state <= S_CTR_SETUP;
                end

                S_CTR_SETUP: begin
                    // Data is now stable, ready to start the engine
                    state <= S_CTR_START;
                end

                S_CTR_START: begin
                    ctr_start <= 1'b1; // Pulse start for one cycle
                    state <= S_CTR_WAIT;
                end

                S_CTR_WAIT: begin
                    if (ctr_done) begin
                        if (is_write_op) begin
                            state <= S_WRITE_BRAM;
                        end else begin
                            cpu_data_out <= ctr_result; // Provide decrypted data to CPU
                            state <= S_IDLE;
                        end
                    end
                end

                S_WRITE_BRAM: begin
                    bram_we <= 1'b1; // Write the encrypted result to BRAM
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule*/