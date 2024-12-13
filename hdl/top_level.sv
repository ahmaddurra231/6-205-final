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
   //output logic [7:0] analyzer
   );

   // shut up those RGBs
   assign rgb0 = 0;
   assign rgb1 = 0;


   //have btnd control system reset
   logic               sys_rst;
   assign sys_rst = btn[0];


   logic [23:0]       touch_status;
   logic [7:0]        control_pads;
   logic              valid_out; //uncomment for capacitors
   
   assign led = touch_status[15:0];
// uncomment for capacitors
   mpr121_controller mpr121_controller_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .sda(pmodb_sda),
                                           .scl_out(pmodb_scl),
                                           .led(),
                                           .touch_status_out(touch_status),
                                           .valid_out(valid_out), 
                                           .control_out(control_pads)
                                          ); 

   logic [2:0]       note_sel;
   logic [23:0]      gate_value, gate_value_pipe;
   logic [23:0]      trigger_value;  
  
   note_decoder note_decoder_inst(.clk_in(clk_100mhz), 
                                 .rst_in(sys_rst),
                                 .touch_status_in(touch_status),
                                 .switches(touch_status),
                                 .note_sel(note_sel),
                                 .gate_out(gate_value),
                                 .trigger_out(trigger_value)
                                );

    // Generate an ADSR instance per note
    localparam NUM_NOTES = 24;
    localparam NUM_VOICES = 8;

    //Declare arrays for ADSR envelopes and idle signals for each note
    logic [15:0] adsr_envelope [NUM_NOTES-1:0]; 
    logic adsr_idle [NUM_NOTES-1:0];

    //Generate one ADSR instance per note
    genvar i;
    generate
        for (i = 0; i < NUM_NOTES; i = i + 1) begin : ADSR_BLOCK
            adsr #(
                .CLK_FREQ(100_000_000),    
                .T_ATTACK_MS(500),          
                .T_DECAY_MS(500),           
                .T_SUSTAIN_MS(200),        
                .T_RELEASE_MS(50),         
                .A_MAX(32'h8000_0000),     
                .A_SUS(32'h0800_0000)     
            ) adsr_inst (
                .clk_in(clk_100mhz),
                .rst_in(sys_rst),
                .hold(gate_value_pipe[i]),       // Hold is true if this note is playing
                .start(trigger_value[i]),   // Start this ADSR when the note is triggered
                .envelope(adsr_envelope[i]),
                .adsr_idle(adsr_idle[i])
            );
        end
    endgenerate

    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
            gate_value_pipe <= 0;
        end else begin
            gate_value_pipe <= gate_value;
        end
    end





   logic [31:0]      phase_value[23:0];

   phase_accumulator phase_accumulator_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .gate_in(gate_value_pipe),
                                           .phase_value(phase_value)
                                          );
                                        
   // BRAM Memory

   parameter SINE_BRAM_WIDTH = 16;
   parameter SINE_BRAM_DEPTH = 256; 
   parameter SINE_ADDR_WIDTH = $clog2(SINE_BRAM_DEPTH);

   // only using port a for reads: we only use dout
   logic [SINE_BRAM_WIDTH-1:0]  spk_data_out     [NUM_NOTES -1:0]; //changed this to hanlde 4 notes

   logic [SINE_BRAM_WIDTH-1:0]  sine_spk_data_out [NUM_VOICES - 1:0];
   logic [SINE_BRAM_WIDTH-1:0]  sawtooth_spk_data_out [NUM_VOICES - 1:0];
   logic [SINE_BRAM_WIDTH-1:0]  square_spk_data_out [NUM_VOICES - 1:0];
   logic [SINE_ADDR_WIDTH-1:0]     note_addr   [NUM_NOTES - 1:0]; //changed this to handle 4 notes in parallel
   logic [SINE_ADDR_WIDTH-1:0] note_addr_logic [NUM_NOTES - 1:0];// logicister the sine_note_addr for BRAM addressing
   logic [3:0]  num_voices;
   logic [NUM_NOTES - 1:0] active_voices;
   logic [4:0] active_voices_idx [NUM_VOICES -1:0];
   logic [4:0] active_voices_idx_pipe [NUM_VOICES -1:0];

//    assign led[4:0] = active_voices_idx[0];
//    assign led[15:8] = touch_status[23:16];
   

   address_generator address_generator_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .phase_in(phase_value),
                                           .gate_in(gate_value_pipe),
                                           .addr_out(note_addr),
                                           .num_voices(num_voices),
                                           .active_voices(active_voices), 
                                           .active_voices_idx(active_voices_idx)
                                          );


    
    integer idx;

    always_ff @(posedge clk_100mhz ) begin
        if (sys_rst) begin
            for (idx = 0; idx < NUM_NOTES; idx++) begin
                note_addr_logic[idx] <= 0;
            end
            for (idx = 0; idx < NUM_VOICES; idx++) begin
                active_voices_idx_pipe[idx] <= 5'b11111;
            end
        end else begin
            for (idx = 0; idx < NUM_NOTES; idx++) begin        
                note_addr_logic[idx] <= note_addr[idx];     
            end
            for (idx = 0; idx < NUM_VOICES; idx++) begin
                active_voices_idx_pipe[idx] <= active_voices_idx[idx];
            end
        end
    end

///////////////////// SINE BRAMS /////////////////

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(SINE_BRAM_WIDTH),
      .RAM_DEPTH(SINE_BRAM_DEPTH),
      .INIT_FILE("../util/sine_wave_256_uint16.hex")) sine_audio_bram
      (
      // PORT A
      .addra((active_voices_idx_pipe[0] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[0]]),
      .dina(0), // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0), // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta(sine_spk_data_out[0]),
      // PORT B
      .addrb((active_voices_idx_pipe[1] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[1]]),
      .dinb(0),
      .clkb(clk_100mhz),
      .web(1'b0),
      .enb(1'b1),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb(sine_spk_data_out[1])
      );

    
xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sine_wave_256_uint16.hex")
) sine_audio_bram1 (
    // PORT A
    .addra((active_voices_idx_pipe[2] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[2]]),
    .dina(0),
    .clka(clk_100mhz),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(sys_rst),
    .regcea(1'b1),
    .douta(sine_spk_data_out[2]),
    // PORT B
    .addrb((active_voices_idx_pipe[3] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[3]]),
    .dinb(0),
    .clkb(clk_100mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(sine_spk_data_out[3])
);

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sine_wave_256_uint16.hex")
) sine_audio_bram2 (
    // PORT A
    .addra((active_voices_idx_pipe[4] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[4]]),
    .dina(0),
    .clka(clk_100mhz),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(sys_rst),
    .regcea(1'b1),
    .douta(sine_spk_data_out[4]),
    // PORT B
    .addrb((active_voices_idx_pipe[5] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[5]]),
    .dinb(0),
    .clkb(clk_100mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(sine_spk_data_out[5])
);

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sine_wave_256_uint16.hex")
) sine_audio_bram3 (
    // PORT A
    .addra((active_voices_idx_pipe[6] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[6]]),
    .dina(0),
    .clka(clk_100mhz),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(sys_rst),
    .regcea(1'b1),
    .douta(sine_spk_data_out[6]),
    // PORT B
    .addrb((active_voices_idx_pipe[7] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[7]]),
    .dinb(0),
    .clkb(clk_100mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(sine_spk_data_out[7])
);

/////////////////////////////////////////////////////


//////////// SAWTOOTH BRAMS ////////////////////////////


xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(SINE_BRAM_WIDTH),
      .RAM_DEPTH(SINE_BRAM_DEPTH),
      .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram
      (
      // PORT A
      .addra((active_voices_idx_pipe[0] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[0]]),
      .dina(0), // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0), // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta(sawtooth_spk_data_out[0]),
      // PORT B
      .addrb((active_voices_idx_pipe[1] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[1]]),
      .dinb(0),
      .clkb(clk_100mhz),
      .web(1'b0),
      .enb(1'b1),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb(sawtooth_spk_data_out[1])
      );

    
xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram1 (
        // PORT A
        .addra((active_voices_idx_pipe[2] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[2]]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(sawtooth_spk_data_out[2]),
        // PORT B
        .addrb((active_voices_idx_pipe[3] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[3]]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(sawtooth_spk_data_out[3])
    );

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram2 (
        // PORT A
        .addra((active_voices_idx_pipe[4] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[4]]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(sawtooth_spk_data_out[4]),
        // PORT B
        .addrb((active_voices_idx_pipe[5] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[5]]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(sawtooth_spk_data_out[5])
    );

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram3 (
        // PORT A
        .addra((active_voices_idx_pipe[6] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[6]]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(sawtooth_spk_data_out[6]),
        // PORT B
        .addrb((active_voices_idx_pipe[7] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[7]]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(sawtooth_spk_data_out[7])
    );


/////////////////////////////////////////////////////////

////////////////////SQUARE BRAMS //////////////////////////

localparam SQUARE_ADDR_OFFSET = 16;

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(SINE_BRAM_WIDTH),
      .RAM_DEPTH(SINE_BRAM_DEPTH),
      .INIT_FILE("../util/square_wave_256_uint16.hex")
    ) square_audio_bram
      (
      // PORT A
      .addra((active_voices_idx_pipe[0] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[0]]),
      .dina(0), // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0), // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta( square_spk_data_out[0]),
      // PORT B
      .addrb((active_voices_idx_pipe[1] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[1]]),
      .dinb(0),
      .clkb(clk_100mhz),
      .web(1'b0),
      .enb(1'b1),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb( square_spk_data_out[1])
      );
    
xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/square_wave_256_uint16.hex")
    ) square_audio_bram1 (
        // PORT A
        .addra((active_voices_idx_pipe[2] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[2]]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta( square_spk_data_out[2]),
        // PORT B
        .addrb((active_voices_idx_pipe[3] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[3]]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb( square_spk_data_out[3])
    );

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/square_wave_256_uint16.hex")
    ) square_audio_bram2 (
        // PORT A
        .addra((active_voices_idx_pipe[4] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[4]]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta( square_spk_data_out[4]),
        // PORT B
        .addrb((active_voices_idx_pipe[5] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[5]]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb( square_spk_data_out[5])
    );

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/square_wave_256_uint16.hex")
    ) square_audio_bram3 (
        // PORT A
        .addra((active_voices_idx_pipe[6] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[6]]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta( square_spk_data_out[6]),
        // PORT B
        .addrb((active_voices_idx_pipe[7] == 5'b11111)? 0:note_addr_logic[active_voices_idx_pipe[7]]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb( square_spk_data_out[7])
    );

//////////////////////////////////////////////////////////

logic [5:0] note_count;
logic [32:0] voice_values [7:0]; //change 32 back to 16
logic [32:0] enveloped_voice_values_pipe [7:0];
logic [16:0] enveloped_voice_values [7:0];
// logic [32:0] sine_voice_values [7:0]; 
// logic [32:0] sawtooth_voice_values [7:0];
// logic [32:0] square_voice_values [7:0];



integer v_idx;
    
//combine up to 8 notes with adsr envelope

always_comb begin
    note_count = 0;
    for (int i = 0; i < NUM_NOTES; i++) note_count = active_voices[i] + note_count;
end 

always_ff @(posedge clk_100mhz)begin
    for (v_idx = 0; v_idx < 8; v_idx = v_idx + 1) begin
        if (active_voices_idx[v_idx] < 5'b11111) begin

             voice_values[v_idx]  <= (sine_spk_data_out[active_voices_idx[v_idx]] * adsr_envelope[active_voices_idx[v_idx]]) >> 16;
            // sine_voice_values[v_idx] <= (sine_spk_data_out[v_idx] );
            // sawtooth_voice_values[v_idx] <= (sawtooth_spk_data_out[v_idx] );
            // square_voice_values[v_idx] <= (square_spk_data_out[v_idx] );

            // case(sw[15:13])
            //     3'b000: voice_values[v_idx] <= (sine_spk_data_out[v_idx] );
            //     3'b001: voice_values[v_idx] <= (sawtooth_spk_data_out[v_idx] );
            //     3'b010: voice_values[v_idx] <= (square_spk_data_out[v_idx] );

            //     3'b011: voice_values[v_idx] <= (square_spk_data_out[v_idx] + sawtooth_spk_data_out[v_idx]) >> 1;
            //     3'b100: voice_values[v_idx] <= (sine_spk_data_out[v_idx] + square_spk_data_out[v_idx]) >> 1;
            //     3'b101: voice_values[v_idx] <= (sine_spk_data_out[v_idx] + sawtooth_spk_data_out[v_idx]) >> 1;
            //     3'b110: voice_values[v_idx] <= (sine_spk_data_out[v_idx] + sawtooth_spk_data_out[v_idx] + square_spk_data_out[v_idx]) >> 2;
            // endcase

            
            // enveloped_voice_values_pipe[v_idx] <= voice_values[v_idx] * adsr_envelope[active_voices_idx[v_idx]] + 16'h8000;
        

            // enveloped_voice_values[v_idx] <= (enveloped_voice_values_pipe[v_idx][31:16] == 16'h0000) ? (enveloped_voice_values_pipe[idx][15:0]) : 16'hFFFF;


        end else begin
            // voice_values[v_idx] <= 0;
            // sine_voice_values[v_idx] <= 0;
            // sawtooth_voice_values[v_idx] <= 0;
            // square_voice_values[v_idx] <= 0;

            voice_values[v_idx] <= 0;
            // enveloped_voice_values[v_idx] <= 0;
            // enveloped_voice_values_pipe[v_idx] <= 0;
        end
    end
    
end 



// handling 4 notes with adsr_envelope
logic [SINE_BRAM_WIDTH:0] average0, average1, average2, average3;
logic [SINE_BRAM_WIDTH-1:0] combined_sine_spk_data_out;

logic [PDM_WIDTH - 1:0] spk_data_out_shifted;
logic [32:0] multiplied_sum; //change it back to 26 ? 
logic [32:0] sum; //change it back to 19

always_ff @(posedge clk_100mhz ) begin
    if (sys_rst) begin
        average0 <= 0;
        average1 <= 0;
        average2 <= 0;
        average3 <= 0;
        combined_sine_spk_data_out <= 0;

        spk_data_out_shifted <= 0;
    end else begin
        // Averaging Logic
        //sum all             
        //divide by number
        average0 <= voice_values[0] + voice_values[1]; 
        average1 <= voice_values[2] + voice_values[3];
        average2 <= voice_values[4] + voice_values[5];
        average3 <= voice_values[6] + voice_values[7];
        sum <= (average0 + average1 + average2 + average3) ; //OVERFLOW ? how do I take the highest ?
        
        //divide by number of voices played: 
        //combined_sine_spk_data_out <= (average0 + average1 + average2 + average3) >> note_count;
        // try to do this with num_voices
        case(note_count) //replace with note_count
            4'd0: multiplied_sum <= sum * 0;
            4'd1: multiplied_sum <= sum * 255;
            4'd2: multiplied_sum <= sum * 128;
            4'd3: multiplied_sum <= sum * 85;
            4'd4: multiplied_sum <= sum * 64;
            4'd5: multiplied_sum <= sum * 51;
            4'd6: multiplied_sum <= sum * 42;
            4'd7: multiplied_sum <= sum * 36;
            4'd8: multiplied_sum <= sum * 32;
            default: multiplied_sum <= 0;
        endcase

        spk_data_out_shifted <= multiplied_sum >> 8;        
    end
end

//assign analyzer[7] = multiplied_sum[0];



//THE REST OF THIS IS OUD PLAYBACK - I DON NOT THINK WE NEED IT ANYMORE - BUT LET'S DISCUSS THIS

//Sample Rate Generater
logic sample_tick; // Tick signal at 16,384 Hz

sample_rate_counter #(
    .SAMPLE_RATE(16384),
    .CLK_FREQ(100_000_000)
) sample_rate_counter_inst (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .sample_tick(sample_tick)
);



//PDM Module Instantiation
logic spk_out;

localparam PDM_RESOLUTION = 65536; 
localparam PDM_WIDTH = $clog2(PDM_RESOLUTION);
localparam SCALE_FACTOR = PDM_RESOLUTION / 256;
localparam PDM_SHIFT = $clog2(SCALE_FACTOR); 

pdm #(
    .PDM_RESOLUTION(PDM_RESOLUTION) // 8-bit resolution
) spk_pdm (
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .dc_in(spk_data_out_shifted),
    .gate_in(gate_value_pipe),
    .sig_out(spk_out)
);

//Connect PWM Output to Speakers
assign spkl = spk_out;
assign spkr = spk_out;

endmodule 

`default_nettype wire 
