module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/ahmaddurra/6205/final_project/sim/sim_build/i2c_controller.fst");
    $dumpvars(0, i2c_controller);
end
endmodule
