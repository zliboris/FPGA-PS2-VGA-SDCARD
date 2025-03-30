module tb_ps2_mem;

reg r_ps2_clk = 1'b0;
reg r_clk = 1'b0;
reg [63:0] r_ps2_data_to_send = 64'hffffff5c79c3ae3f;
reg [31:0] r_addr = 1'b0;
reg r_req = 1'b0;
reg r_wren = 1'b0;
wire [7:0] w_out_data;
wire w_done;

ps2_mem kb_mem(.i_ps2_clk(r_ps2_clk),.i_ps2_data(r_ps2_data_to_send[0]),
  .i_clk(r_clk),.o_out(w_out_data),.i_addr(r_addr),.i_req(r_req),
  .i_wren(r_wren),.done(w_done));

always #5 r_clk = ~r_clk;

always begin
  #107 r_ps2_clk = ~r_ps2_clk;
end

always @(posedge r_ps2_clk) r_ps2_data_to_send <= {r_ps2_data_to_send[0],r_ps2_data_to_send[63:1]};


initial begin
  $monitor("moitor output: %h",w_out_data);
  #10
  r_req = 1'b1;
  #1
  r_req = 1'b0;
 #1000000
 $finish;
end

endmodule
