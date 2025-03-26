module clock_divider(
  input i_clk,
  output o_clk,
  input i_mode
);


localparam Clk_400kh = 1'b0;

reg [7:0] r_counter_400kh = 8'b0;
reg r_clk_out = 1'b0;

always @(i_clk) begin
  case (i_mode)
    
    Clk_400kh: begin

      if(r_counter_400kh == 8'd125) begin
        r_counter_400kh <= 8'd1;
        r_clk_out = ~r_clk_out;
      end
      else r_counter_400kh <= r_counter_400kh + 1'b1;

    end

    Clk_
    
  endcase
end


assign o_clk = r_clk_out;

endmodule
