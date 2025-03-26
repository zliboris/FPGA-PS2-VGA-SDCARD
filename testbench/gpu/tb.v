module tb;
  
  reg CLK = 0;
  wire [10:0] x;
  wire [9:0] y;
  wire HS, VS, DISPLAY;
  
  vga_controler vc(.CLK(CLK),.X(x), .Y(y) , .HS(HS) , .VS(VS), .DISPLAY(DISPLAY));
  
  
  initial begin
	  $monitor("x : %d, y : %d, HS : %b, VS : %b, DISPLAY : %b",x,y,HS,VS,DISPLAY);
    #1000000 $finish;
    
  end
  
  always begin
    #5 CLK = ~CLK;
  end
  
endmodule;
