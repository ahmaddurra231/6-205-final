`default_nettype none // Prevents implicit net declarations

module top_level (
    input wire          clk_100mhz, 
    input wire [15:0]   sw,         // 16 input slide switches for note selection
    input wire [3:0]    btn,        // 4 momentary button switches
    output logic        spkl, spkr,  // Left and right channels of line out port
    output logic [2:0]  rgb0, rgb1   // RGB LEDs (unused)
);

    //turn off RGC LEDs
    assign rgb0 = 3'b000; 
    assign rgb1 = 3'b000; 

    
    logic               sys_rst;
    assign sys_rst = btn[0]; // button[0] to reset the system

    //Note Selection
    logic [2:0]         note_sel;      // 3-bit note selection signal (supports up to 8 notes)
    logic               gate_value;    // Gate signal to control playback
    logic               trigger_value; // Trigger signal for note on events

    // Instantiate the Note Decoder
    note_decoder note_decoder_inst (
        .clk_in(clk_100mhz),
        .sw_in(sw),
        .rst_in(sys_rst),
        .btn_in(btn),
        .note_sel(note_sel),
        .gate_out(gate_value),
        .trigger_out(trigger_value)
    );

    //Sample Rate Generater
    logic               sample_tick; // Tick signal at 16,384 Hz

    sample_rate_counter #(
        .SAMPLE_RATE(16384),
        .CLK_FREQ(100_000_000)
    ) sample_rate_counter_inst (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .sample_tick(sample_tick)
    );

    //Sample Adress Counter
    parameter BRAM_DEPTH  = 8192; // Number of samples per note
    parameter ADDR_WIDTH  = 13; //$clog2(BRAM_DEPTH);  // Address width (13 bits for 8192 depth)

    logic [ADDR_WIDTH-1:0] sample_addr; // Current sample address

    sample_address_counter #(
    .BRAM_DEPTH(BRAM_DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) sample_address_counter_inst (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .sample_tick(sample_tick),
    .gate_in(gate_value),
    .sample_addr(sample_addr)
);

    //BRAM instances for each note 
    //NOTE TO SELF: Currently we have 4 notes, we should use generate for more efficient code to generate more notes
    parameter BRAM_WIDTH = 16; // 16-bit sample width

    localparam NUM_NOTES = 8; 

    // Wires to hold data output from each BRAM
    logic [BRAM_WIDTH-1:0] bram_data_out [NUM_NOTES-1:0];

    // Instantiate BRAMs for each note
    // change hex file in each BRAM to generate a different note
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH),
        .INIT_FILE("../util/output_hex_files/note_1_wave_16ksps.hex") 
    ) bram_note0 (
        .addra(sample_addr),
        .dina(16'd0), // Read-only port
        .clka(clk_100mhz),
        .wea(1'b0),    // Read-only
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(bram_data_out[0])
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH),
        .INIT_FILE("../util/output_hex_files/note_2_wave_16ksps.hex") 
    ) bram_note1 (
        .addra(sample_addr),
        .dina(16'd0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(bram_data_out[1])
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH),
        .INIT_FILE("../util/output_hex_files/note_3_wave_16ksps.hex") 
    ) bram_note2 (
        .addra(sample_addr),
        .dina(16'd0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(bram_data_out[2])
    );

    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(BRAM_WIDTH),
        .RAM_DEPTH(BRAM_DEPTH),
        .INIT_FILE("../util/output_hex_files/note_4_wave_16ksps.hex") 
    ) bram_note3 (
        .addra(sample_addr),
        .dina(16'd0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(bram_data_out[3])
    );


    //Select BRAM Output Based on Note Selection
    logic [BRAM_WIDTH-1:0] selected_bram_data;

    always_comb begin
        case (note_sel)
            3'd0: selected_bram_data = bram_data_out[0];
            3'd1: selected_bram_data = bram_data_out[1];
            3'd2: selected_bram_data = bram_data_out[2];
            3'd3: selected_bram_data = bram_data_out[3];
            // Extend the case statement for additional notes
            default: selected_bram_data = 16'd0; // Silence if no valid note is selected
        endcase
    end

    //Prepare Data for PWM
    logic [7:0] spk_data_out_shifted;

    // Convert 16-bit signed sample to 8-bit unsigned for PWM
    assign spk_data_out_shifted = selected_bram_data[15:8] + 8'd128; // Simple scaling

    //PWM Module Instantiation
    logic spk_out;

    pwm #(
        .PWM_RESOLUTION(256) // 8-bit resolution
    ) spk_pwm (
        .clk_in(clk_100mhz),
        .rst_in(sys_rst),
        .dc_in(spk_data_out_shifted),
        .gate_in(gate_value),
        .sig_out(spk_out)
    );

    //Connect PWM Output to Speakers
    assign spkl = spk_out;
    assign spkr = spk_out;

endmodule 

`default_nettype wire 
