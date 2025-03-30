module sd_card_write(
  input i_clk,
  input [31:0] i_addr,

  output [7:0] o_status,
  output [31:0] o_addr,
  output o_wr_nrd,
  input [7:0] i_data,
  input [7:0] i_accept_register,

  //sd output signals
  output o_cmd_line_select,
  output o_write_data_output,

  //sd input signal
  input i_sd_DO,

  //control pins
  input i_start_write,
  output o_write_done,

  //cmd module io
  output o_send_cmd,
  output [2:0] o_cmd_select,
  output [31:0] o_cmd_arg,
  input i_confirm_pin,
  input [7:0] i_response_status
);
  //States
  reg [7:0] r_state = 8'b0;
  localparam Write_Idle = 8'd0, Write_CMD24_send = 8'd1, Write_send_data = 8'd2, Write_busy_wait = 8'd3, Write_status_done = 8'd4, Write_Error = 8'hFF;

  //Registri za sd output signals
  reg r_cmd_line_select = 1'b0;
  reg [7:0] r_write_data_output = 8'b0;

  //Command send sub states
  reg [7:0] r_cmd_send_sub_state = 8'b0;
  localparam Cmd_send_select = 8'd0, Cmd_send_drive_pin = 8'd2, Cmd_send_confirm_wait = 8'd3, Cmd_send_response = 8'd4, Cmd_send_done = 8'd5, Cmd_send_error = 8'd6;

  // Komande i response
  reg [2:0] r_cmd = 3'b0;
  reg [31:0] r_cmd_arg = 32'b0;
  reg r_send_cmd = 1'b0;
  localparam NO_CMD = 3'h0, CMD0 = 3'h1, CMD16 = 3'h2, CMD17 = 3'h3, CMD24 = 3'h4, CMD55 = 3'h5, CMD58 = 3'h6, CMD41 = 3'h7;
  localparam Rsp_no_rsp = 8'd0, Rsp_no_error = 8'd1, Rsp_idle_error = 8'd2, Rsp_Parameter_error = 8'd3, Rsp_address_error = 8'd4, Rsp_erase_sequence_error = 8'd5, Rsp_crc_error = 8'd6, Rsp_illegal_command = 8'd7, Rsp_erase_reset = 8'd8;

  // Error code
  reg [7:0] r_error_code = 8'd0;
  reg [7:0] r_error_save_register = 8'd0;
  reg [7:0] r_status = 8'd0;
  localparam R_error_card_locked = 8'd1, R_error_out_of_range = 8'd2, R_error_card_ECC_failed = 8'd3, R_error_card_controller_error = 8'd4, R_error_unspecified_error = 8'd5;

  // Temp registers
  reg [31:0] r_byte_counter = 32'd0;
  reg [7:0] r_shifting_one = 8'd0;

  // IO registers
  reg [7:0] r_statusreg = 8'b0;
  reg r_write_done = 8'b0;
  reg [7:0] r_data = 8'b0;
  reg [31:0] r_addr = 32'b0;
  reg r_wr_nrd = 1'b0;

  // Status reg codes
  localparam Status_read_complete = 8'd1, Status_write_complete = 8'd2, Status_write_error = 8'd3;

  // Write operation send data sub states
  reg [7:0] r_write_send_data_state = 8'd0;
  reg [7:0] r_write_data_response_token = 8'd0;

  assign o_status = r_status;
  assign o_addr = r_addr;
  assign o_wr_nrd = r_wr_nrd;
  assign o_send_cmd = r_send_cmd;
  assign o_cmd_arg = r_cmd_arg;
  assign o_cmd_select = r_cmd;
  assign o_write_done = r_write_done;
  assign o_cmd_line_select = r_cmd_line_select;
  assign o_write_data_output = r_write_data_output[7];

  always @(posedge i_clk) begin

    if (r_cmd_line_select) r_write_data_output <= {r_write_data_output[6:0] , r_write_data_output[7]};
    r_shifting_one <= {r_shifting_one[6:0], r_shifting_one[7]};

    case (r_state)

      Write_Idle: begin

        if (i_start_write) r_state <= Write_CMD24_send;

      end

      Write_CMD24_send: begin

        case (r_cmd_send_sub_state)

          Cmd_send_select: begin

            r_cmd <= CMD24; // Biranje komande za slanje
            r_cmd_arg <= i_addr; // Biranje argumenta komande
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
              r_shifting_one <= 8'h02;
              if (i_response_status == Rsp_no_error) r_cmd_send_sub_state <= Cmd_send_done;
              else begin
                r_error_code <= i_response_status;
                r_cmd_send_sub_state <= Cmd_send_error;
              end
            end

          end

          Cmd_send_error: begin

            r_cmd_send_sub_state <= Cmd_send_select;

            case (r_error_code)// Stanja posle gresaka pri slanju komande

              Rsp_idle_error: r_state <= Write_Error;

              Rsp_erase_reset: r_state <= Write_Error;

              Rsp_illegal_command: r_state <= Write_Error;

              Rsp_crc_error: r_state <= Write_Error;

              Rsp_erase_sequence_error: r_state <= Write_Error;

              Rsp_address_error: r_state <= Write_Error;

              Rsp_Parameter_error: r_state <= Write_Error;

            endcase

          end

          Cmd_send_done: begin

            r_cmd_send_sub_state <= Cmd_send_select;
            r_state <= Write_send_data; // Stanje posle poslate komande

          end

        endcase

      end

      Write_send_data: begin

        case (r_write_send_data_state)

          8'd0: begin

            if (r_shifting_one[6]) begin
              r_cmd_line_select <= 1'b1;
              r_write_data_output <= 8'hFE;
              r_write_send_data_state <= 8'd1;
              r_byte_counter <= 32'd0;
            end

          end


          8'd1: begin

            if (r_shifting_one[5]) begin
              if (r_byte_counter == 32'd512) begin // end send
                r_byte_counter <= 32'd0;
                r_write_send_data_state <= 8'd2;
              end
              else begin
                r_addr <= r_byte_counter;
                r_byte_counter <= r_byte_counter + 32'd1;
              end
            end

            else if (r_shifting_one[6]) r_write_data_output <= i_data;

          end

          8'd2: begin

            r_write_data_output <= 8'hFF;
            r_write_send_data_state <= 8'd3;

          end

          8'd3: if (r_shifting_one[6]) r_write_send_data_state <= 8'd4;

          8'd4: if (r_shifting_one[6]) r_write_send_data_state <= 8'd5;

          8'd5: begin

            if (r_shifting_one[6]) begin
              r_write_data_response_token <= i_accept_register;
              r_shifting_one <= 8'd0;
              r_write_data_output <= 8'd0;
              r_cmd_line_select <= 1'b0;
              r_write_send_data_state <= 8'd6;
            end

          end

          8'd6: begin

            case (r_write_data_response_token[3:1])

              010: begin // Data was accepted

                r_write_send_data_state <= 8'd0;
                r_statusreg <= Status_write_complete;
                r_state <= Write_busy_wait;

              end

              101: begin // Data was rejected, CRC error (should never happened)

                r_write_send_data_state <= 8'd0;
                r_statusreg <= Status_write_error;
                r_state <= Write_busy_wait;

              end

              110: begin // Data was rejected, write error

                r_write_send_data_state <= 8'd0;
                r_statusreg <= Status_write_error;
                r_state <= Write_busy_wait;

              end

              default: begin

                r_write_send_data_state <= 8'd0;
                r_statusreg <= Status_write_error;
                r_state <= Write_busy_wait;

              end

            endcase

          end

        endcase

      end

      Write_busy_wait: begin

        if (i_sd_DO) begin
          r_write_done <= 1'b1;
          r_state <= Write_status_done;
        end

      end

      Write_status_done: begin

        r_write_done <= 1'b0;
        r_state <= Write_Idle;

      end

      Write_Error: r_state <= Write_Error;

    endcase

  end

endmodule
