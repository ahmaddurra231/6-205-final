//phase accumulator is only used for sine_wave so I reverted back to the ld version of it after I used the multiple BRAMs for Oud

module phase_accumulator (
    input logic clk_in,                  // System clock
    input logic rst_in,                  // Reset signal
    input logic [7:0] note_in,     // Note frequency value from Note Decoder
    output logic [31:0] phase_value   // Accumulated phase value output
);
  // Parameters for note values (e.g., MIDI note numbers or custom IDs)
  parameter NOTE_C4 = 8'd60;  // C4 (Middle C)
  parameter NOTE_D4 = 8'd62;  // D4
  parameter NOTE_E4 = 8'd64;  // E4
  parameter NOTE_F4 = 8'd65;  // F4
  parameter NOTE_G4 = 8'd67;  // G4
  parameter NOTE_A4 = 8'd69;  // A4
  parameter NOTE_B4 = 8'd71;  // B4
  parameter NOTE_C5 = 8'd72;  // C5


  // Phase increment value - Adjusted according to the note value
  logic [31:0] phase_increment;

  // Frequency to Phase Increment mapping (simplified)
  always_comb begin
      case (note_in)
          // value calculated based on a 100mhz clock.
          NOTE_C4: phase_increment = 32'd112404;  // Example value for C4
          NOTE_D4: phase_increment = 32'd126156;  // Example value for D4
          NOTE_E4: phase_increment = 32'd141526;  // Example value for E4
          NOTE_F4: phase_increment = 32'd149664;  // Example value for F4
          NOTE_G4: phase_increment = 32'd167772;  // Example value for G4
          NOTE_A4: phase_increment = 32'd188743;  // Example value for A4
          NOTE_B4: phase_increment = 32'd211688;  // Example value for B4
          NOTE_C5: phase_increment = 32'd224003;  // Example value for C5
          default: phase_increment = 32'd0;     // No valid note selected
      endcase
  end

  // Phase accumulator register
  always_ff @(posedge clk_in) begin
      if (rst_in) begin
          phase_value <= 32'd0; // Reset phase value to 0
      end else begin
          phase_value <= phase_value + phase_increment; // Accumulate phase
      end
  end

endmodule





// module phase_accumulator (
//     input logic clk_in,                // System clock (100 MHz)
//     input logic rst_in,                // Reset signal
//     input logic [7:0] note_in,         // Note frequency value from Note Decoder
//     output logic [31:0] phase_value    // Accumulated phase value output
// );
//     // Parameters for note values (e.g., MIDI note numbers or custom IDs)
//     parameter NOTE_C4 = 8'd60;  // C4 (Middle C)
//     parameter NOTE_D4 = 8'd62;  // D4
//     parameter NOTE_E4 = 8'd64;  // E4
//     parameter NOTE_F4 = 8'd65;  // F4
//     parameter NOTE_G4 = 8'd67;  // G4
//     parameter NOTE_A4 = 8'd69;  // A4
//     parameter NOTE_B4 = 8'd71;  // B4
//     parameter NOTE_C5 = 8'd72;  // C5

//     // Frequencies of the notes (in Hz)
//     parameter real FREQ_C4 = 261.63;
//     parameter real FREQ_D4 = 293.66;
//     parameter real FREQ_E4 = 329.63;
//     parameter real FREQ_F4 = 349.23;
//     parameter real FREQ_G4 = 392.00;
//     parameter real FREQ_A4 = 440.00;
//     parameter real FREQ_B4 = 493.88;
//     parameter real FREQ_C5 = 523.25;

//     // Sample rate (in Hz)
//     parameter real SAMPLE_RATE = 16_384.0;

//     // Function to calculate phase increment
//     function [31:0] calculate_phase_increment(input real frequency);
//         real phase_inc_real;
//         begin
//             phase_inc_real = (frequency * (2.0**32)) / SAMPLE_RATE;
//             calculate_phase_increment = $rtoi(phase_inc_real);
//         end
//     endfunction

//     // Phase increment value - Adjusted according to the note value
//     logic [31:0] phase_increment;

//     // Frequency to Phase Increment mapping
//     always_comb begin
//         case (note_in)
//             NOTE_C4: phase_increment = calculate_phase_increment(FREQ_C4);
//             NOTE_D4: phase_increment = calculate_phase_increment(FREQ_D4);
//             NOTE_E4: phase_increment = calculate_phase_increment(FREQ_E4);
//             NOTE_F4: phase_increment = calculate_phase_increment(FREQ_F4);
//             NOTE_G4: phase_increment = calculate_phase_increment(FREQ_G4);
//             NOTE_A4: phase_increment = calculate_phase_increment(FREQ_A4);
//             NOTE_B4: phase_increment = calculate_phase_increment(FREQ_B4);
//             NOTE_C5: phase_increment = calculate_phase_increment(FREQ_C5);
//             default: phase_increment = 32'd0; // No valid note selected
//         endcase
//     end

//     // Phase accumulator register
//     always_ff @(posedge clk_in) begin
//         if (rst_in) begin
//             phase_value <= 32'd0; // Reset phase value to 0
//         end else begin
//             phase_value <= phase_value + phase_increment; // Accumulate phase
//         end
//     end

// endmodule



