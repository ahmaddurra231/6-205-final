//Changed this module to be sequential to meet time requirment

module address_generator #(
  parameter ADDR_WIDTH = 8
)(
  input wire clk_in,
  input wire rst_in,
  input logic [31:0] phase_in [7:0],
  input logic [7:0] gate_in,
  output logic [ADDR_WIDTH-1:0] addr_out [3:0],
  output logic [2:0] num_voices,
  output logic [7:0] active_voices
);

  integer idx;

  // Sequential logic block
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      num_voices     <= 0;
      active_voices  <= 0;
      addr_out[0]    <= 0;
      addr_out[1]    <= 0;
      addr_out[2]    <= 0;
      addr_out[3]    <= 0;
    end 
    
    else begin
      // Reset temporary variables
      num_voices     <= 0;
      active_voices  <= 8'b0;
      addr_out[0]    <= 0;
      addr_out[1]    <= 0;
      addr_out[2]    <= 0;
      addr_out[3]    <= 0;
      
      // Iterate through each gate to determine active voices and assign addresses
      for (idx = 0; idx < 8; idx++) begin
        if (gate_in[idx]) begin
          active_voices[idx] <= 1'b1; // Mark the voice as active
          
          if (num_voices < 4) begin
            addr_out[num_voices] <= phase_in[idx][31:(32 - ADDR_WIDTH)];
            num_voices <= num_voices + 1;
          end

        end 
        
        else begin
          active_voices[idx] <= 1'b0; // Mark the voice as inactive
        end
      end
    end
  end

endmodule
