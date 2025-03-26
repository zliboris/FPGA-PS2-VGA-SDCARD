module tb_gpu;

  reg CLK = 1'b0;
  reg [7:0] PD = 8'b0;

  wire hs,vs;
  wire [31:0] addr;
  wire [3:0] r,g,b;

  gpu test(.i_CLK(CLK),.i_PixelData(PD),.o_HS(hs),.o_VS(vs),.o_RdAddr(addr),.o_RED(r),.o_GREEN(g),.o_BLUE(b));

  initial begin
  #10000000 $finish;
  end

  always #5 CLK = ~CLK;
  
endmodule
