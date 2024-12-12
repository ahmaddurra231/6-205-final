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
   logic              valid_out; //uncomment for capacitors
   
// uncomment for capacitors
   mpr121_controller mpr121_controller_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .sda(pmodb_sda),
                                           .scl_out(pmodb_scl),
                                           .led(), //ask durra
                                           .touch_status_out(touch_status),
                                           .valid_out(valid_out)
                                          ); 

   logic [2:0]       note_sel;
   logic [23:0]      gate_value;
   logic [23:0]      trigger_value;  
  
   note_decoder note_decoder_inst(.clk_in(clk_100mhz), 
                                 .rst_in(sys_rst),
                                 .touch_status_in(touch_status),
                                 //.switches(touch_status),
                                 .note_sel(note_sel),
                                 .gate_out(gate_value),
                                 .trigger_out(trigger_value)
                                );

    // Generate an ADSR instance per note
    localparam NUM_NOTES = 24;
    localparam NUM_VOICES = 24;

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
                .hold(gate_value[i]),       // Hold is true if this note is playing
                .start(trigger_value[i]),   // Start this ADSR when the note is triggered
                .envelope(adsr_envelope[i]),
                .adsr_idle(adsr_idle[i])
            );
        end
    endgenerate





   logic [31:0]      phase_value[23:0];

   phase_accumulator phase_accumulator_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .gate_in(gate_value),
                                           .phase_value(phase_value)
                                          );
                                        
   // BRAM Memory

   parameter SINE_BRAM_WIDTH = 16;
   parameter SINE_BRAM_DEPTH = 256; 
   parameter SINE_ADDR_WIDTH = $clog2(SINE_BRAM_DEPTH);

   // only using port a for reads: we only use dout
   logic [SINE_BRAM_WIDTH-1:0]  spk_data_out     [NUM_NOTES -1:0]; //changed this to hanlde 4 notes
   logic [SINE_ADDR_WIDTH-1:0]     note_addr   [NUM_NOTES - 1:0]; //changed this to handle 4 notes in parallel
   //logic [SINE_ADDR_WIDTH-1:0] note_addr_logic [NUM_NOTES - 1:0];// logicister the sine_note_addr for BRAM addressing
   logic [4:0]  num_voices;
   logic [NUM_NOTES - 1:0] active_voices;
   //logic [4:0] active_voices_idx [NUM_VOICES -1:0];

   //assign led = touch_status[23:8];
   

   address_generator address_generator_inst(.clk_in(clk_100mhz), 
                                           .rst_in(sys_rst), 
                                           .phase_in(phase_value),
                                           .gate_in(gate_value[23:0]),
                                           .addr_out(note_addr),
                                           .num_voices(num_voices),
                                           .active_voices(active_voices)
                                           //.active_voices_idx(active_voices_idx)
                                          );

    // logic [SINE_ADDR_WIDTH-1:0] note_addr_logic [NUM_NOTES - 1:0];// logicister the sine_note_addr for BRAM addressing

logic [SINE_ADDR_WIDTH-1:0] note_addr_logic [NUM_NOTES - 1:0];// logicister the sine_note_addr for BRAM addressing
    always_ff @(posedge clk_100mhz ) begin
    if (sys_rst) begin
        note_addr_logic[1] <= 0;
        note_addr_logic[2] <= 0;
        note_addr_logic[3] <= 0;
        note_addr_logic[0] <= 0;
        note_addr_logic[4] <= 0;
        note_addr_logic[5] <= 0;
        note_addr_logic[6] <= 0;
        note_addr_logic[7] <= 0;
        note_addr_logic[8] <= 0;
        note_addr_logic[9] <= 0;
        note_addr_logic[10] <= 0;
        note_addr_logic[11] <= 0;
        note_addr_logic[12] <= 0;
        note_addr_logic[13] <= 0;
        note_addr_logic[14] <= 0;
        note_addr_logic[15] <= 0;
        note_addr_logic[16] <= 0;
        note_addr_logic[17] <= 0;
        note_addr_logic[18] <= 0;
        note_addr_logic[19] <= 0;
        note_addr_logic[20] <= 0;
        note_addr_logic[21] <= 0;
        note_addr_logic[22] <= 0;
        note_addr_logic[23] <= 0;
 
    end else begin
        note_addr_logic[0] <= note_addr[0];
        note_addr_logic[1] <= note_addr[1];
        note_addr_logic[2] <= note_addr[2];
        note_addr_logic[3] <= note_addr[3];
        note_addr_logic[4] <= note_addr[4];
        note_addr_logic[5] <= note_addr[5];
        note_addr_logic[6] <= note_addr[6];
        note_addr_logic[7] <= note_addr[7];
        note_addr_logic[8] <= note_addr[8];
        note_addr_logic[9] <= note_addr[9];
        note_addr_logic[10] <= note_addr[10];
        note_addr_logic[11] <= note_addr[11];
        note_addr_logic[12] <= note_addr[12];
        note_addr_logic[13] <= note_addr[13];
        note_addr_logic[14] <= note_addr[14];
        note_addr_logic[15] <= note_addr[15];
        note_addr_logic[16] <= note_addr[16];
        note_addr_logic[17] <= note_addr[17];
        note_addr_logic[18] <= note_addr[18];
        note_addr_logic[19] <= note_addr[19];
        note_addr_logic[20] <= note_addr[20];
        note_addr_logic[21] <= note_addr[21];
        note_addr_logic[22] <= note_addr[22];
        note_addr_logic[23] <= note_addr[23];

    end
    end    
    // integer idx;

    // always_ff @(posedge clk_100mhz ) begin
    //     if (sys_rst) begin
    //         for (idx = 0; idx < NUM_NOTES; idx++) begin
    //             note_addr_logic[idx] <= 0;
    //         end
    //     end else begin
    //         for (idx = 0; idx < NUM_NOTES; idx++) begin        
    //             note_addr_logic[idx] <= note_addr[idx];     
    //         end
    //     end
    // end

///////////////////// SINE BRAMS /////////////////

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(SINE_BRAM_WIDTH),
      .RAM_DEPTH(SINE_BRAM_DEPTH),
      .INIT_FILE("../util/sine_wave_256_uint16.hex")) sine_audio_bram
      (
      // PORT A
      .addra(note_addr_logic[0]),
      .dina(0), // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0), // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta(spk_data_out[0]),
      // PORT B
      .addrb(note_addr_logic[1]),
      .dinb(0),
      .clkb(clk_100mhz),
      .web(1'b0),
      .enb(1'b1),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb(spk_data_out[1])
      );

    
xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sine_wave_256_uint16.hex")
) sine_audio_bram1 (
    // PORT A
    .addra(note_addr_logic[2]),
    .dina(0),
    .clka(clk_100mhz),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(sys_rst),
    .regcea(1'b1),
    .douta(spk_data_out[2]),
    // PORT B
    .addrb(note_addr_logic[3]),
    .dinb(0),
    .clkb(clk_100mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(spk_data_out[3])
);

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sine_wave_256_uint16.hex")
) sine_audio_bram2 (
    // PORT A
    .addra(note_addr_logic[4]),
    .dina(0),
    .clka(clk_100mhz),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(sys_rst),
    .regcea(1'b1),
    .douta(spk_data_out[4]),
    // PORT B
    .addrb(note_addr_logic[5]),
    .dinb(0),
    .clkb(clk_100mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(spk_data_out[5])
);

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sine_wave_256_uint16.hex")
) sine_audio_bram3 (
    // PORT A
    .addra(note_addr_logic[6]),
    .dina(0),
    .clka(clk_100mhz),
    .wea(1'b0),
    .ena(1'b1),
    .rsta(sys_rst),
    .regcea(1'b1),
    .douta(spk_data_out[6]),
    // PORT B
    .addrb(note_addr_logic[7]),
    .dinb(0),
    .clkb(clk_100mhz),
    .web(1'b0),
    .enb(1'b1),
    .rstb(sys_rst),
    .regceb(1'b1),
    .doutb(spk_data_out[7])
);

/////////////////////////////////////////////////////


//////////// SAWTOOTH BRAMS ////////////////////////////

localparam SAWTOOTH_ADDR_OFFSET = 8;

xilinx_true_dual_port_read_first_2_clock_ram
    #(.RAM_WIDTH(SINE_BRAM_WIDTH),
      .RAM_DEPTH(SINE_BRAM_DEPTH),
      .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram
      (
      // PORT A
      .addra(note_addr_logic[8]),
      .dina(0), // we only use port A for reads!
      .clka(clk_100mhz),
      .wea(1'b0), // read only
      .ena(1'b1),
      .rsta(sys_rst),
      .regcea(1'b1),
      .douta(spk_data_out[8]),
      // PORT B
      .addrb(note_addr_logic[9]),
      .dinb(0),
      .clkb(clk_100mhz),
      .web(1'b0),
      .enb(1'b1),
      .rstb(sys_rst),
      .regceb(1'b1),
      .doutb(spk_data_out[9])
      );

    
xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram1 (
        // PORT A
        .addra(note_addr_logic[10]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(spk_data_out[10]),
        // PORT B
        .addrb(note_addr_logic[11]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(spk_data_out[11])
    );

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram2 (
        // PORT A
        .addra(note_addr_logic[12]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(spk_data_out[12]),
        // PORT B
        .addrb(note_addr_logic[13]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(spk_data_out[13])
    );

xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(SINE_BRAM_WIDTH),
    .RAM_DEPTH(SINE_BRAM_DEPTH),
    .INIT_FILE("../util/sawtooth_wave_256_uint16.hex")
    ) sawtooth_audio_bram3 (
        // PORT A
        .addra(note_addr_logic[14]),
        .dina(0),
        .clka(clk_100mhz),
        .wea(1'b0),
        .ena(1'b1),
        .rsta(sys_rst),
        .regcea(1'b1),
        .douta(spk_data_out[14]),
        // PORT B
        .addrb(note_addr_logic[15]),
        .dinb(0),
        .clkb(clk_100mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(spk_data_out[15])
    );


/////////////////////////////////////////////////////////

////////////////////SQUARE BRAMS //////////////////////////

// localparam SQUARE_ADDR_OFFSET = 16;

// xilinx_true_dual_port_read_first_2_clock_ram
//     #(.RAM_WIDTH(SINE_BRAM_WIDTH),
//       .RAM_DEPTH(SINE_BRAM_DEPTH),
//       .INIT_FILE("../util/square_wave_256_uint16.hex")
//     ) square_audio_bram
//       (
//       // PORT A
//       .addra(note_addr_logic[16]),
//       .dina(0), // we only use port A for reads!
//       .clka(clk_100mhz),
//       .wea(1'b0), // read only
//       .ena(1'b1),
//       .rsta(sys_rst),
//       .regcea(1'b1),
//       .douta(spk_data_out[16]),
//       // PORT B
//       .addrb(note_addr_logic[17]),
//       .dinb(0),
//       .clkb(clk_100mhz),
//       .web(1'b0),
//       .enb(1'b1),
//       .rstb(sys_rst),
//       .regceb(1'b1),
//       .doutb(spk_data_out[17])
//       );
    
// xilinx_true_dual_port_read_first_2_clock_ram #(
//     .RAM_WIDTH(SINE_BRAM_WIDTH),
//     .RAM_DEPTH(SINE_BRAM_DEPTH),
//     .INIT_FILE("../util/square_wave_256_uint16.hex")
//     ) square_audio_bram1 (
//         // PORT A
//         .addra(note_addr_logic[18]),
//         .dina(0),
//         .clka(clk_100mhz),
//         .wea(1'b0),
//         .ena(1'b1),
//         .rsta(sys_rst),
//         .regcea(1'b1),
//         .douta(spk_data_out[18]),
//         // PORT B
//         .addrb(note_addr_logic[19]),
//         .dinb(0),
//         .clkb(clk_100mhz),
//         .web(1'b0),
//         .enb(1'b1),
//         .rstb(sys_rst),
//         .regceb(1'b1),
//         .doutb(spk_data_out[19])
//     );

// xilinx_true_dual_port_read_first_2_clock_ram #(
//     .RAM_WIDTH(SINE_BRAM_WIDTH),
//     .RAM_DEPTH(SINE_BRAM_DEPTH),
//     .INIT_FILE("../util/square_wave_256_uint16.hex")
//     ) square_audio_bram2 (
//         // PORT A
//         .addra(note_addr_logic[20]),
//         .dina(0),
//         .clka(clk_100mhz),
//         .wea(1'b0),
//         .ena(1'b1),
//         .rsta(sys_rst),
//         .regcea(1'b1),
//         .douta(spk_data_out[20]),
//         // PORT B
//         .addrb(note_addr_logic[21]),
//         .dinb(0),
//         .clkb(clk_100mhz),
//         .web(1'b0),
//         .enb(1'b1),
//         .rstb(sys_rst),
//         .regceb(1'b1),
//         .doutb(spk_data_out[21])
//     );

// xilinx_true_dual_port_read_first_2_clock_ram #(
//     .RAM_WIDTH(SINE_BRAM_WIDTH),
//     .RAM_DEPTH(SINE_BRAM_DEPTH),
//     .INIT_FILE("../util/square_wave_256_uint16.hex")
//     ) square_audio_bram3 (
//         // PORT A
//         .addra(note_addr_logic[22]),
//         .dina(0),
//         .clka(clk_100mhz),
//         .wea(1'b0),
//         .ena(1'b1),
//         .rsta(sys_rst),
//         .regcea(1'b1),
//         .douta(spk_data_out[22]),
//         // PORT B
//         .addrb(note_addr_logic[23]),
//         .dinb(0),
//         .clkb(clk_100mhz),
//         .web(1'b0),
//         .enb(1'b1),
//         .rstb(sys_rst),
//         .regceb(1'b1),
//         .doutb(spk_data_out[23])
//     );

//////////////////////////////////////////////////////////

logic [4:0] note_count;
logic [16:0] voice_values [0:23]; //change 32 back to 16

//integer v_idx;
    
//combine up to 8 notes with adsr envelope

// always_comb begin
//     note_count = 0;
//     for (int i = 0; i < NUM_NOTES; i++) note_count = active_voices[i] + note_count;
// end 

// always_ff @(posedge clk_100mhz)begin
//     for (v_idx = 0; v_idx < 8; v_idx = v_idx + 1) begin
//         if (active_voices_idx[v_idx] < 5'b11111) begin
//             voice_values[v_idx]  <= (spk_data_out[active_voices_idx[v_idx]] * adsr_envelope[v_idx]) >> 16;
//         end else begin
//             voice_values[v_idx] <= 0;
//         end
//     end
    
// end 

//combine up to 24 notes with adsr envelope
    always_comb begin
        note_count = 0;
        for (int i = 0; i < 24; i++) note_count = active_voices[i] + note_count;
    end 

    always_ff @(posedge clk_100mhz)begin
        

        if (active_voices[0]) begin
            voice_values[0] <= (spk_data_out[0] * adsr_envelope[0]) >> 16;
        end

        if (active_voices[1]) begin
            voice_values[1] <= (spk_data_out[1] * adsr_envelope[1]) >> 16;
        end 

        if (active_voices[2]) begin
            voice_values[2] <= (spk_data_out[2] * adsr_envelope[2]) >> 16;
        end 

        if (active_voices[3]) begin
            voice_values[3] <= (spk_data_out[3] * adsr_envelope[3]) >> 16;
        end 

        if (active_voices[4]) begin
            voice_values[4] <= (spk_data_out[4] * adsr_envelope[4]) >> 16;
        end 

        if (active_voices[5]) begin
            voice_values[5] <= (spk_data_out[5] * adsr_envelope[5]) >> 16;
        end 

        if (active_voices[6]) begin
            voice_values[6] <= (spk_data_out[6] * adsr_envelope[6]) >> 16;
        end 

        if (active_voices[7]) begin
            voice_values[7] <= (spk_data_out[7] * adsr_envelope[7]) >> 16;
        end 

        if (active_voices[8]) begin
            voice_values[8] <= (spk_data_out[8] * adsr_envelope[8]) >> 16;
        end 

        if (active_voices[9]) begin
            voice_values[9] <= (spk_data_out[9] * adsr_envelope[9]) >> 16;
        end 

        if (active_voices[10]) begin
            voice_values[10] <= (spk_data_out[10] * adsr_envelope[10]) >> 16;
        end 

        if (active_voices[11]) begin
            voice_values[11] <= (spk_data_out[11] * adsr_envelope[11]) >> 16;
        end 

        if (active_voices[12]) begin
            voice_values[12] <= (spk_data_out[12] * adsr_envelope[12]) >> 16;
        end 

        if (active_voices[13]) begin
            voice_values[13] <= (spk_data_out[13] * adsr_envelope[13]) >> 16;
        end 

        if (active_voices[14]) begin
            voice_values[14] <= (spk_data_out[14] * adsr_envelope[14]) >> 16;
        end 

        if (active_voices[15]) begin
            voice_values[15] <= (spk_data_out[15] * adsr_envelope[15]) >> 16;
        end 

        if (active_voices[16]) begin
            voice_values[16] <= (spk_data_out[16] * adsr_envelope[16]) >> 16;
        end 

        if (active_voices[17]) begin
            voice_values[17] <= (spk_data_out[17] * adsr_envelope[17]) >> 16;
        end 

        if (active_voices[18]) begin
            voice_values[18] <= (spk_data_out[18] * adsr_envelope[18]) >> 16;
        end 

        if (active_voices[19]) begin
            voice_values[19] <= (spk_data_out[19] * adsr_envelope[19]) >> 16;
        end 

        if (active_voices[20]) begin
            voice_values[20] <= (spk_data_out[20] * adsr_envelope[20]) >> 16;
        end 

        if (active_voices[21]) begin
            voice_values[21] <= (spk_data_out[21] * adsr_envelope[21]) >> 16;
        end 

        if (active_voices[22]) begin
            voice_values[22] <= (spk_data_out[22] * adsr_envelope[22]) >> 16;
        end

        if (active_voices[23]) begin
            voice_values[23] <= (spk_data_out[23] * adsr_envelope[23]) >> 16;
        end


    end



// handling 4 notes with adsr_envelope
logic [SINE_BRAM_WIDTH:0] average0, average1, average2, average3, average4, average5, average6, average7, average8, average9, average10, average11;
logic [SINE_BRAM_WIDTH-1:0] combined_sine_spk_data_out;

logic [PDM_WIDTH - 1:0] spk_data_out_shifted;
logic [32:0] modulated_combined_sine_data; // ADSR-modulated combined sine data --> change it back to 15 
logic [32:0] multiplied_sum; //change it back to 26 ? 
logic [32:0] sum; //change it back to 19

always_ff @(posedge clk_100mhz ) begin
    if (sys_rst) begin
        average0 <= 0;
        average1 <= 0;
        average2 <= 0;
        average3 <= 0;
        combined_sine_spk_data_out <= 0;

        modulated_combined_sine_data <= 0;
        spk_data_out_shifted <= 0;
    end else begin
        // Averaging Logic
        //sum all             
        //divide by number
        average0 <= voice_values[0] + voice_values[1]; 
        average1 <= voice_values[2] + voice_values[3];
        average2 <= voice_values[4] + voice_values[5];
        average3 <= voice_values[6] + voice_values[7];
        average4 <= voice_values[8] + voice_values[9];
        average5 <= voice_values[10] + voice_values[11];
        average6 <= voice_values[12] + voice_values[13];
        average7 <= voice_values[14] + voice_values[15];
        average8 <= voice_values[16] + voice_values[17];
        average9 <= voice_values[18] + voice_values[19];
        average10 <= voice_values[20] + voice_values[21];
        average11 <= voice_values[22] + voice_values[23];
        //this might cause issues - multiplying a lot of numbers - come back to it 
        sum <= (average0 + average1 + average2 + average3 + average4 + average5 + average6 + average7 + average8 + average9 + average10 + average11) ; //OVERFLOW ? how do I take the highest ?
        
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
            4'd8: multiplied_sum <= sum * 32;
            //this should be fine - if we try to play more than 8 it would output 0
            default: multiplied_sum <= 0;
        endcase

        combined_sine_spk_data_out <= multiplied_sum >> 8;


        // average0 <= (sine_spk_data_out[0] + sine_spk_data_out[1]) >> 1;
        // average1 <= (sine_spk_data_out[2] + sine_spk_data_out[3]) >> 1;
        // combined_sine_spk_data_out <= (average0 + average1) >> 1;
        
        // ADSR Modulation and PDM Data Preparation
        //temp <= adsr_envelope * (combined_sine_spk_data_out >>> 1);
        //modulated_combined_sine_data <= temp >>> 16;
        //spk_data_out_shifted <= modulated_combined_sine_data;

        spk_data_out_shifted <= combined_sine_spk_data_out;
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

//Sample Adress Counter
parameter OUD_BRAM_DEPTH  = 8192; // Number of samples per note
parameter OUD_ADDR_WIDTH  = 13; //$clog2(BRAM_DEPTH);  // Address width (13 bits for 8192 depth)
parameter OUD_BRAM_WIDTH = 16; // 16-bit sample width

logic [OUD_ADDR_WIDTH-1:0] sample_addr; // Current sample address


// sample_address_counter #(
// .BRAM_DEPTH(OUD_BRAM_DEPTH),
// .ADDR_WIDTH(OUD_ADDR_WIDTH)
// ) sample_address_counter_inst (
// .clk_in(clk_100mhz),
// .rst_in(sys_rst),
// .sample_tick(sample_tick),
// .led(led[12]),
// .gate_in(gate_value[7:0]),
// .sample_addr(sample_addr)
// );




// always_ff @( posedge clk_100mhz ) begin
//     touch_status <= sw[7:0];
// end


//PWM Module Instantiation
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
    .gate_in(gate_value[23:0]),
    .sig_out(spk_out)
);

//Connect PWM Output to Speakers
assign spkl = spk_out;
assign spkr = spk_out;

endmodule 

`default_nettype wire 
