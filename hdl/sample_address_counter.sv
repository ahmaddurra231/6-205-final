`timescale 1ns / 1ps
`default_nettype none

module sample_address_counter #(
    parameter integer BRAM_DEPTH = 8192, // Number of samples per BRAM
    parameter integer ADDR_WIDTH = 13    // Address width (log2(BRAM_DEPTH)) for BRAM_DEPTH = 8192
)(
    input  wire clk_in,
    input  wire rst_in,
    input  wire sample_tick,
    input  wire gate_in,
    output reg [ADDR_WIDTH-1:0] sample_addr
);
    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in || !gate_in) begin
            sample_addr <= 0;
        end else if (sample_tick) begin
            if (sample_addr == BRAM_DEPTH - 1) begin
                sample_addr <= 0; // Loop back to start
            end else begin
                sample_addr <= sample_addr + 1;
            end
        end
    end
endmodule

`default_nettype wire

