`default_nettype none // Prevents implicit net declarations

module top_level
  (
   input wire          clk_100mhz, //100 MHz onboard clock
   input wire [15:0]   sw, //all 16 input slide switches
   input wire [3:0]    btn, //all four momentary button switches
   inout wire        pmodb_sda, //I2C data line
   output wire      pmodb_scl, //I2C clock line
   output logic        spkl, spkr, // left and right channels of line out port
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1,
   output logic [15:0] led
   );

   // shut up those RGBs
   assign rgb0 = 0;
   assign rgb1 = 0;


   //have btnd control system reset
   logic               sys_rst;
   assign sys_rst = btn[0];


   logic [11:0]       touch_status;
   logic              valid_out;
   

   mpr121_controller mpr121_controller_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .sda(pmodb_sda),
                                           .scl_out(pmodb_scl),
                                           .led(led[15:0]),
                                           .touch_status_out(touch_status),
                                           .valid_out(valid_out)
                                          );

   logic [7:0]       note_value;
   logic             gate_value;
   logic             trigger_value;

  //  assign led[11:0] = touch_status;
  
  
   note_decoder note_decoder_inst(.clk_in(clk_100mhz), 
                                 .rst_in(sys_rst),
                                 .touch_status_in(touch_status),
                                 .note_out(note_value),
                                 .gate_out(gate_value),
                                 .trigger_out(trigger_value)
                                );


   logic [31:0]      phase_value;

   phase_accumulator phase_accumulator_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .note_in(note_value),
                                           .phase_value(phase_value)
                                          );
                                        
   // BRAM Memory
   // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!

   parameter BRAM_WIDTH = 8;
   parameter BRAM_DEPTH = 256; // 40_000 samples = 5 seconds of samples at 8kHz sample
   parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);

   // only using port a for reads: we only use dout
   logic [BRAM_WIDTH-1:0]     spk_data_out;
   logic [ADDR_WIDTH-1:0]     note_addr;

   assign note_addr = phase_value[31:32 - ADDR_WIDTH];


   xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(BRAM_WIDTH),
      .RAM_DEPTH(BRAM_DEPTH),
      .INIT_FILE("../util/sine_wave_256.hex")) audio_bram
      (
      // PORT A
      .addra(note_addr),
      .dina(0), // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0), // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta(spk_data_out)
      );


   // PWM module
   logic                      spk_out;
   logic [BRAM_WIDTH-1:0]     spk_data_out_shifted;

   assign spk_data_out_shifted = spk_data_out >> 2; // shift right to match 8-bit PWM resolution
   // TODO: instantiate a pwm module to drive spk_out based on the
   pwm spk_pwm(
    .clk_in(clk_100mhz), 
    .rst_in(sys_rst), 
    .dc_in(spk_data_out_shifted), 
    .gate_in(gate_value),
    .sig_out(spk_out));


   // set both output channels equal to the same PWM signal!
   assign spkl = spk_out;
   assign spkr = spk_out;
    
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
