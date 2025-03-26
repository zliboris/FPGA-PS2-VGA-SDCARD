module tb_db;

reg r_clk = 1'b0;
reg r_signal = 1'b0;
wire w_db_signal;

debouncer db(
  .i_clk(r_clk),
  .i_in(r_signal),
  .o_out(w_db_signal)
  );

  always #5 r_clk = ~r_clk;

  initial begin
    repeat (100) #1 r_signal = $urandom % 2; 
    repeat (100) #1 r_signal = 1;
    repeat (100) #1 r_signal = $urandom % 2;
    repeat (100) #1 r_signal = 0;
    #10
    $finish;
  end

endmodule
