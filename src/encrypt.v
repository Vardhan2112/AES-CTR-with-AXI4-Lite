`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: aes_128_encrypt (Corrected)
// Description: Final, robust top-level iterative AES-128 encryption core.
//              Uses a single clocked FSM block to prevent timing/logic errors.
//////////////////////////////////////////////////////////////////////////////////
module aes_128_encrypt (
    input                 clk,
    input                 rst_n,
    input                 start_encrypt,
    input      [127:0]    plaintext_in,
    input      [127:0]    key_in,
    output reg [127:0]    ciphertext_out,
    output reg            encrypt_done
);
    // FSM State Definition
    localparam S_IDLE            = 3'b000;
    localparam S_KEY_EXPANSION   = 3'b001;
    localparam S_INIT_ADD_KEY    = 3'b010;
    localparam S_ENCRYPT_ROUNDS  = 3'b011;
    localparam S_FINAL_ROUND     = 3'b100;
    localparam S_DONE            = 3'b101;
    
    reg [2:0] state;
    reg [3:0] round_counter; // Counts from 0 to 10
    
    // Internal Registers and Wires
    reg [127:0] state_reg;
    wire        key_expansion_ready;
    wire [127:0]current_round_key;
    reg         start_key_expansion;
    
    // Separate wires for round outputs and a mux to select
    wire [127:0] std_round_out;
    wire [127:0] final_round_out;
    wire [127:0] round_logic_out = (state == S_FINAL_ROUND) ? final_round_out : std_round_out;
    wire [127:0] after_add_key;
    
    // Sub-Module Instantiations
    key_expansion_128 u_key_exp (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start_key_expansion), 
        .key_in(key_in),
        .round(round_counter), 
        .round_key_out(current_round_key), 
        .ready(key_expansion_ready)
    );
    
    encrypt_round u_std_round (
        .state_in(state_reg), 
        .state_out(std_round_out)
    );
    
    encrypt_final_round u_final_round (
        .state_in(state_reg), 
        .state_out(final_round_out)
    );
    
    addRoundKey u_add_key (
        .in( (state == S_INIT_ADD_KEY) ? plaintext_in : round_logic_out ),
        .key(current_round_key),
        .out(after_add_key)
    );
    
    // FSM and Sequential Logic (using a single, safer always block)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            round_counter <= 4'b0;
            start_key_expansion <= 1'b0;
            encrypt_done <= 1'b0;
            ciphertext_out <= 128'b0;
            state_reg <= 128'b0;
        end else begin
            // Default assignments
            start_key_expansion <= 1'b0;
            encrypt_done <= 1'b0;
            
            case (state)
                S_IDLE: begin
                    if (start_encrypt) begin
                        start_key_expansion <= 1'b1; // Pulse to start key gen
                        round_counter <= 4'b0;       // Start with round 0 (initial key)
                        state <= S_KEY_EXPANSION;
                    end
                end
                
                S_KEY_EXPANSION: begin
                    if (key_expansion_ready) begin
                        state <= S_INIT_ADD_KEY;
                    end
                end
                
                S_INIT_ADD_KEY: begin
                    state_reg <= after_add_key;    // Apply initial AddRoundKey with round 0 key
                    round_counter <= 4'd1;         // Prepare for round 1
                    state <= S_ENCRYPT_ROUNDS;
                end
                
                S_ENCRYPT_ROUNDS: begin
                    state_reg <= after_add_key;    // Apply standard round + AddRoundKey
                    if (round_counter < 9) begin
                        round_counter <= round_counter + 1;  // Move to next round (2,3,4,5,6,7,8,9)
                        // Stay in S_ENCRYPT_ROUNDS
                    end else begin  // round_counter == 9, just finished round 9
                        round_counter <= 4'd10;     // Prepare for final round (round 10)
                        state <= S_FINAL_ROUND;
                    end
                end
                
                S_FINAL_ROUND: begin
                    // Apply final round (no MixColumns) + AddRoundKey with round 10 key
                    state_reg <= after_add_key;
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    ciphertext_out <= state_reg;   // The result is now in state_reg
                    encrypt_done <= 1'b1;
                    round_counter <= 4'b0;         // Reset for next operation
                    state <= S_IDLE;
                end
                
                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
    
endmodule