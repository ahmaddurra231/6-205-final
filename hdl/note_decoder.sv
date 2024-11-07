module note_decoder (
    input logic [3:0] btn_in,      // 4 btn_in as triggers
    input logic [15:0] sw_in,    // 16 sw_in to determine the note
    output logic [7:0] note_out   // Output note value (frequency index or ID)
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
    
    // Note decoding logic
    always_comb begin
        // Default to no note
        note_out = 8'd0;

        // Check which button is pressed
        case (btn_in)
            4'b0010: begin
                // Button 0 pressed - determine note based on sw_in
                case (sw_in)
                    16'b0000_0000_0000_0001: note_out = NOTE_C4;
                    16'b0000_0000_0000_0010: note_out = NOTE_D4;
                    16'b0000_0000_0000_0100: note_out = NOTE_E4;
                    16'b0000_0000_0000_1000: note_out = NOTE_F4;
                    16'b0000_0000_0001_0000: note_out = NOTE_G4;
                    16'b0000_0000_0010_0000: note_out = NOTE_A4;
                    16'b0000_0000_0100_0000: note_out = NOTE_B4;
                    16'b0000_0000_1000_0000: note_out = NOTE_C5;
                    default: note_out = 8'd0; // No valid switch combination
                endcase
            end
            4'b0001: begin
                // Button 1 pressed - use another set of switch mappings if needed
                // (similar case structure for additional notes can be added here)
                note_out = 8'd0; // Placeholder for future use
            end
            4'b0100: begin
                // Button 2 pressed - more switch mappings can be added here
                note_out = 8'd0; // Placeholder for future use
            end
            4'b1000: begin
                // Button 3 pressed - more switch mappings can be added here
                note_out = 8'd0; // Placeholder for future use
            end
            default: note_out = 8'd0; // No button pressed
        endcase
    end

endmodule
