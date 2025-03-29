module tb_sd_card_read;

  reg r_shift = 1'b0;

  reg r_clk = 1'b0;
  reg [31:0] r_addr = 32'b0;
  reg r_start_read = 1'b0;
  reg [7:0] r_accept_register = 8'hFF;

  wire [7:0] w_status;
  wire [7:0] w_data;
  wire [31:0] w_addr;
  wire w_wr_nrd;

  wire w_send_cmd;
  wire [2:0] w_cmd_select;
  wire [31:0] w_cmd_arg;
  wire w_confirm_pin;
  wire [7:0] w_response_status;
  wire [7:0] w_accept_register;
  wire w_read_done;

  reg [4128:0] r_podaci = {1'b1,8'b0, 8'hFE,
    {2048{1'b0}} , {2048{1'b1}},
    16'b0};
  wire w_CMD_OUTPUT;
  wire w_sd_response;
  assign w_sd_response = r_podaci[4128];

  sd_card_read scr(
    .i_clk(r_clk),
    .i_addr(r_addr),
    .i_accept_register(r_accept_register),
    .o_status(w_status),
    .o_data(w_data),
    .o_addr(w_addr),
    .o_wr_nrd(w_wr_nrd),
    .i_start_read(r_start_read),
    .o_read_done(w_read_done),

    .o_send_cmd(w_send_cmd),
    .o_cmd_select(w_cmd_select),
    .o_cmd_arg(w_cmd_arg),
    .i_confirm_pin(w_confirm_pin),
    .i_response_status(w_response_status)
  );

  sd_card_cmd scc(
    .i_clk(r_clk),
    .i_send_cmd(w_send_cmd),
    .i_cmd_select(w_cmd_select),
    .i_cmd_arg(w_cmd_arg),
    .io_sd_response(w_sd_response),
    .o_confirm_pin(w_confirm_pin),
    .o_CMD_OUTPUT(w_CMD_OUTPUT),
    .o_response_status(w_response_status)
  );

  mem_for_testing mft(.i_clk(r_clk), .i_data(w_data), .i_addr(w_addr), .i_write(w_wr_nrd));

  always #5 r_clk = ~r_clk;

  always @(posedge r_clk) begin
    r_accept_register <= {r_accept_register[6:0],w_sd_response};
    if (r_shift) r_podaci <= {r_podaci[4127:0], 1'b0};
    if (w_confirm_pin && !r_shift) r_shift <= 1'b1;
  end

  initial begin

    #55
    r_start_read <= 1'b1;
    #10
    r_start_read <= 1'b0;
    #1000000
    $finish;
  end

endmodule
