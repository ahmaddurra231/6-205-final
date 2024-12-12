//bringin the older version: 
//Changed this module to be sequential to meet time requirment

module address_generator #(
  parameter ADDR_WIDTH = 8
)(
  input wire clk_in,
  input wire rst_in,
  input logic [31:0] phase_in [23:0],
  input logic [23:0] gate_in,
  output logic [ADDR_WIDTH-1:0] addr_out [23:0],
  output logic [4:0] num_voices,
  output logic [23:0] active_voices
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
      addr_out[4]    <= 0;
      addr_out[5]    <= 0;
      addr_out[6]    <= 0;
      addr_out[7]    <= 0;
      addr_out[8]    <= 0;
      addr_out[9]    <= 0;
      addr_out[10]    <= 0;
      addr_out[11]    <= 0;
      addr_out[12]    <= 0;
      addr_out[13]    <= 0;
      addr_out[14]    <= 0;
      addr_out[15]    <= 0;
      addr_out[16]    <= 0;
      addr_out[17]    <= 0;
      addr_out[18]    <= 0;
      addr_out[19]    <= 0;
      addr_out[20]    <= 0;
      addr_out[21]    <= 0;
      addr_out[22]    <= 0;
      addr_out[23]    <= 0;
      
    end 
    
    else begin
      // Reset temporary variables
      num_voices     <= 0;
      active_voices  <= 8'b0;
      addr_out[0]    <= 0;
      addr_out[1]    <= 0;
      addr_out[2]    <= 0;
      addr_out[3]    <= 0;
      addr_out[4]    <= 0;
      addr_out[5]    <= 0;
      addr_out[6]    <= 0;
      addr_out[7]    <= 0;
      addr_out[8]    <= 0;
      addr_out[9]    <= 0;
      addr_out[10]    <= 0;
      addr_out[11]    <= 0;
      addr_out[12]    <= 0;
      addr_out[13]    <= 0;
      addr_out[14]    <= 0;
      addr_out[15]    <= 0;
      addr_out[16]    <= 0;
      addr_out[17]    <= 0;
      addr_out[18]    <= 0;
      addr_out[19]    <= 0;
      addr_out[20]    <= 0;
      addr_out[21]    <= 0;
      addr_out[22]    <= 0;
      addr_out[23]    <= 0;
      
      // Iterate through each gate to determine active voices and assign addresses
      for (idx = 0; idx < 24; idx++) begin
        if (gate_in[idx]) begin
          active_voices[idx] <= 1'b1; // Mark the voice as active
          
          //if (num_voices < 4) begin
            addr_out[idx] <= phase_in[idx][31:(32 - ADDR_WIDTH)]; //replaced num_voices with idx
            num_voices <= num_voices + 1; //I can make this output the number of voices played
          //end

        end 
        
        else begin
          active_voices[idx] <= 1'b0; // Mark the voice as inactive
        end
      end
    end
  end

endmodule

// //Changed this module to be sequential to meet time requirment

// module address_generator #(
//   parameter ADDR_WIDTH = 8,
//   parameter NUM_NOTES = 24, 
//   parameter NUM_VOICES = 24 //not being used 

// )(
//   input wire clk_in,
//   input wire rst_in,
//   input logic [31:0] phase_in [NUM_NOTES - 1:0],
//   input logic [NUM_NOTES - 1:0] gate_in,
//   output logic [ADDR_WIDTH-1:0] addr_out [NUM_NOTES - 1:0],
//   output logic [4:0] num_voices,
//   output logic [NUM_NOTES - 1:0] active_voices,
//   output logic [NUM_NOTES_WIDTH - 1:0] active_voices_idx [NUM_VOICES - 1:0]
// );

//   integer idx;

//   localparam integer NUM_NOTES_WIDTH = 5;
  

//   // Sequential logic block
//   always_ff @(posedge clk_in) begin
//     if (rst_in) begin
//       num_voices     <= 0;
//       active_voices  <= 0;
//       for (idx = 0; idx < NUM_NOTES; idx++) begin
//         addr_out[idx] <= '0;
//       end
//     end 
    
//     else begin
//       // Reset temporary variables
//       num_voices     <= 0;
//       active_voices  <= 8'b0;
//       for (idx = 0; idx < NUM_NOTES; idx++) begin
//         addr_out[idx] <= '0;
//       end

//       for (idx = 0; idx < NUM_VOICES; idx++) begin
//         active_voices_idx[idx] <= 5'b11111;
//       end
      
//       // Iterate through each gate to determine active voices and assign addresses
//       for (idx = 0; idx < NUM_NOTES; idx++) begin
//         if (gate_in[idx]) begin
//           if (num_voices < NUM_VOICES) begin
//             active_voices[idx] <= 1'b1; // Mark the voice as active
//             active_voices_idx[num_voices] <= idx;
//             addr_out[idx] <= phase_in[idx][31:(32 - ADDR_WIDTH)];
//             num_voices <= num_voices + 1; //I can make this output the number of voices played
//           end
//         end else begin
//           active_voices[idx] <= 1'b0; // Mark the voice as inactive
//         end
//       end
//     end
//   end

// endmodule
