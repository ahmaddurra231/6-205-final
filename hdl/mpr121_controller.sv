module mpr121_controller(
  input logic clk_in,
  input logic rst_in,
  inout logic sda,
  output logic scl_out,
  output logic [11:0] touch_status_out,
  output logic [13:0] led,
  output logic valid_out
);
  logic start;
  logic [6:0] peripheral_addr_in;
  logic rw;
  logic [7:0] command_byte_in;
  logic [7:0] data_byte_in;
  logic [7:0] data_byte_out;
  logic ack_out;
  logic data_valid_out;
  logic [4:0] threshold_index;

  i2c_controller i2c_inst (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .sda(sda),
    .start(start),
    .peripheral_addr_in(peripheral_addr_in),
    .rw(rw),
    .command_byte_in(command_byte_in),
    .data_byte_in(data_byte_in),
    .data_byte_out(data_byte_out),
    .ack_out(ack_out),
    .scl_out(scl_out),
    .data_valid_out(data_valid_out)
  );
  typedef enum logic [4:0] {
    INIT_START,
    AWAIT_VALID_OUT,
    INIT_WRITE_THRESH,
    VERIFY_THRESH,
    VERIFY_THRESH_2,
    INIT_WRITE_ECR_ENABLE,
    VERIFY,
    VERIFY_2,
    VERIFY_ECR,
    VERIFY_ECR_2,
    START_READ_TOUCH_STATUS,
    READ_TOUCH_STATUS_FIRST_BYTE,
    START_READ_SECOND_BYTE,
    READ_TOUCH_STATUS_SECOND_BYTE, 
    STOP
  } state_t;

  state_t state;
  state_t next_state;
  logic [3:0] stop_byte; 
  assign led[7:0] = touch_status_out[7:0];

  assign peripheral_addr_in = 7'h5A; // MPR121 default I2C address
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      start <= 1'b0;
      rw <= 1'b0;
      command_byte_in <= 8'b0;
      data_byte_in <= 8'b0;
      touch_status_out <= 12'b0;
      valid_out <= 1'b0;
      state <= INIT_START;
    end else begin
      case (state)
        INIT_START: begin
          //write 0x00 to MPR121_ECR (0x5E) to stop MPR121
          start <= 1'b1;
          rw <= 1'b0; // Write operation
          command_byte_in <= 8'h5E; // MPR121_ECR register
          data_byte_in <= 8'h00; // Disable MPR121
          state <= AWAIT_VALID_OUT;
          next_state <= INIT_WRITE_THRESH;
          threshold_index <= 0;
        end
        AWAIT_VALID_OUT: begin
          start <= 1'b0;
          if (data_valid_out) begin
            state <= next_state;
          end
        end
        INIT_WRITE_THRESH: begin
          start <= 1'b1;
          rw <= 1'b0; // Write operation
          command_byte_in <= 8'h41 + threshold_index; // MPR121_E0FD register
          state <= AWAIT_VALID_OUT;
          if (threshold_index[0] == 1'b0) begin
            //even index. touch threshold
            data_byte_in <= 8'h0F; 
          end else begin
            //odd index. release threshold
            data_byte_in <= 8'h0A; 
          end
          if (threshold_index < 5'd24) begin
            threshold_index <= threshold_index + 1;
            next_state <= INIT_WRITE_THRESH;
          end else begin
            threshold_index <= 0;
            next_state <= INIT_WRITE_ECR_ENABLE;
          end    
        end
        VERIFY_THRESH: begin
          start <= 1'b1;
          rw <= 1'b1; // Read operation
          command_byte_in <= 8'h40 + threshold_index; // MPR121_E0FD register
          state <= AWAIT_VALID_OUT;
          next_state <= VERIFY_THRESH_2;
        end
        VERIFY_THRESH_2: begin
          if (data_byte_out == 8'h0F || data_byte_out == 8'h0A) begin
            
            state <= INIT_WRITE_THRESH;
          end else begin
            stop_byte <= 4'b0001;
            state <= STOP;
          end
        end
        INIT_WRITE_ECR_ENABLE: begin
          start <= 1'b1;
          rw <= 1'b0; // Write operation
          command_byte_in <= 8'h5E; // MPR121_ECR register
          data_byte_in <= 8'h0C; // Enable MPR121
          state <= AWAIT_VALID_OUT;
          next_state <= VERIFY;
        end
        VERIFY: begin
          start <= 1'b1;
          rw <= 1'b1; // Read operation
          command_byte_in <= 8'h5D; // MPR121_ECR register
          state <= AWAIT_VALID_OUT;
          next_state <= VERIFY_2;
        end
        VERIFY_2: begin
          if (data_byte_out == 8'h24) begin
            state <= VERIFY_ECR;
          end else begin
            state <= STOP;
            stop_byte <= 4'b0010;
          end
        end
        VERIFY_ECR: begin
          start <= 1'b1;
          rw <= 1'b1; // Read operation
          command_byte_in <= 8'h5E; // MPR121_ECR register
          state <= AWAIT_VALID_OUT;
          next_state <= VERIFY_ECR_2;
        end
        VERIFY_ECR_2: begin
          if (data_byte_out == 8'h0C) begin
            state <= START_READ_TOUCH_STATUS;
          end else begin
            state <= STOP;
            stop_byte <= 4'b0011;
          end
        end
        START_READ_TOUCH_STATUS: begin
          start <= 1'b1;
          rw <= 1'b1; // Read operation
          command_byte_in <= 8'h00; // MPR121_TOUCH_STATUS register
          state <= AWAIT_VALID_OUT;
          next_state <= READ_TOUCH_STATUS_FIRST_BYTE;
        end
        READ_TOUCH_STATUS_FIRST_BYTE: begin
          touch_status_out[7:0] <= data_byte_out;
          state <= START_READ_SECOND_BYTE;
        end
        START_READ_SECOND_BYTE: begin
          start <= 1'b1;
          rw <= 1'b1; // Read operation
          command_byte_in <= 8'h01; // MPR121_TOUCH_STATUS register
          state <= AWAIT_VALID_OUT;
          next_state <= READ_TOUCH_STATUS_SECOND_BYTE;
        end
        READ_TOUCH_STATUS_SECOND_BYTE: begin
          touch_status_out[11:8] <= data_byte_out[3:0];
          state <= START_READ_TOUCH_STATUS;
          valid_out <= 1'b1;
        end
        STOP: begin
          start <= 1'b0;
        end
        default: begin
        end 

      endcase
      
    end
  end

  
endmodule