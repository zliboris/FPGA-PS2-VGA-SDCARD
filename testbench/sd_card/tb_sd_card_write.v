module tb_sd_card_write;

  reg r_clk = 1'b0;
  reg [31:0] r_addr = 32'b0;
  reg r_start_write = 1'b0;
  reg [7:0] r_accept_register = 8'hFF;
  reg r_shift = 1'b0;

  wire [7:0] w_status;
  wire [31:0] w_addr;
  wire w_wr_nrd;

  wire w_send_cmd;
  wire [2:0] w_cmd_select;
  wire [31:0] w_cmd_arg;
  wire w_confirm_pin;
  wire [7:0] w_response_status;
  wire [7:0] w_mem_out;
  wire [7:0] w_data;
  wire w_write_data_output;
  wire w_write_done;

  reg [4184:0] r_podaci = {1'b1,8'b0,{516{8'hFF}},8'b00000101,{20{1'b0}},{20{1'b1}}};
  wire w_CMD_OUTPUT;
  wire w_sd_response;
  assign w_sd_response = r_podaci[4184];

  sd_card_write scw(
  .i_clk(r_clk),
  .i_addr(r_addr),
  .o_status(w_status),
  .o_addr(w_addr),
  .o_wr_nrd(w_wr_nrd),
  .i_data(w_mem_out),
  .i_accept_register(r_accept_register),
  .o_cmd_line_select(w_cmd_line_select),
  .o_write_data_output(w_write_data_output),
  .i_sd_DO(w_sd_response),
  .i_start_write(r_start_write),
  .o_write_done(w_write_done),
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

  mem_for_testing mft(.i_clk(r_clk), .i_data(w_data), .i_addr(w_addr), .i_write(w_wr_nrd), .o_data(w_mem_out));

  always #5 r_clk = ~r_clk;

  always @(posedge r_clk) begin

    r_accept_register <= {r_accept_register[6:0],w_sd_response};
    if (r_shift) r_podaci <= {r_podaci[4183:0], 1'b0};
    if (w_confirm_pin || w_write_done) r_shift <= 1'b1;

  end

  initial begin
    #55
    r_start_write <= 1'b1;
    #10
    r_start_write <= 1'b0;
    #1000000
    $finish;
  end

endmodule
