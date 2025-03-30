module ps2(
input i_ps2_clk,
input i_ps2_data,
input i_clk,
input i_spa,
output o_cap,
output [7:0] o_dap
);

wire w_db_ps2_clk;
reg [7:0] r_input_data = 8'd1, r_saved_data = 8'b0;
reg r_ps2_clk_prev = 1'b0;
reg r_reciving = 1'b0;
reg [3:0] r_bit_cnt = 1'b0;
reg r_ready = 1'b0;
reg r_cap = 1'b0;

assign o_dap = r_saved_data;//{r_saved_data[0], r_saved_data[1], r_saved_data[2], r_saved_data[3], r_saved_data[4], r_saved_data[5], r_saved_data[6], r_saved_data[7]};
assign o_cap = r_cap;
debouncer db(.i_in(i_ps2_clk),.i_clk(i_clk),.o_out(w_db_ps2_clk));

always @(posedge i_clk) begin
  r_ps2_clk_prev <= w_db_ps2_clk;
  if (r_ps2_clk_prev == 1'b1 && w_db_ps2_clk == 1'b0) begin
    if (!r_reciving && !i_ps2_data && r_input_data[7]) begin
      r_reciving <= 1;
      r_bit_cnt <= 0;
    end
    else begin
      r_input_data <= {i_ps2_data,r_input_data[7:1]};
      if (r_bit_cnt == 4'd8 && r_reciving) begin
        r_saved_data <= r_input_data;
        r_ready <= 1'b1;
        r_reciving <= 1'b0;
      end
      else r_bit_cnt <= r_bit_cnt + 1'b1;
    end
  end
  if (r_ready == 1'b0) r_cap <= 1'b0;
  if (r_ready == 1'b1 && i_spa) begin
    r_cap <= 1'b1;
    r_ready <= 1'b0;
  end
end

endmodule
