module tb_clk_div;

reg clk = 1'b0, mode = 1'b0;

wire clk_out;

clock_divider cd(.i_clk(clk),.o_clk(clk_out),.i_mode(mode));

always #5 clk = ~clk;

initial begin
#10000 $finish;
end

endmodule
