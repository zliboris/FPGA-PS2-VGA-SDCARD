module tb_sd_card_init;

  reg r_clk = 1'b0;

  wire w_mode;
  wire w_SD_CD;
  wire w_send_cmd;
  wire [2:0] w_cmd_select;
  wire [31:0] w_cmd_arg;
  wire w_confirm_pin;
  wire [7:0] w_response_status;
  wire w_CMD_OUTPUT;
  wire w_sd_response;

  sd_card_init sci(
  .i_clk(r_clk),
  .o_init_finished(w_mode),
  .o_sd_cs(w_SD_CD),

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

  always begin

    if(w_mode) #5;
    else #50;
    r_clk = ~r_clk;

  end


  always @(posedge r_clk) begin

  end

  initial begin

    #100000 $finish;

  end

endmodule
