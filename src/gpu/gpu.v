module gpu (
  input i_CLK,
  input [7:0] i_PixelData,
  output o_HS,
  output o_VS,
  output [31:0] o_RdAddr,
  output [3:0] o_RED,
  output [3:0] o_GREEN,
  output [3:0] o_BLUE
);

  wire w_DISPLAY;

assign o_RED = w_DISPLAY ? {i_PixelData[2:0],1'b1} : 4'b0;
assign o_GREEN = w_DISPLAY ? {i_PixelData[5:3],1'b1} : 4'b0;
assign o_BLUE = w_DISPLAY ? {i_PixelData[7:6],1'b1,1'b0} : 4'b0;

wire [10:0] w_x;
wire [9:0] w_y;

vga_controller vc(.CLK(i_CLK),.X(w_x),.Y(w_y),.HS(o_HS),.VS(o_VS),.DISPLAY(w_DISPLAY));

  integer in_pixel_horizontal_count = 0, vertical_count = 0, horizontal_count = 0;
  reg [31:0] addr = 32'b0;
  assign o_RdAddr = addr;


  always @(posedge i_CLK) begin
    if (w_DISPLAY) begin
      
      in_pixel_horizontal_count = in_pixel_horizontal_count + 1;

      if (in_pixel_horizontal_count > 4) begin

        in_pixel_horizontal_count = 0;
        addr = addr + 1;
        horizontal_count = horizontal_count + 1;

        if (horizontal_count > 159) begin

          horizontal_count = 0;
          vertical_count = vertical_count + 1;

          if (vertical_count > 5)  vertical_count = 0;

          else addr = addr - 160;

        end
      end
    end
    if(o_VS)begin
      addr <= 32'b0;
      in_pixel_horizontal_count = 0;
      vertical_count = 0;
      horizontal_count = 0;
    end
  end


endmodule
