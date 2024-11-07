`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module top_level
  (
   input wire          clk_100mhz, //100 MHz onboard clock
   input wire [15:0]   sw, //all 16 input slide switches
   input wire [3:0]    btn, //all four momentary button switches
   output logic        spkl, spkr, // left and right channels of line out port
   );


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
  assign note_addr = note_value[31:24];
                                        
  // BRAM Memory
  // We've configured this for you, but you'll need to hook up your address and data ports to the rest of your logic!

  parameter BRAM_WIDTH = 8;
  parameter BRAM_DEPTH = 40_000; // 40_000 samples = 5 seconds of samples at 8kHz sample
  parameter ADDR_WIDTH = $clog2(BRAM_DEPTH);

  // only using port a for reads: we only use dout
  logic [BRAM_WIDTH-1:0]     spk_data_out;
  logic [ADDR_WIDTH-1:0]     note_addr;


  xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(BRAM_WIDTH),
      .RAM_DEPTH(BRAM_DEPTH)) audio_bram
      (
      // PORT A
      .addra(note_addr),
      .dina(0), // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0), // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta(spk_data_out),
      // PORT B
      .addrb(addrb),
      .dinb(dinb),
      .clkb(clk_100mhz),
      .web(1'b1), // write always
      .enb(1'b0),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb() // we only use port B for writes!
      );


  // PWM module
  logic                      spk_out;
  // TODO: instantiate a pwm module to drive spk_out based on the
  pwm spk_pwm(.clk_in(clk_100mhz), .rst_in(sys_rst), .dc_in(douta), .sig_out(spk_out));


  // set both output channels equal to the same PWM signal!
  assign spkl = spk_out;
  assign spkr = spk_out;




  // reminder TODO: go up to your PWM module, wire up the speaker to play the data from port A dout.


    
endmodule // top_level

`default_nettype wire
