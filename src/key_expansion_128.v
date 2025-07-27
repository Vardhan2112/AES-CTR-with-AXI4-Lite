
module key_expansion_128 (
    input clk,
    input rst_n,                    // Active-low asynchronous reset
    input start,                    // Pulse to start key generation
    input [127:0] key_in,          // The 128-bit cipher key
    input [3:0] round,             // Selects which round key to output (0-10)
    output reg [127:0] round_key_out, // The selected 128-bit round key
    output reg ready               // High when the key schedule is valid
);
    // Internal memory for the 44 words of the key schedule
    reg [31:0] w[0:43];
    
    // State machine definition
    localparam S_IDLE = 2'b00;
    localparam S_GENERATE = 2'b01;
    localparam S_READY = 2'b10;
    
    reg [1:0] state, next_state;
    reg [5:0] i;                   // Counter for the word being generated, from 4 to 43
    
    // NEW: Add a flag to track if key expansion has been completed at least once
    reg key_schedule_valid;
    
    //----------------------------------------------------- 
    // Combinational Logic for G-function
    //----------------------------------------------------- 
    wire [31:0] w_prev = (i > 0) ? w[i-1] : 32'h0;
    wire [31:0] temp_rot, temp_sub, rcon_val;
    wire [3:0] rcon_round;
    wire is_key_word;
    
    assign is_key_word = (i[1:0] == 2'b00); // i % 4 == 0
    assign rcon_round = i[5:2];             // i / 4
    
    // G-function components (only used when i%4==0)
    RotWord u_rot (
        .word_in(w_prev), 
        .word_out(temp_rot)
    );
    
    SubWord u_sub (
        .word_in(temp_rot), 
        .word_out(temp_sub)
    );
    
    Rcon u_rcon (
        .round_num(rcon_round), 
        .rcon_val(rcon_val)
    );
    
    // Calculate the transformation for current word
    wire [31:0] temp_word;
    assign temp_word = is_key_word ? (temp_sub ^ rcon_val) : w_prev;
    
    //----------------------------------------------------- 
    // FSM and Sequential Logic
    //----------------------------------------------------- 
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            key_schedule_valid <= 1'b0;
        end else begin
            state <= next_state;
            
            // Set key_schedule_valid when we complete generation
            if (state == S_GENERATE && i >= 44)
                key_schedule_valid <= 1'b1;
            else if (state == S_IDLE && start)
                key_schedule_valid <= 1'b0;  // Clear when starting new key expansion
        end
    end
    
    // Counter and word generation
    integer j;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i <= 6'd4;
            // Clear all words
            for (j = 0; j < 44; j = j + 1)
                w[j] <= 32'h0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        // Load initial key
                        w[0] <= key_in[127:96];
                        w[1] <= key_in[95:64];
                        w[2] <= key_in[63:32];
                        w[3] <= key_in[31:0];
                        i <= 6'd4;
                    end
                end
                
                S_GENERATE: begin
                    if (i < 44) begin
                        // Generate next word: w[i] = w[i-4] XOR temp_word
                        w[i] <= w[i-4] ^ temp_word;
                        i <= i + 1;
                    end
                end
                
                S_READY: begin
                    // Stay in ready state - don't restart unless explicitly needed
                    // Remove automatic restart on start pulse to avoid glitches
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        ready = 1'b0;
        
        case (state)
            S_IDLE: begin
                if (start)
                    next_state = S_GENERATE;
            end
            
            S_GENERATE: begin
                if (i >= 44)
                    next_state = S_READY;
            end
            
            S_READY: begin
                ready = 1'b1;
                // Stay in ready state - don't transition back to IDLE
            end
            
            default: next_state = S_IDLE;
        endcase
    end
    
    // FIXED: Output round key selection with better logic
    always @(*) begin
        if (key_schedule_valid && round <= 10) begin
            // Assemble the 128-bit round key from 4 consecutive 32-bit words
            round_key_out = {w[round*4], w[round*4+1], w[round*4+2], w[round*4+3]};
        end else if (round == 0) begin
            // For round 0, always output the original key even if expansion isn't complete
            round_key_out = {w[0], w[1], w[2], w[3]};
        end else begin
            round_key_out = 128'h0;
        end
    end
endmodule

/*
module key_expansion_128 (
    input clk,
    input rst_n,                    // Active-low asynchronous reset
    input start,                    // Pulse to start key generation
    input [127:0] key_in,          // The 128-bit cipher key
    input [3:0] round,             // Selects which round key to output (0-10)
    output reg [127:0] round_key_out, // The selected 128-bit round key
    output reg ready               // High when the key schedule is valid
);
    // Internal memory for the 44 words of the key schedule
    reg [31:0] w[0:43];
    
    // State machine definition
    localparam S_IDLE = 2'b00;
    localparam S_GENERATE = 2'b01;
    localparam S_READY = 2'b10;
    
    reg [1:0] state, next_state;
    reg [5:0] i;                   // Counter for the word being generated, from 4 to 43
    
    // NEW: Add a flag to track if key expansion has been completed at least once
    reg key_schedule_valid;
    
    // NEW: Register to track the current key for change detection
    reg [127:0] current_key;
    
    //----------------------------------------------------- 
    // Combinational Logic for G-function
    //----------------------------------------------------- 
    wire [31:0] w_prev = (i > 0) ? w[i-1] : 32'h0;
    wire [31:0] temp_rot, temp_sub, rcon_val;
    wire [3:0] rcon_round;
    wire is_key_word;
    
    assign is_key_word = (i[1:0] == 2'b00); // i % 4 == 0
    assign rcon_round = i[5:2];             // i / 4
    
    // G-function components (only used when i%4==0)
    RotWord u_rot (
        .word_in(w_prev), 
        .word_out(temp_rot)
    );
    
    SubWord u_sub (
        .word_in(temp_rot), 
        .word_out(temp_sub)
    );
    
    Rcon u_rcon (
        .round_num(rcon_round), 
        .rcon_val(rcon_val)
    );
    
    // Calculate the transformation for current word
    wire [31:0] temp_word;
    assign temp_word = is_key_word ? (temp_sub ^ rcon_val) : w_prev;
    
    //----------------------------------------------------- 
    // FSM and Sequential Logic
    //----------------------------------------------------- 
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            key_schedule_valid <= 1'b0;
            current_key <= 128'h0;
        end else begin
            state <= next_state;
            
            // Set key_schedule_valid when we complete generation
            if (state == S_GENERATE && i >= 44) begin
                key_schedule_valid <= 1'b1;
                current_key <= key_in;  // Store the key that was expanded
            end else if (state == S_IDLE && start) begin
                key_schedule_valid <= 1'b0;  // Clear when starting new key expansion
            end else if (key_in != current_key) begin
                // Key changed without start pulse - invalidate current schedule
                key_schedule_valid <= 1'b0;
            end
        end
    end
    
    // Counter and word generation
    integer j;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i <= 6'd4;
            // Clear all words
            for (j = 0; j < 44; j = j + 1)
                w[j] <= 32'h0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        // Load initial key
                        w[0] <= key_in[127:96];
                        w[1] <= key_in[95:64];
                        w[2] <= key_in[63:32];
                        w[3] <= key_in[31:0];
                        i <= 6'd4;
                    end
                end
                
                S_GENERATE: begin
                    if (i < 44) begin
                        // Generate next word: w[i] = w[i-4] XOR temp_word
                        w[i] <= w[i-4] ^ temp_word;
                        i <= i + 1;
                    end
                end
                
                S_READY: begin
                    // Stay in ready state - don't restart unless explicitly needed
                    // Remove automatic restart on start pulse to avoid glitches
                end
            endcase
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        ready = 1'b0;
        
        case (state)
            S_IDLE: begin
                if (start)
                    next_state = S_GENERATE;
            end
            
            S_GENERATE: begin
                if (i >= 44)
                    next_state = S_READY;
            end
            
            S_READY: begin
                ready = 1'b1;
                // Stay in ready state - don't transition back to IDLE
            end
            
            default: next_state = S_IDLE;
        endcase
    end
    
    // FIXED: Output round key selection with better logic
    always @(*) begin
        if (key_schedule_valid && (key_in == current_key) && round <= 10) begin
            // Assemble the 128-bit round key from 4 consecutive 32-bit words
            round_key_out = {w[round*4], w[round*4+1], w[round*4+2], w[round*4+3]};
        end else if (round == 0) begin
            // For round 0, always output the current key input
            round_key_out = key_in;
        end else begin
            round_key_out = 128'h0;
        end
    end
endmodule
*/