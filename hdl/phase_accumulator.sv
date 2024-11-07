//returns a 32-bit phase value by a phase increment value that is
// appropriately scaled to the desired frequency.

module phase_accumulator (
    input logic clk_in,                  // System clock
    input logic rst_in,                  // Reset signal
    input logic [7:0] note_value,     // Note frequency value from Note Decoder
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
      case (note_value)
          // value calculated based on a 100mhz clock.
          NOTE_C4: phase_increment = 32'd112404;  // Example value for C4
          NOTE_D4: phase_increment = 32'd126156;  // Example value for D4
          NOTE_E4: phase_increment = 32'd141526;  // Example value for E4
          NOTE_F4: phase_increment = 32'd149664;  // Example value for F4
          NOTE_F4: phase_increment = 32'd167772;  // Example value for G4
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
