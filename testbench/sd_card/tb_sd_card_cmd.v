module tb_sd_card_cmd;

  reg r_clk = 1'b0;
  reg r_send_cmd = 1'b0;
  reg [2:0] r_cmd_select = 3'b0;
  reg [31:0] r_cmd_arg = 32'd12344;
  reg r_sd_response = 1'bz;
 
  wire w_cmd_done;
  wire w_CMD_OUTPUT;
  wire [7:0] w_response_status;
  wire w_sd_response_pin;

  localparam NO_CMD = 3'h0, CMD0 = 3'h1, CMD16 = 3'h2, CMD17 = 3'h3, CMD24 = 3'h4, CMD55 = 3'h5, CMD58 = 3'h6, CMD41 = 3'h7;
 
  sd_card_cmd scc(.i_clk(r_clk),.i_send_cmd(r_send_cmd),.i_cmd_select(r_cmd_select),.i_cmd_arg(r_cmd_arg),.io_sd_response(w_sd_response_pin),.o_cmd_done(w_cmd_done),.o_CMD_OUTPUT(w_CMD_OUTPUT),.o_response_status(w_response_status));

  assign w_sd_response_pin = r_sd_response;

  always #5 r_clk <= ~r_clk;

  initial begin
    r_sd_response = 1'bz;
    r_cmd_select <= CMD0;
    #20
    r_send_cmd <= 1'b1;
    #10
    r_send_cmd <= 1'b0;
    #1000
    r_sd_response <= 1'b0;
    #10
    r_sd_response <= 1'b0;
    #10
    r_sd_response <= 1'b0;
    #10
    r_sd_response <= 1'b1;
    #10
    r_sd_response <= 1'b0;
    #10
    r_sd_response <= 1'b0;
    #10
    r_sd_response <= 1'b0;
    #10
    r_sd_response <= 1'b0;
    #10
    r_sd_response <= 1'bz;
    #1000
    r_cmd_select <= CMD16;
    #20
    r_send_cmd <= 1'b1;
    #10
    r_send_cmd <= 1'b0;
    #5000
    r_cmd_select <= CMD17;
    #20
    r_send_cmd <= 1'b1;
    #10
    r_send_cmd <= 1'b0;
    #5000
    r_cmd_select <= CMD24;
    #20
    r_send_cmd <= 1'b1;
    #10
    r_send_cmd <= 1'b0;
    #5000
    r_cmd_select <= CMD55;
    #20
    r_send_cmd <= 1'b1;
    #10
    r_send_cmd <= 1'b0;
    #5000
    r_cmd_select <= CMD58;
    #20
    r_send_cmd <= 1'b1;
    #10
    r_send_cmd <= 1'b0;
    #5000
    r_cmd_select <= CMD41;
    #20
    r_send_cmd <= 1'b1;
    #10
    r_send_cmd <= 1'b0;
    #5000
    $finish;
  end

endmodule
