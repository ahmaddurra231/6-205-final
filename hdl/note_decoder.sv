module note_decoder (
    input logic clk_in,         // Clock input
    input logic rst_in,         // Reset input
    input logic [11:0] touch_status_in, // 12 touch_status_in to determine the note
    input logic [15:0] sw_in,    // 16 sw_in to determine the note
    output logic [7:0] note_out,   // Output note value (frequency index or ID)
    output logic gate_out,
    output logic trigger_out
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

    
    logic gate_out_prev;


    // debouncer key_press_debounce(
    //     .clk_in(clk_in),
    //     .rst_in(rst_in),
    //     .dirty_in(btn_in[1]),
    //     .clean_out(key_press)
    // );

    assign gate_out = |touch_status_in;
    assign trigger_out = gate_out & ~gate_out_prev;


    
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            gate_out_prev <= 1'b0;
        end else begin
            gate_out_prev <= gate_out;
        end
    end

    
    // Note decoding logic
    always_comb begin
        // Default to no note

        case (touch_status_in)
            12'b0000_0000_0001: note_out = NOTE_C4;
            12'b0000_0000_0010: note_out = NOTE_D4;
            12'b0000_0000_0100: note_out = NOTE_E4;
            12'b0000_0000_1000: note_out = NOTE_F4;
            12'b0000_0001_0000: note_out = NOTE_G4;
            12'b0000_0010_0000: note_out = NOTE_A4;
            12'b0000_0100_0000: note_out = NOTE_B4;
            12'b0000_1000_0000: note_out = NOTE_C5;
            default: note_out = 8'd0; // No valid switch combination
        endcase

    end

endmodule
