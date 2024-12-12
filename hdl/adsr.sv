
// Amax  |    /\
//       |   /  \
//       |  /    \
// Asus  | /      ------------
//       |/                   \
//       ---------------------------
//        | attack
//             | decay
//                | sustain
//                            | release


module adsr #(
        parameter real CLK_FREQ       = 100_000_000.0, //110 MHz
        parameter real T_ATTACK_MS    =  1, //10,
        parameter real T_DECAY_MS     =  2 ,//50,
        parameter real T_SUSTAIN_MS   = 5, //200,
        parameter real T_RELEASE_MS   =  2, //50,
        parameter [31:0] A_MAX        = 32'h8000_0000, //32'h8000_0000, //50% of max amp
        parameter [31:0] A_SUS        = 32'h0800_0000//32'h4000_0000 //25% 
)(
        input logic clk_in,
        input logic rst_in,
        input logic hold,
        input logic start, // generate a pulse to start the envelope generation
        // input logic [31:0] attack_step_value, // precalculated (Amax - 0)/(t_attack - t_sys) steps for the attack segment
        // input logic [31:0] decay_step_value,  // precalculated (A_max-A_sus) / (t_decay / t_sys) steps for the decay segment
        // input logic [31:0] sustain_level, // amplitude for the sustain segment
        // input logic [31:0] release_step_value,  // precalculated (A_sus - 0)/(t_release - t_sys) steps fot the release segment
        // input logic [31:0] sustain_time, // tsustain / t_sys steps for the sustain
        output logic  [15:0] envelope,
        output logic adsr_idle

    );

    // Convert times to cycles - this will be changed to FPGA inputs to be modified by the user

    //convert to seconds
    localparam real T_ATTACK_S    = T_ATTACK_MS / 1000.0;
    localparam real T_DECAY_S     = T_DECAY_MS / 1000.0;
    localparam real T_SUSTAIN_S   = T_SUSTAIN_MS / 1000.0;
    localparam real T_RELEASE_S   = T_RELEASE_MS / 1000.0;


    localparam int ATTACK_CYCLES  = int'(T_ATTACK_S  * CLK_FREQ);
    localparam int DECAY_CYCLES   = int'(T_DECAY_S   * CLK_FREQ);
    localparam int SUSTAIN_CYCLES = int'(T_SUSTAIN_S * CLK_FREQ);
    localparam int RELEASE_CYCLES = int'(T_RELEASE_S * CLK_FREQ);

    localparam real A_MAX_f = 2147483648.0;  // decimal for 0x80000000
    localparam real A_SUS_f = 134217728.0;//8388608.0 ;//32768.0;  // decimal for 0x40000000

    localparam [31:0] ATTACK_STEP_VALUE  = (ATTACK_CYCLES  > 0) ? int'(A_MAX_f / ATTACK_CYCLES) : 32'h0;
    localparam [31:0] DECAY_STEP_VALUE   = (DECAY_CYCLES   > 0) ? int'((A_MAX_f - A_SUS_f) / DECAY_CYCLES) : 32'h0;
    localparam [31:0] SUSTAIN_LEVEL      = int'(A_SUS_f);
    localparam [31:0] RELEASE_STEP_VALUE = (RELEASE_CYCLES > 0) ? int'(A_SUS_f / RELEASE_CYCLES) : 32'h0;
    localparam [31:0] SUSTAIN_TIME       = int'(SUSTAIN_CYCLES);

    
    // constants
    localparam MAX = A_MAX; 
    localparam BYPASS = 32'hffff_ffff;
    localparam ZERO = 32'h0000_0000;
    
    // fsm state type
    typedef enum {idle, launch, attack, decay, sustain, rel} state_type;
    
    // declaration
    state_type state_reg;
    state_type state_next;
    logic [31:0] amplitude_counter_reg;
    logic [31:0] amplitude_counter_next;
    logic [31:0] sustain_time_reg;
    logic [31:0] sustain_time_next;
    logic [31:0] n_tmp;
    logic fsm_idle;
    logic [31:0] envelope_i;
    
    // state and data registers
    always_ff @(posedge clk_in)
    begin
        if(rst_in) 
          begin
            state_reg <= idle; //start from idle state
            amplitude_counter_reg <= 32'h0; //set amp counter to 0
            sustain_time_reg <= 32'h0; //set sustain time to 0
          end
         else
         begin
            state_reg <= state_next; //moce to next state
            amplitude_counter_reg <= amplitude_counter_next; //increment amp counter
            sustain_time_reg <= sustain_time_next; //increment sustain time
         end
    end
    
    // fsmd (fsm with data path ) next-state logic and data path logic
    always_comb
    begin
        state_next = state_reg;
        amplitude_counter_next = amplitude_counter_reg;
        sustain_time_next = sustain_time_reg;
        fsm_idle = 1'b0;      

        case (state_reg)  
            //IDLE STATE       
            idle: begin
                fsm_idle = 1'b1;
                if (start) begin
                    state_next = launch; //if you get start signal --> go to launch
                  end
              end

            //LAUNCH STATE
            launch: begin
                state_next = attack; //you start the attack
                amplitude_counter_next = 32'b0; //you reset amp counter
              end  

            //ATTACK STATE
            attack: begin
                if(start) begin
                    state_next = launch; //always go back to launch if start is high
                end 
                
                //adding to n_temp till it's equal MAX
                else begin
                    n_tmp = amplitude_counter_reg + ATTACK_STEP_VALUE;
                    if (n_tmp < MAX) begin
                        amplitude_counter_next = n_tmp;
                    end else begin
                        state_next = decay;
                    end
                end
              end
            
            //DECAY STEP
            decay: begin
                if (start) begin
                    state_next = launch;
                end 

                 
                
                //Decrementing from n_temp till it's equal to sustain_level
                else begin
                    n_tmp = amplitude_counter_reg - DECAY_STEP_VALUE;
                    if(n_tmp > SUSTAIN_LEVEL) begin
                        amplitude_counter_next = n_tmp;
                    end else begin
                        amplitude_counter_next = SUSTAIN_LEVEL;
                        state_next = sustain;
                        sustain_time_next = 32'b0;  // start timer for sustain
                    end
                end
              end  

            //SUSTAIN STEP            
            sustain: begin
                

                if (start) begin
                    state_next = launch;
                end 

                // if (hold) begin
                //     state_next = sustain;
                // end


                //keep incrementing sustain_time counter till it's equal to sustain_time
                else begin
                    if(sustain_time_reg < SUSTAIN_TIME) begin
                        sustain_time_next = sustain_time_next + 1;
                    end else begin
                        state_next = rel; //is this going to default ? 
                    end
                 end
              end

                           
             default: begin
                if (start) begin
                    state_next = launch;
                end 
                
                else begin
                    if(amplitude_counter_reg > RELEASE_STEP_VALUE) begin
                        amplitude_counter_next = amplitude_counter_reg - RELEASE_STEP_VALUE;
                    end else begin
                        state_next = idle;
                    end
                  end
               end    
        endcase

    end
    
    assign adsr_idle = fsm_idle;
    
    assign envelope_i = (ATTACK_STEP_VALUE == BYPASS) ? MAX :
                   (ATTACK_STEP_VALUE == ZERO) ? 32'b0 : 
                   amplitude_counter_reg;

    //assign envelope_i = MAX;
                   
   assign envelope = envelope_i[31:16];
endmodule