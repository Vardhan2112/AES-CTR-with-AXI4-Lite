`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2025 11:27:21
// Design Name: 
// Module Name: bram_memory
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
// Module: bram_memory
// Description: A simple synchronous memory model that will be inferred
//              as Block RAM (BRAM) by the synthesis tool. It has a 
//              one-cycle read latency.
//////////////////////////////////////////////////////////////////////////////////

module bram_memory #(
    // Parameters make the module reusable
    parameter DATA_WIDTH = 128,         // How wide each memory location is
    parameter ADDR_WIDTH = 8,           // How many bits for the address
    parameter DEPTH      = 2**ADDR_WIDTH // The number of memory locations
)(
    input                      clk,
    input                      we,         // Write Enable: high to write, low to read
    input      [ADDR_WIDTH-1:0] addr,
    input      [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    // This is the core memory array. Vivado will map this to a BRAM resource.
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];

    // Synchronous Write Logic
    // On the rising edge of the clock, if write enable is high,
    // store the input data at the specified address.
    always @(posedge clk) begin
        if (we) begin
            mem[addr] <= data_in;
        end
    end
    
    // Synchronous Read Logic
    // On the rising edge of the clock, the data at the current address
    // is read from the memory array and latched into the output register.
    // This creates a one-cycle read latency.
    always @(posedge clk) begin
        data_out <= mem[addr];
    end

endmodule