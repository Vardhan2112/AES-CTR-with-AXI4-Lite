`timescale 1ns / 1ps
//
// Module: Rcon
// Description: Provides the round constant based on the round number.
//
module Rcon (
    input  [3:0]  round_num, // Expects 1 to 10
    output [31:0] rcon_val
);
    reg [31:0] rcon_reg;
    assign rcon_val = rcon_reg;

    always @(*) begin
        case (round_num)
            4'd1:  rcon_reg = 32'h01000000;
            4'd2:  rcon_reg = 32'h02000000;
            4'd3:  rcon_reg = 32'h04000000;
            4'd4:  rcon_reg = 32'h08000000;
            4'd5:  rcon_reg = 32'h10000000;
            4'd6:  rcon_reg = 32'h20000000;
            4'd7:  rcon_reg = 32'h40000000;
            4'd8:  rcon_reg = 32'h80000000;
            4'd9:  rcon_reg = 32'h1B000000;
            4'd10: rcon_reg = 32'h36000000;
            default: rcon_reg = 32'h00000000;
        endcase
    end
endmodule