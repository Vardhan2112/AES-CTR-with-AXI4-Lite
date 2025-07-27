`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2025 12:53:57
// Design Name: 
// Module Name: decrypt
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
// Module: aes_128_decrypt
// Description: Top-level iterative AES-128 decryption core.
//              Mirrors the design of the encryption core.
//////////////////////////////////////////////////////////////////////////////////
module aes_128_decrypt (
    input                 clk,
    input                 rst_n,
    input                 start_decrypt,
    input      [127:0]    ciphertext_in,
    input      [127:0]    key_in,
    output reg [127:0]    plaintext_out,
    output reg            decrypt_done
);
    //==============================================================
    // 1. STATE MACHINE DEFINITION
    //==============================================================
    localparam S_IDLE            = 3'b000;
    localparam S_KEY_EXPANSION   = 3'b001;
    localparam S_INIT_ADD_KEY    = 3'b010;
    localparam S_DECRYPT_ROUNDS  = 3'b011;
    localparam S_FINAL_ROUND     = 3'b100;
    localparam S_DONE            = 3'b101;
    
    reg [2:0] state;
    reg [3:0] round_counter; // Counts DOWN from 10 to 0
    
    //==============================================================
    // 2. INTERNAL REGISTERS AND WIRES
    //==============================================================
    reg [127:0] state_reg;
    wire        key_expansion_ready;
    wire [127:0]current_round_key;
    reg         start_key_expansion;
    
    // Separate wires for round outputs and a mux to select
    wire [127:0] std_round_out;      // InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns
    wire [127:0] final_round_out;    // InvShiftRows -> InvSubBytes -> AddRoundKey (no InvMixColumns)
    wire [127:0] round_logic_out;
    wire [127:0] after_add_key;
    
    // Mux to select between standard and final round
    assign round_logic_out = (state == S_FINAL_ROUND) ? final_round_out : std_round_out;
    
    //==============================================================
    // 3. SUB-MODULE INSTANTIATIONS
    //==============================================================
    key_expansion_128 u_key_exp (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start_key_expansion), 
        .key_in(key_in),
        .round(round_counter), 
        .round_key_out(current_round_key), 
        .ready(key_expansion_ready)
    );
    
    // Decryption Round Modules
    // Standard decrypt round: InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns
    decrypt_round u_std_round (
        .state_in(state_reg), 
        .round_key(current_round_key),
        .state_out(std_round_out)
    );
    
    // Final decrypt round: InvShiftRows -> InvSubBytes -> AddRoundKey (no InvMixColumns)
    decrypt_final_round u_final_round (
        .state_in(state_reg), 
        .round_key(current_round_key),
        .state_out(final_round_out)
    );
    
    // Initial AddRoundKey (for the very first operation with round 10 key)
    addRoundKey u_add_key (
        .in(ciphertext_in),
        .key(current_round_key),
        .out(after_add_key)
    );
    
    //==============================================================
    // 4. FSM AND SEQUENTIAL LOGIC
    //==============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            round_counter <= 4'd10;
            start_key_expansion <= 1'b0;
            decrypt_done <= 1'b0;
            plaintext_out <= 128'b0;
            state_reg <= 128'b0;
        end else begin
            start_key_expansion <= 1'b0;
            decrypt_done <= 1'b0;
            
            case (state)
                S_IDLE: begin
                    if (start_decrypt) begin
                        start_key_expansion <= 1'b1;
                        round_counter <= 4'd10;     // Start with round 10 key
                        state <= S_KEY_EXPANSION;
                    end
                end
                
                S_KEY_EXPANSION: begin
                    if (key_expansion_ready) begin
                        state <= S_INIT_ADD_KEY;
                    end
                end
                
                S_INIT_ADD_KEY: begin
                    // Apply initial AddRoundKey with round 10 key
                    state_reg <= after_add_key;
                    round_counter <= 4'd9;          // Prepare for round 9
                    state <= S_DECRYPT_ROUNDS;
                end
                
                S_DECRYPT_ROUNDS: begin
                    // Apply standard decrypt round (InvShiftRows -> InvSubBytes -> AddRoundKey -> InvMixColumns)
                    state_reg <= std_round_out;
                    if (round_counter > 1) begin
                        round_counter <= round_counter - 1;  // Move to next round (8,7,6,5,4,3,2,1)
                        // Stay in S_DECRYPT_ROUNDS
                    end else begin  // round_counter == 1, just finished round 1
                        round_counter <= 4'd0;      // Prepare for final round (round 0)
                        state <= S_FINAL_ROUND;
                    end
                end
                
                S_FINAL_ROUND: begin
                    // Apply final decrypt round (InvShiftRows -> InvSubBytes -> AddRoundKey, no InvMixColumns)
                    state_reg <= final_round_out;
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    plaintext_out <= state_reg;    // The final result is in state_reg
                    decrypt_done <= 1'b1;
                    round_counter <= 4'd10;        // Reset for next operation
                    state <= S_IDLE;
                end
                
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
    
endmodule
