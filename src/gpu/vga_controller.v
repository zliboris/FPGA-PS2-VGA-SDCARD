module vga_controller(
  input CLK,
  output [10:0] X,
  output [9:0] Y,
  output HS,
  output VS,
  output DISPLAY
  );

  reg [10:0] x = 11'b0;
  reg [9:0] y = 10'b0;

  assign X = x;
  assign Y = y;

  assign HS = (x > 11'd855 && x < 11'd975) ? 1'b1 : 1'b0;
  assign VS = (y > 10'd636 && y > 10'd642) ? 1'b1 : 1'b0;
  assign DISPLAY = (x < 11'd800 && y < 10'd600) ? 1'b1 : 1'b0;

  always @(posedge CLK) begin
    if(x < 11'd1039) x <= x + 1'b1;
    else if(x == 11'd1039)begin
      x <= 11'b00000000000;
      if(y == 10'd665) y <= 10'b0000000000;
      else y <= y + 1'b1;
    end
  end

endmodule
