//Added PWM_RESOLUTION parameter to make module easier to change
`timescale 1ns / 1ps
`default_nettype none

module pwm #(
    parameter integer PWM_RESOLUTION = 256 // Default 8-bit resolution
)(
    input wire clk_in,
    input wire rst_in,
    input wire [7:0] dc_in, 
    input wire [7:0] gate_in,
    output logic sig_out
);
     
    logic [31:0] count;
    
    // Instantiate the counter with PWM_RESOLUTION as period_in
    counter mc (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .period_in(PWM_RESOLUTION),
        .count_out(count)
    );
    
    // Generate PWM signal 
    assign sig_out = (|gate_in) && (count < dc_in);
    
endmodule

`default_nettype wire



