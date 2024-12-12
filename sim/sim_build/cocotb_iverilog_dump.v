module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/ahmaddurra/6205/final_project/sim/sim_build/address_generator.fst");
    $dumpvars(0, address_generator);
end
endmodule
