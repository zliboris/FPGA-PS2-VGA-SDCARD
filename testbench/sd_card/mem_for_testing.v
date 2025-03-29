module mem_for_testing(
  input i_clk,
  input [7:0] i_data,
  input [31:0] i_addr,
  input i_write
);

  reg [7:0] memorija[0:512];

  always @(posedge i_clk) begin

    if (i_write) memorija[i_addr] <= i_data;

  end

endmodule
