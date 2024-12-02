//this module is currently not being used 
module address_generator #(parameter ADDR_WIDTH = 8)(
  input wire clk_in,
  input wire rst_in,
  input logic [31:0] phase_in[7:0],
  input logic [7:0] gate_in,
  output logic [ADDR_WIDTH-1:0] addr_out [1:0],
  output logic [1:0] num_voices,
  output logic [7:0] active_voices
);



always_comb begin
  integer idx;
  num_voices = 0;
  // Initialize note_addr to zero
  addr_out[0] = 0;
  addr_out[1] = 0;
  for (idx = 0; idx < 8; idx++) begin
    if (gate_in[idx]) begin
      if (num_voices < 2) begin
        addr_out[num_voices] = phase_in[idx][31:32 - ADDR_WIDTH];
        
        num_voices++;
      end
    end
  end
end


  
endmodule