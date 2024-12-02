module i2c_controller(
  input logic clk_in,
  input logic rst_in,
  inout logic sda,
  input logic start,
  input logic [6:0] peripheral_addr_in,
  input logic rw, //write = 0, read = 1
  input logic [7:0] command_byte_in,
  input logic [7:0] data_byte_in,
  //input logic drive_low,
  output logic [7:0] data_byte_out,
  output logic ack_out,
  output logic scl_out, 
  output logic data_valid_out
);

logic sda_val;
//assign sda = sda_val? (drive_low? 0: 1'bz) : 1'b0;
assign sda = sda_val? 1'bz : 1'b0;

//generate clock
localparam integer CLK_IN_FREQ = 100_000_000;
localparam integer I2C_FREQ = 100_000;
localparam integer PERIOD = CLK_IN_FREQ / I2C_FREQ;
localparam integer HALF_PERIOD = PERIOD / 2;
localparam integer QUARTER_PERIOD = PERIOD / 4;
localparam integer HALF_PERIOD_WIDTH = $clog2(HALF_PERIOD);
localparam integer STOP_SETUP_CYCLES = 120;
localparam integer BUS_FREE_CYCLES = 1000;
logic [HALF_PERIOD_WIDTH-1:0] half_period_count;

localparam integer ADDR_BYTE = 3'b0;
localparam integer CMD_BYTE = 3'b1;
localparam integer DATA_BYTE = 3'b10;
localparam integer STOP_BYTE = 3'b11;
logic [1:0] prev_byte;

logic scl_toggle_en;//scl automatic toggle enabled when high, disabled when low
logic scl_overdrive;
logic scl_toggle;
logic scl_falling_edge;
logic scl_rising_edge;
logic scl_prev;


logic ack_in; //sda value when awaiting ack

logic [7:0] peripheral_addr_in_reg;
logic [7:0] data_byte_in_reg;
logic [7:0] command_byte_in_reg;
logic rw_reg;

logic [2:0] bit_count;
logic [9:0] stop_setup_count;

assign scl_out = scl_toggle_en? scl_toggle : scl_overdrive;
assign scl_falling_edge = scl_prev & ~scl_toggle;
assign scl_rising_edge = ~scl_prev & scl_toggle;


always_ff @(posedge clk_in) begin
  if (rst_in) begin
    scl_toggle <= 1'b1;
    half_period_count <= 0;
    scl_prev <= 1'b1;
  end else begin
    if (scl_toggle_en) begin
      scl_prev <= scl_toggle;
      if (state == START) begin
        scl_toggle <= 1'b1;
      end else begin
        if (half_period_count == HALF_PERIOD-1) begin
          scl_toggle <= ~scl_toggle;
          half_period_count <= 0;
        end else begin
          half_period_count <= half_period_count + 1;
        end
      end
    end else begin
      scl_toggle <= 1'b1;
      half_period_count <= 0;
    end
  end
end
//states
typedef enum logic [3:0] {
  IDLE,
  START,
  ADDR,
  AWAIT_ACK,
  READ_ACK,
  PROCESS_ACK,
  DATA,
  READ,
  STOP, 
  BUS_FREE_TIME
} state_t;

state_t state;
logic [3:0] current_state;
logic [3:0] retry_count;
assign current_state = state;

always_ff @(posedge clk_in) begin
  if (rst_in) begin
    state <= IDLE;
    sda_val <= 1'b1;
    ack_out <= 1'b0;
    data_valid_out <= 1'b0;
    scl_overdrive <= 1'b1;
    scl_toggle_en <= 1'b0;
    bit_count <= 0;
    retry_count <= 0;
  end else begin
    case(state)
      IDLE: begin
        scl_toggle_en <= 1'b0;
        scl_overdrive <= 1'b1;
        sda_val <= 1'b1;
        data_valid_out <= 1'b0;
        ack_out <= 1'b0;
        if (start) begin
          state <= START;
        end
      end
      START: begin
        
        ack_out <= 1'b0;
        if (prev_byte == CMD_BYTE) begin
          //repeated start
          peripheral_addr_in_reg[0] <= 1'b1;
        end else begin
          peripheral_addr_in_reg <= {peripheral_addr_in, 1'b0};
          rw_reg <= rw;
          data_byte_in_reg <= data_byte_in;
          command_byte_in_reg <= command_byte_in;
          ack_out <= 1'b0;
        end
        scl_toggle_en <= 1'b1;
        sda_val <= 1'b0;
        bit_count <= 7;
        state <= ADDR;
        
      
      end
      ADDR: begin
        //wait for first scl toggle to 0, then start sending data on falling edge. 
        //each bit of data stays on the line as long as scl is high
        if (scl_falling_edge) begin
          sda_val <= peripheral_addr_in_reg[bit_count];
          if (bit_count == 0) begin
            state <= AWAIT_ACK;
            prev_byte <= ADDR_BYTE;
          end else begin
            bit_count <= bit_count - 1;
          end
        end
      end
      AWAIT_ACK: begin
        //maintain sda upto next falling edge. then set to high impedence to read sda.
        if (scl_falling_edge) begin
          sda_val <= 1'b1;//sets sda_out to high impedence
          state <= READ_ACK;
        end
      end
      READ_ACK: begin
        //wait for scl to go high, then read sda over the clock cycles in the middle of the high period
        if (half_period_count == QUARTER_PERIOD && scl_out) begin
          ack_in <= sda;
          state <= PROCESS_ACK;
        end
      end
      PROCESS_ACK: begin
        if ((prev_byte == DATA_BYTE) && peripheral_addr_in_reg[0]) begin
          //read; end repeated start with a NACK. just need to keep sda high
          state <= STOP;
        end else begin
          if (!ack_in)begin
            //ack recieved
            if (rw_reg) begin
              if (prev_byte == CMD_BYTE) begin
                //read; repeated start
                if(scl_rising_edge) begin
                  state <= START;
                end
        
              end else if (peripheral_addr_in_reg[0]) begin
                state <= READ;
                sda_val <= 1'b1; // set to high impedence to read sda
              end else begin
                state <= DATA;
              end
              bit_count <= 7;
            end else begin
              if (prev_byte == DATA_BYTE) begin
                state <= STOP;
              end else begin
                state <= DATA;
                bit_count <= 7;
              end
            end
          end else begin
            //no ack recieved
            state <= STOP;
            retry_count <= retry_count + 1;
            ack_out <= 1'b1;
          end
        end
      end
      DATA: begin
        if (prev_byte == ADDR_BYTE) begin
          //command byte follows if write. data byte follows if read in repeated start phase(indicated by the rw bit of the addr byte)   
          if (scl_falling_edge) begin  
            sda_val <= command_byte_in_reg[bit_count];
            if (bit_count == 0) begin
              state <= AWAIT_ACK;
              prev_byte <= CMD_BYTE;
            end else begin
              bit_count <= bit_count - 1;
            end
          end
        end else if (prev_byte == CMD_BYTE) begin
          //data byte follows
          if (scl_falling_edge) begin
            sda_val <= data_byte_in_reg[bit_count];
            if (bit_count == 0) begin
              state <= AWAIT_ACK;
              prev_byte <= DATA_BYTE;
            end else begin
              bit_count <= bit_count - 1;
            end
          end
        end
      end
      READ: begin
        if (scl_rising_edge) begin
          data_byte_out[bit_count] <= sda;
          if (bit_count == 0) begin
            state <= AWAIT_ACK;
            prev_byte <= DATA_BYTE;
          end else begin
            bit_count <= bit_count - 1;
          end
        end
      end
      STOP: begin
        //ENSURE TBUF IS NOT VIOLATED
        //need 0.6 ms delay before sda is pulled back high. add delay of 60 cycles between scl rising and sda rising
        if (!scl_toggle_en) begin
          if (stop_setup_count == STOP_SETUP_CYCLES) begin
            sda_val <= 1'b1;
            state <= BUS_FREE_TIME;
            prev_byte <= STOP_BYTE;
            stop_setup_count <= 0;
          end else begin
            stop_setup_count <= stop_setup_count + 1;
          end 
        end else if (scl_falling_edge) begin
          sda_val <= 1'b0;
        end else if (scl_rising_edge) begin
          scl_toggle_en <= 1'b0;
          stop_setup_count <= 0;
        end
      end
      BUS_FREE_TIME: begin
        //wait for 1.3 ms before next start condition
        if (stop_setup_count == BUS_FREE_CYCLES) begin
          if (!ack_out) begin
            data_valid_out <= 1'b1;
            state <= IDLE;
            retry_count <= 0;
          end else begin
            //retry
            if (retry_count == 4'd10) begin
              state <= IDLE;
              retry_count <= 0;
              ack_out <= 1'b0;
            end else begin
              state <= START;
              retry_count <= retry_count + 1;
            end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
          end
          stop_setup_count <= 0;
        end else begin
          stop_setup_count <= stop_setup_count + 1;
          
        end
      end
    endcase 
  end
end
endmodule