//Changed this module to be sequential to meet time requirment

module address_generator #(
  parameter ADDR_WIDTH = 8,
  parameter NUM_NOTES = 24, 
  parameter NUM_VOICES = 8

)(
  input wire clk_in,
  input wire rst_in,
  input logic [31:0] phase_in [NUM_NOTES - 1:0],
  input logic [NUM_NOTES - 1:0] gate_in,
  output logic [ADDR_WIDTH-1:0] addr_out [NUM_NOTES - 1:0],
  output logic [3:0] num_voices,
  output logic [NUM_NOTES - 1:0] active_voices,
  output logic [NUM_NOTES_WIDTH - 1:0] active_voices_idx [NUM_VOICES - 1:0]
);

  integer idx;

  localparam integer NUM_NOTES_WIDTH = 5;
  localparam integer NUM_NOTES_PER_WAVEFORM = 8;


  logic [1:0] waveform_idx;
  logic [5:0] waveform_idx_offset;

  logic [3:0] num_voices_intermediate;
  logic [NUM_NOTES - 1:0] active_voices_intermediate;
  logic [NUM_NOTES_WIDTH - 1:0] active_voices_idx_intermediate [NUM_VOICES - 1:0];

  assign waveform_idx_offset = (waveform_idx == 0) ? 0 :
                               (waveform_idx == 1) ? 8 : 16;
  

  // Sequential logic block
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      num_voices     <= 0;
      active_voices  <= 0;
      waveform_idx   <= 3;
      for (idx = 0; idx < NUM_NOTES; idx++) begin
        addr_out[idx] <= '0;
      end
      for (idx = 0; idx < NUM_VOICES; idx++) begin
        active_voices_idx[idx] <= 5'b11111;
        active_voices_idx_intermediate[idx] <= 5'b11111;
      end
      num_voices_intermediate <= 0;
      active_voices_intermediate <= 0;
        
    end 
    
    else begin
      // Reset temporary variables
      logic [3:0] temp_num_voices;
      logic [NUM_NOTES - 1:0] temp_active_voices;
      logic [NUM_NOTES_WIDTH - 1:0] temp_active_voices_idx [NUM_VOICES - 1:0];

      if (waveform_idx == 3) begin
        //
        num_voices <= num_voices_intermediate;
        active_voices <= active_voices_intermediate;
        for (idx = 0; idx < NUM_VOICES; idx++) begin
          active_voices_idx[idx] <= active_voices_idx_intermediate[idx];
        end
        num_voices_intermediate <= 0;
        active_voices_intermediate <= 0;
        for (idx = 0; idx < NUM_VOICES; idx++) begin
          active_voices_idx_intermediate[idx] <= 5'b11111;
        end
      end else begin
        temp_num_voices = num_voices_intermediate;
        temp_active_voices = active_voices_intermediate;
        for (idx = 0; idx < NUM_VOICES; idx++) begin
          temp_active_voices_idx[idx] = active_voices_idx_intermediate[idx];
        end
          // Iterate through each gate to determine active voices and assign addresses
        for (idx = 0; idx < NUM_NOTES; idx++) begin
          if (idx >= waveform_idx_offset && idx < (waveform_idx_offset + NUM_NOTES_PER_WAVEFORM)) begin
            if (gate_in[idx]) begin
              if (temp_num_voices < NUM_VOICES) begin
                temp_active_voices[idx] = 1'b1; // Mark the voice as active
                temp_active_voices_idx[temp_num_voices] = idx;
                addr_out[idx] <= phase_in[idx][31:(32 - ADDR_WIDTH)];
                temp_num_voices = temp_num_voices + 1; //I can make this output the number of voices played
              end

            end else begin
              addr_out[idx] <= '0;
            end
          end
        end

        num_voices_intermediate <= temp_num_voices;
        active_voices_intermediate <= temp_active_voices;
        for (idx = 0; idx < NUM_VOICES; idx++) begin
          active_voices_idx_intermediate[idx] <= temp_active_voices_idx[idx];
        end
      end
      waveform_idx <= waveform_idx + 1;
      
    end
  end

endmodule
