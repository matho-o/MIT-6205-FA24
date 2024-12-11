module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/lixuan/Documents/Classes/FA24/6.205/final_project/sim_build/top_level.fst");
    $dumpvars(0, top_level);
end
endmodule
