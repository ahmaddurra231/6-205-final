module counter(     input wire clk_in,
                    input wire rst_in,
                    input wire [31:0] period_in,
                    output logic [31:0] count_out
              );
  logic [32:0] count;
  always_comb begin
    count = rst_in ? 0:
            count_out == period_in - 1? 0: count_out +1;
  end
  always_ff @(posedge clk_in)begin
    count_out <= count[31:0];
  end

    
endmodule
