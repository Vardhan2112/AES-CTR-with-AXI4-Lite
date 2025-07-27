`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2025 15:23:00
// Design Name: 
// Module Name: aes_128_ctr_engine
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
// Module: aes_128_ctr_engine (Final, Robust Version)
// Description: Implements AES-CTR mode for a single block.
//              It latches its own inputs on a 'start' pulse to ensure
//              data stability throughout its multi-cycle operation.
//////////////////////////////////////////////////////////////////////////////////

module aes_128_ctr_engine (
    input               clk,
    input               rst_n,
    input               start,          // Pulse to begin a single CTR operation
    input      [127:0]  key_in,
    input      [127:0]  iv_counter_in,
    input      [127:0]  data_in,        // Generic name: can be plaintext or ciphertext
    output reg [127:0]  data_out,       // Generic name: can be ciphertext or plaintext
    output reg          done
);

    // FSM States
    localparam S_IDLE         = 2'b00;
    localparam S_ENCRYPT_IV   = 2'b01;
    localparam S_XOR_DATA     = 2'b10;
    
    reg [1:0] state;

    // Internal registers to latch inputs and intermediate results
    reg [127:0] key_reg;
    reg [127:0] iv_counter_reg;
    reg [127:0] data_in_reg;
    reg [127:0] keystream_reg; // To latch the output of the AES core

    // Wires for AES core communication
    wire [127:0] aes_core_output;
    wire         encrypt_done_wire;
    
    // Instantiate the encryption core. It uses our stable internal registers.
    aes_128_encrypt u_encrypt (
        .clk(clk),
        .rst_n(rst_n),
        .start_encrypt( (state == S_IDLE) && start ), // Start AES core when we get the main start pulse
        .plaintext_in(iv_counter_reg), // Use the registered IV to be encrypted
        .key_in(key_reg),              // Use the registered Key
        .ciphertext_out(aes_core_output),
        .encrypt_done(encrypt_done_wire)
    );

    // FSM and Sequential Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            done <= 1'b0;
            data_out <= 128'b0;
            // Reset internal registers
            key_reg <= 128'b0;
            iv_counter_reg <= 128'b0;
            data_in_reg <= 128'b0;
            keystream_reg <= 128'b0;
        end else begin
            done <= 1'b0; // Default done to low each cycle
            
            case (state)
                S_IDLE: begin
                    if (start) begin
                        // On start, LATCH ALL INPUTS into our internal registers
                        key_reg        <= key_in;
                        iv_counter_reg <= iv_counter_in;
                        data_in_reg    <= data_in;
                        state          <= S_ENCRYPT_IV;
                    end
                end
                
                S_ENCRYPT_IV: begin
                    // Wait for the AES core to finish generating the keystream
                    if (encrypt_done_wire) begin
                        // LATCH the keystream when it's valid
                        keystream_reg <= aes_core_output;
                        state <= S_XOR_DATA;
                    end
                end
                
                S_XOR_DATA: begin
                    // XOR the LATCHED input data with the LATCHED keystream
                    data_out <= data_in_reg ^ keystream_reg;
                    done <= 1'b1; // Signal completion
                    state <= S_IDLE;
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
