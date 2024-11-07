`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level
  (
   input wire          clk_100mhz, //100 MHz onboard clock
   input wire [15:0]   sw, //all 16 input slide switches
   input wire [3:0]    btn, //all four momentary button switches
   output logic        spkl, spkr, // left and right channels of line out port
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1
   );

  // shut up those RGBs
  assign rgb0 = 0;
  assign rgb1 = 0;


   //have btnd control system reset
  logic               sys_rst;
  assign sys_rst = btn[0];


  logic [7:0]       note_value;
  logic [31:0]      phase_value;
  
  note_decoder note_decoder_inst(.sw_in(sw), 
                                 .btn_in(btn), 
                                 .note_out(note_value)
                                );

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
  pwm spk_pwm(.clk_in(clk_100mhz), .rst_in(sys_rst), .dc_in(spk_data_out_shifted), .sig_out(spk_out));


  // set both output channels equal to the same PWM signal!
  assign spkl = spk_out;
  assign spkr = spk_out;
    
endmodule // top_level

`default_nettype wire
