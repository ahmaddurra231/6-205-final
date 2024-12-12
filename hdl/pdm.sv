`timescale 1ns / 1ps
`default_nettype none
module pdm #(
  parameter integer PDM_RESOLUTION = 256 // Default 8-bit resolution
)(
  input wire clk_in,
  input wire rst_in,
  input wire [PDM_RESOLUTION_WIDTH - 1:0] dc_in,  // Input amplitude (8-bit)
  input wire [23:0] gate_in, // Gate signal for note activity
  output logic sig_out     // PDM output signal
);
  localparam PDM_RESOLUTION_WIDTH = $clog2(PDM_RESOLUTION);

  // Accumulator for PDM modulation
  logic [PDM_RESOLUTION_WIDTH:0] accumulator; // 9-bit to handle overflow
  logic [PDM_RESOLUTION_WIDTH:0] pdm_res_minus_dc;
  assign pdm_res_minus_dc = PDM_RESOLUTION - dc_in;
    
  always_ff @(posedge clk_in or posedge rst_in) begin
    if (rst_in) begin
      accumulator <= 0;
      sig_out <= 0;
    end else begin
      if (|gate_in) begin
        if (accumulator >= pdm_res_minus_dc) begin
          sig_out <= 1;
          accumulator <= accumulator - pdm_res_minus_dc;
        end else begin
          sig_out <= 0;
          accumulator <= accumulator + dc_in;
        end
      end else begin
        sig_out <= 0; // Silence when gate is inactive
      end
    end
  end
endmodule
`default_nettype wire
