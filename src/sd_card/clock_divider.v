module clock_divider(
  input i_clk,
  output o_clk,
  input i_mode
);


localparam Clk_400KHz = 1'b0, Clk_12_5Mhz = 1'b1;

reg [7:0] r_counter_400KHz = 8'b0;
reg [7:0] r_counter_12_5MHz = 8'b0;
reg r_clk_out = 1'b0;

always @(i_clk) begin

  case (i_mode)

    Clk_400KHz: begin

      if (r_counter_400KHz == 8'd125) begin
        r_counter_400KHz <= 8'd1;
        r_clk_out = ~r_clk_out;
      end
      else r_counter_400KHz <= r_counter_400KHz + 1'b1;

    end

    Clk_12_5Mhz: begin

      if (r_counter_12_5MHz == 8'd3) begin
        r_counter_12_5MHz <= 8'd0;
        r_clk_out = ~r_clk_out;
      end
      else r_counter_12_5MHz <= r_counter_12_5MHz + 1'b1;

    end

  endcase
end


assign o_clk = r_clk_out;

endmodule
