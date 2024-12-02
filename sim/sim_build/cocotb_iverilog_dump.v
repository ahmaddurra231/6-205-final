module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/ahmaddurra/6205/final_project/sim/sim_build/pdm.fst");
    $dumpvars(0, pdm);
end
endmodule
