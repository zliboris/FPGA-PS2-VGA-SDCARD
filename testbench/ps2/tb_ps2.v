module tb_ps2;

reg r_ps2_clk = 1'b0;
reg r_clk = 1'b0;
reg [63:0] r_ps2_data_to_send = 64'hffffff5c79c3ae3f;
wire w_cap;
wire [7:0] w_out_data;

ps2 tastatura(.i_ps2_clk(r_ps2_clk),.i_ps2_data(r_ps2_data_to_send[0]),.i_clk(r_clk),.i_spa(1'b1),.o_cap(w_cap),.o_dap(w_out_data));

always #2 r_clk = ~r_clk;

always begin
  #40 r_ps2_clk = ~r_ps2_clk;
end

always @(negedge r_ps2_clk) r_ps2_data_to_send <= {r_ps2_data_to_send[0],r_ps2_data_to_send[63:1]};

always @(posedge w_cap) $display("display output: %h",w_out_data);

initial begin
  $monitor("moitor output: %h",w_out_data);
 #10000
 $finish;
end

endmodule
