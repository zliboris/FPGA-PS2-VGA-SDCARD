module sd_card_init(
  input i_clk,
  output o_init_finished,

  //SD card CS pin
  output o_sd_cs,

  //cmd module io
  output o_send_cmd,
  output [2:0] o_cmd_select,
  output [31:0] o_cmd_arg,
  input i_confirm_pin,
  input [7:0] i_response_status
);

  //Init states
  reg [7:0] r_state = 8'd0;
  localparam Asertcs = 8'd0, Delay75 = 8'd1, Delay16 = 8'd2, CMD0_send = 8'd3, CMD55_send = 8'd4, CMD41_send = 8'd5, CMD58_send = 8'd6, Set_clk_max = 8'd7, Init_done = 8'd8, Ups = 8'hFF;

  reg r_init_finished = 1'b0;
  reg r_sd_cs = 1'b0;
  reg [7:0] r_delay_counter = 8'b0; 

  // Error handle
  reg [7:0] r_error_code = 8'd0;

  //Command send sub states
  reg [7:0] r_cmd_send_sub_state = 8'b0;
  localparam Cmd_send_select = 8'd0, Cmd_send_drive_pin = 8'd2, Cmd_send_confirm_wait = 8'd3, Cmd_send_response = 8'd4, Cmd_send_done = 8'd5, Cmd_send_error = 8'd6;

  // Komande i response
  reg [2:0] r_cmd = 3'b0;
  reg [31:0] r_cmd_arg = 32'b0;
  reg r_send_cmd = 1'b0;
  localparam NO_CMD = 3'h0, CMD0 = 3'h1, CMD16 = 3'h2, CMD17 = 3'h3, CMD24 = 3'h4, CMD55 = 3'h5, CMD58 = 3'h6, CMD41 = 3'h7;
  localparam Rsp_no_rsp = 8'd0, Rsp_no_error = 8'd1, Rsp_idle_error = 8'd2, Rsp_Parameter_error = 8'd3, Rsp_address_error = 8'd4, Rsp_erase_sequence_error = 8'd5, Rsp_crc_error = 8'd6, Rsp_illegal_command = 8'd7, Rsp_erase_reset = 8'd8;

  assign o_init_finished = r_init_finished;
  assign o_sd_cs = r_sd_cs;
  assign o_cmd_arg = r_cmd_arg;
  assign o_send_cmd = r_send_cmd;
  assign o_cmd_select = r_cmd;

  always @(posedge i_clk) begin

    case (r_state)

          Asertcs: begin

            r_sd_cs <= 1'b1;
            r_delay_counter <= 8'b0;
            r_state <= Delay75;

          end

          Delay75: begin

            if (r_delay_counter == 8'd75) begin
              r_delay_counter <= 8'b0;
              r_sd_cs <= 1'b0;
              r_state <= Delay16;
            end
            else r_delay_counter <= r_delay_counter + 8'd1;

          end

          Delay16: begin

            if (r_delay_counter == 8'd15) begin
              r_delay_counter <= 8'b0;
              r_state <= CMD0_send;
            end
            else r_delay_counter <= r_delay_counter + 8'd1;

          end

          CMD0_send: begin

            case (r_cmd_send_sub_state)

              Cmd_send_select: begin

                r_cmd <= CMD0; // Biranje komande za slanje
                r_cmd_arg <= 32'b0; // Biranje argumenta komande
                r_send_cmd <=  1'b1;
                r_cmd_send_sub_state <= Cmd_send_drive_pin;

              end

              Cmd_send_drive_pin: begin

                r_send_cmd <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_confirm_wait;

              end

              Cmd_send_confirm_wait: begin

                if (i_confirm_pin) begin
                  r_cmd <= NO_CMD;
                  r_cmd_send_sub_state <= Cmd_send_response;
                end

              end

              Cmd_send_response: begin

                if (i_confirm_pin) begin
                  if (i_response_status == Rsp_no_error) r_cmd_send_sub_state <= Cmd_send_done;
                  else begin
                    r_error_code <= i_response_status;
                    r_cmd_send_sub_state <= Cmd_send_error;
                  end
                end

              end

              Cmd_send_error: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;

                case (r_error_code)// Stanja posle gresaka pri slanju komande

                  Rsp_idle_error: r_state <= CMD55_send;

                  Rsp_erase_reset: r_state <= Ups;

                  Rsp_illegal_command: r_state <= Ups;

                  Rsp_crc_error: r_state <= Ups;

                  Rsp_erase_sequence_error: r_state <= Ups;

                  Rsp_address_error: r_state <= Ups;

                  Rsp_Parameter_error: r_state <= Ups;

                endcase

              end

              Cmd_send_done: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;
                r_state <= CMD55_send; // Stanje posle poslate komande

              end

            endcase

          end

          CMD55_send: begin

            case (r_cmd_send_sub_state)

              Cmd_send_select: begin

                r_sd_cs <= 1'b0;
                r_cmd <= CMD55; // Biranje komande za slanje
                r_cmd_arg <= 32'b0; // Biranje argumenta komande
                r_send_cmd <=  1'b1;
                r_cmd_send_sub_state <= Cmd_send_drive_pin;

              end

              Cmd_send_drive_pin: begin

                r_send_cmd <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_confirm_wait;

              end

              Cmd_send_confirm_wait: begin

                if (i_confirm_pin) begin
                  r_cmd <= NO_CMD;
                  r_cmd_send_sub_state <= Cmd_send_response;
                end

              end

              Cmd_send_response: begin

                if (i_confirm_pin) begin
                  if (i_response_status == Rsp_no_error) r_cmd_send_sub_state <= Cmd_send_done;
                  else begin
                    r_error_code <= i_response_status;
                    r_cmd_send_sub_state <= Cmd_send_error;
                  end
                end

              end

              Cmd_send_error: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;

                case (r_error_code)// Stanja posle gresaka pri slanju komande

                  Rsp_idle_error: r_state <= CMD41_send;

                  Rsp_erase_reset: r_state <= Ups;

                  Rsp_illegal_command: r_state <= Ups;

                  Rsp_crc_error: r_state <= Ups;

                  Rsp_erase_sequence_error: r_state <= Ups;

                  Rsp_address_error: r_state <= Ups;

                  Rsp_Parameter_error: r_state <= Ups;

                endcase

              end

              Cmd_send_done: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;
                r_state <= CMD41_send; // Stanje posle poslate komande

              end

            endcase

          end

          CMD41_send: begin

            case (r_cmd_send_sub_state)

              Cmd_send_select: begin

                r_sd_cs <= 1'b0;
                r_cmd <= CMD41; // Biranje komande za slanje
                r_cmd_arg <= 32'b0; // Biranje argumenta komande
                r_send_cmd <=  1'b1;
                r_cmd_send_sub_state <= Cmd_send_drive_pin;

              end

              Cmd_send_drive_pin: begin

                r_send_cmd <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_confirm_wait;

              end

              Cmd_send_confirm_wait: begin

                if (i_confirm_pin) begin
                  r_cmd <= NO_CMD;
                  r_cmd_send_sub_state <= Cmd_send_response;
                end

              end

              Cmd_send_response: begin

                if (i_confirm_pin) begin
                  if (i_response_status == Rsp_no_error) r_cmd_send_sub_state <= Cmd_send_done;
                  else begin
                    r_error_code <= i_response_status;
                    r_cmd_send_sub_state <= Cmd_send_error;
                  end
                end

              end

              Cmd_send_error: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;

                case (r_error_code)// Stanja posle gresaka pri slanju komande

                  Rsp_idle_error: r_state <= CMD55_send;

                  Rsp_erase_reset: r_state <= Ups;

                  Rsp_illegal_command: r_state <= Ups;

                  Rsp_crc_error: r_state <= Ups;

                  Rsp_erase_sequence_error: r_state <= Ups;

                  Rsp_address_error: r_state <= Ups;

                  Rsp_Parameter_error: r_state <= Ups;

                endcase

              end

              Cmd_send_done: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;
                r_state <= CMD58_send; // Stanje posle poslate komande

              end

            endcase

          end

          CMD58_send: begin

            case (r_cmd_send_sub_state)

              Cmd_send_select: begin

                r_sd_cs <= 1'b0;
                r_cmd <= CMD58; // Biranje komande za slanje
                r_cmd_arg <= 32'b0; // Biranje argumenta komande
                r_send_cmd <=  1'b1;
                r_cmd_send_sub_state <= Cmd_send_drive_pin;

              end

              Cmd_send_drive_pin: begin

                r_send_cmd <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_confirm_wait;

              end

              Cmd_send_confirm_wait: begin

                if (i_confirm_pin) begin
                  r_cmd <= NO_CMD;
                  r_cmd_send_sub_state <= Cmd_send_response;
                end

              end

              Cmd_send_response: begin

                if (i_confirm_pin) begin
                  if (i_response_status == Rsp_no_error) r_cmd_send_sub_state <= Cmd_send_done;
                  else begin
                    r_error_code <= i_response_status;
                    r_cmd_send_sub_state <= Cmd_send_error;
                  end
                end

              end

              Cmd_send_error: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;

                case (r_error_code)// Stanja posle gresaka pri slanju komande

                  Rsp_idle_error: r_state <= Ups;

                  Rsp_erase_reset: r_state <= Ups;

                  Rsp_illegal_command: r_state <= Ups;

                  Rsp_crc_error: r_state <= Ups;

                  Rsp_erase_sequence_error: r_state <= Ups;

                  Rsp_address_error: r_state <= Ups;

                  Rsp_Parameter_error: r_state <= Ups;

                endcase

              end

              Cmd_send_done: begin

                r_sd_cs <= 1'b1;
                r_cmd_send_sub_state <= Cmd_send_select;
                r_state <= Set_clk_max; // Stanje posle poslate komande

              end

            endcase

          end

          Set_clk_max: begin

            r_init_finished <= 1'b1;
            r_state <= Init_done;

          end

          Ups: begin

            r_state <= Ups;

          end

          Init_done: r_state <= Init_done;

    endcase

  end

endmodule
