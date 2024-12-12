
module note_decoder (
    input logic clk_in,         // Clock input
    input logic rst_in,         // Reset input
    input logic [23:0] touch_status_in, // 12 touch_status_in to determine the note
    input logic [11:0] switches, 
    output logic [23:0] gate_out,
    output logic [23:0] trigger_out,
    output logic [2:0] note_sel //up to 8 notes
);

    //NOTE TO SELF we could use these paramteres to claridy which note is being played
    // Parameters for note values (e.g., MIDI note numbers or custom IDs)
    parameter NOTE_C4 = 8'd60;  // C4 (Middle C)
    parameter NOTE_D4 = 8'd62;  // D4
    parameter NOTE_E4 = 8'd64;  // E4
    parameter NOTE_F4 = 8'd65;  // F4
    parameter NOTE_G4 = 8'd67;  // G4
    parameter NOTE_A4 = 8'd69;  // A4
    parameter NOTE_B4 = 8'd71;  // B4
    parameter NOTE_C5 = 8'd72;  // C5

    
    logic [11:0] gate_out_prev;

    //YOU CAN COMMENT OUT THE DEBOUNCER LOGIC - IT'S ONLY USED FOR THE SWITCHES

    // logic [11:0] debounced; 
    // logic [11:0] debounced_prev;

    // genvar i;
    // generate
    //     for (i = 0; i < 9; i = i + 1) begin : debounce_loop
    //         debouncer debounce_inst(
    //             .clk_in(clk_in),
    //             .rst_in(rst_in),
    //             .dirty_in(switches[i]),
    //             .clean_out(debounced[i])
    //         );
    //     end
    // endgenerate

    assign gate_out = touch_status_in;
     
    assign trigger_out = gate_out & ~gate_out_prev;
    //assign trigger_out = debounced & ~debounced_prev;



    //  always_ff @(posedge clk_in) begin
    //     if (rst_in) begin
    //         debounced_prev <= 12'b0;
    //     end else begin
    //         debounced_prev <= debounced;
    //     end
    // end

    
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            gate_out_prev <= 24'b0;
        end else begin
            gate_out_prev <= gate_out;
        end
    end

    
    // Note decoding logic
    always_comb begin
        // Default to no note

        case (touch_status_in)
            24'b0000_0000_0000_0000_0000_0001: note_sel = 3'b000; // C4
            24'b0000_0000_0000_0000_0000_0100: note_sel = 3'b010; // C4
            24'b0000_0000_0000_0000_0000_0010: note_sel = 3'b001; // C4
            24'b0000_0000_0000_0000_0000_1000: note_sel = 3'b011; // C4
            24'b0000_0000_0000_0000_0001_0000: note_sel = 3'b100; // C4
            24'b0000_0000_0000_0000_0010_0000: note_sel = 3'b101; // C4
            24'b0000_0000_0000_0000_0100_0000: note_sel = 3'b110; // C4
            24'b0000_0000_0000_0000_1000_0000: note_sel = 3'b111; // C4
            default: note_sel = 3'd0; // No valid switch combination
        endcase

    end

endmodule
