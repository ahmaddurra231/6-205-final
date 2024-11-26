module sample_rate_counter (
    input logic clk_in,
    input logic rst_in,
    output logic sample_tick
);
    parameter integer SAMPLE_RATE = 16384; //16ksps
    parameter integer CLK_FREQ = 100_000_000;
    parameter integer COUNT_MAX = CLK_FREQ / SAMPLE_RATE;

    logic [$clog2(COUNT_MAX)-1:0] count;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            count <= 0;
            sample_tick <= 0;
        end else if (count == COUNT_MAX - 1) begin
            count <= 0;
            sample_tick <= 1;
        end else begin
            count <= count + 1;
            sample_tick <= 0;
        end
    end
endmodule
