module sd_card_controller(
  input i_clk,
  input [31:0] i_addr,
  input [7:0] i_controlreg,
  input [7:0] i_data,
  output [7:0] o_statusreg,
  output o_write_statusreg,
  output [7:0] o_data,
  output [31:0] o_addr,
  output o_wr_nrd,
  output o_req,

  //sd card io
  inout io_SD_DAT0_DO,
  inout io_SD_DAT3_nCS,
  inout io_SD_CMD_DI,
  output o_SD_CLK,
  input i_SD_WP_N
);

  //States
  reg [7:0] r_state = 8'd0;
  reg [7:0] r_sub_states = 8'd0;
  localparam Init = 8'b0, Idle = 8'h01, Read = 8'h02, Write = 8'h03; 

  //Control register
  localparam ctrlreg_no_operation = 8'd0, ctrlreg_read_operation = 8'd1, ctrlreg_write_operation = 8'd2;

  wire w_cmd_line_select;
  wire w_write_data_output;
  wire w_CMD_OUTPUT;

  wire w_send_cmd;
  wire w_send_cmd_Read;
  wire w_send_cmd_Write;
  wire w_send_cmd_Init;

  wire [7:0] w_response_status;

  wire [2:0] w_cmd_select;
  wire [2:0] w_cmd_select_Read;
  wire [2:0] w_cmd_select_Write;
  wire [2:0] w_cmd_select_Init;

  wire [31:0] w_cmd_arg;
  wire [31:0] w_cmd_arg_Read;
  wire [31:0] w_cmd_arg_Write;
  wire [31:0] w_cmd_arg_Init;

  wire [7:0] w_data_Read;
  
  wire [7:0] w_status_Read;
  wire [7:0] w_status_Write;

  wire [31:0] w_addr_Read;
  wire [31:0] w_addr_Write;

  wire w_wr_nrd;
  wire w_wr_nrd_Read;
  wire w_wr_nrd_Write;

  wire w_mode;
  wire w_SD_CD_init_module;

  assign o_req = 1'b1;
  assign w_send_cmd = (r_state == Init) ? w_send_cmd_Init :
                      (r_state == Read) ? w_send_cmd_Read :
                      (r_state == Write) ? w_send_cmd_Write :
                      1'b0;
  assign w_cmd_select = (r_state == Init) ? w_cmd_select_Init :
                        (r_state == Read) ? w_cmd_select_Read :
                        (r_state == Write) ? w_cmd_select_Write :
                        3'b0;
  assign w_cmd_arg = (r_state == Init) ? w_cmd_arg_Init :
                     (r_state == Read) ? w_cmd_arg_Read:
                     (r_state == Write) ? w_cmd_arg_Write :
                      32'b0;
  assign o_statusreg = (r_state == Read) ? w_status_Read :
                       (r_state == Write) ? w_status_Write :
                       8'b0;
  assign o_data = w_data_Read;
  assign o_addr = (r_state == Read) ? w_addr_Read :
                  (r_state == Write) ? w_addr_Write :
                  32'b0;
  assign o_wr_nrd = (r_state == Read) ? w_wr_nrd_Read :
                    (r_state == Write) ? w_wr_nrd_Write :
                    1'b0;

  reg r_drive_SD_DI = 1'b0;
  reg r_drive_SD_CS = 1'b0;
  wire w_SD_DI;
  wire w_SD_CS;

  assign io_SD_DAT0_DO = 1'bz;
  assign io_SD_CMD_DI = r_drive_SD_DI ? w_SD_DI : 1'bz;
  assign io_SD_DAT3_nCS = r_drive_SD_CS ? w_SD_CS : 1'bz;

  assign w_SD_DI = w_cmd_line_select ? w_write_data_output : w_CMD_OUTPUT;
  assign w_SD_CS = (r_state == Init) ? w_SD_CD_init_module : 1'b0;

  reg [7:0] r_accept_register = 8'd0;
  reg r_start_read = 1'b0;
  reg r_start_write = 1'b0;
  reg r_write_statusreg = 1'b0;
  
  assign o_write_statusreg = r_write_statusreg;

  clock_divider cd(.i_clk(i_clk),.o_clk(o_SD_CLK),.i_mode(w_mode));

  sd_card_init sci(
    .i_clk(o_SD_CLK),
    .o_init_finished(w_mode),
    .o_sd_cs(w_SD_CD_init_module),

    .o_send_cmd(w_send_cmd_Init),
    .o_cmd_select(w_cmd_select_Init),
    .o_cmd_arg(w_cmd_arg_Init),
    .i_confirm_pin(w_confirm_pin),
    .i_response_status(w_response_status)
  );

  sd_card_read scr(
    .i_clk(o_SD_CLK),
    .i_addr(i_addr),
    .i_accept_register(r_accept_register),
    .o_status(w_status_Read),
    .o_data(w_data_Read),
    .o_addr(w_addr_Read),
    .o_wr_nrd(w_wr_nrd_Read),
    .i_start_read(r_start_read),
    .o_read_done(w_read_done),

    .o_send_cmd(w_send_cmd_Read),
    .o_cmd_select(w_cmd_select_Read),
    .o_cmd_arg(w_cmd_arg_Read),
    .i_confirm_pin(w_confirm_pin),
    .i_response_status(w_response_status)
  );

  sd_card_write scw(
    .i_clk(o_SD_CLK),
    .i_addr(i_addr),
    .o_status(w_status_Write),
    .o_addr(w_addr_Write),
    .o_wr_nrd(w_wr_nrd_Write),
    .i_data(i_data),
    .i_accept_register(r_accept_register),
    .o_cmd_line_select(w_cmd_line_select),
    .o_write_data_output(w_write_data_output),
    .i_sd_DO(io_SD_DAT0_DO),
    .i_start_write(r_start_write),
    .o_write_done(w_write_done),

    .o_send_cmd(w_send_cmd_Write),
    .o_cmd_select(w_cmd_select_Write),
    .o_cmd_arg(w_cmd_arg_Write),
    .i_confirm_pin(w_confirm_pin),
    .i_response_status(w_response_status)
  );

  sd_card_cmd scc(
    .i_clk(o_SD_CLK),
    .i_send_cmd(w_send_cmd),
    .i_cmd_select(w_cmd_select),
    .i_cmd_arg(w_cmd_arg),
    .io_sd_response(io_SD_DAT0_DO),
    .o_confirm_pin(w_confirm_pin),
    .o_CMD_OUTPUT(w_CMD_OUTPUT),
    .o_response_status(w_response_status)
  );

  always @(posedge o_SD_CLK) begin

    r_accept_register <= { r_accept_register[6:0], io_SD_DAT0_DO };

    case (r_state)

      Init: begin

        r_drive_SD_CS <= 1'b1;
        r_drive_SD_DI <= 1'b1;
        if (w_mode) begin
          r_drive_SD_CS <= 1'b0;
          r_drive_SD_DI <= 1'b0;
          r_state <= Idle;
        end

      end

      Idle: begin

        if (i_controlreg == ctrlreg_read_operation) r_state <= Read;

        else if(i_controlreg == ctrlreg_write_operation) r_state <= Write;

      end

      Read: begin


        case (r_sub_states)

          8'd0: begin

            r_drive_SD_CS <= 1'b1;
            r_drive_SD_DI <= 1'b1;
            r_start_read <= 1'b1;
            r_sub_states <= r_sub_states + 8'd1;

          end

          8'd1: begin

            r_start_read <= 1'b0;
            if (w_read_done) begin
              r_write_statusreg <= 1'b1;
              r_sub_states <= r_sub_states + 8'd1;
            end

          end

          8'd2: begin

            r_drive_SD_CS <= 1'b0;
            r_drive_SD_DI <= 1'b0;
            r_write_statusreg <= 1'b0;
            r_sub_states <= 8'd0;
            r_state <= Idle;

          end

        endcase

      end

      Write: begin

        case (r_sub_states)

          8'd0: begin

            r_drive_SD_CS <= 1'b1;
            r_drive_SD_DI <= 1'b1;
            r_start_write <= 1'b1;
            r_sub_states <= r_sub_states + 8'd1;

          end

          8'd1: begin

            r_start_write <= 1'b0;
            if (w_write_done) begin
              r_write_statusreg <= 1'b1;
              r_sub_states <= r_sub_states + 8'd1;
            end

          end

          8'd2: begin

            r_drive_SD_CS <= 1'b0;
            r_drive_SD_DI <= 1'b0;
            r_write_statusreg <= 1'b0;
            r_sub_states <= 8'd0;
            r_state <= Idle;

          end

        endcase

      end

    endcase

  end

endmodule
