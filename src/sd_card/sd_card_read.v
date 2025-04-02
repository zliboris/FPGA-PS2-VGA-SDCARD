module sd_card_read(
  input i_clk,
  input [31:0] i_addr,
  input [7:0] i_accept_register,
  output [7:0] o_status,
  output [7:0] o_data,
  output [31:0] o_addr,
  output o_wr_nrd,

  //contol pins
  input i_start_read,
  output o_read_done,

  //cmd module io
  output o_send_cmd,
  output [2:0] o_cmd_select,
  output [31:0] o_cmd_arg,
  input i_confirm_pin,
  input [7:0] i_response_status
);

  //missing regs
  reg [7:0] r_statusreg = 8'b0;
  reg r_read_done = 8'b0;
  reg [7:0] r_data = 8'b0;
  reg [31:0] r_addr = 32'b0;
  reg r_wr_nrd = 1'b0;

  //Command send sub states
  reg [7:0] r_cmd_send_sub_state = 8'b0;
  localparam Cmd_send_select = 8'd0, Cmd_send_drive_pin = 8'd2, Cmd_send_confirm_wait = 8'd3, Cmd_send_response = 8'd4, Cmd_send_done = 8'd5, Cmd_send_error = 8'd6;

  //cmd module
  reg r_send_cmd = 1'b0;
  reg [2:0] r_cmd = 3'b0;
  reg [31:0] r_cmd_arg = 32'b0;
  localparam NO_CMD = 3'h0, CMD0 = 3'h1, CMD16 = 3'h2, CMD17 = 3'h3, CMD24 = 3'h4, CMD55 = 3'h5, CMD58 = 3'h6, CMD41 = 3'h7;
  localparam Rsp_no_rsp = 8'd0, Rsp_no_error = 8'd1, Rsp_idle_error = 8'd2, Rsp_Parameter_error = 8'd3, Rsp_address_error = 8'd4, Rsp_erase_sequence_error = 8'd5, Rsp_crc_error = 8'd6, Rsp_illegal_command = 8'd7, Rsp_erase_reset = 8'd8;

  // Temp registers
  reg [31:0] r_byte_counter = 32'd0;
  reg [7:0] r_shifting_one = 8'd0;

  // Error code
  reg [7:0] r_error_code = 8'd0;
  reg [7:0] r_error_save_register = 8'd0;
  reg [7:0] r_status = 8'd0;
  localparam R_error_card_locked = 8'd1, R_error_out_of_range = 8'd2, R_error_card_ECC_failed = 8'd3, R_error_card_controller_error = 8'd4, R_error_unspecified_error = 8'd5;

  // Read states
  reg [7:0] r_state = 8'd0;
  localparam Read_Idle = 8'd0, Read_CMD17_send = 8'd1, Read_data = 8'd2, Read_data_accept = 8'd3, Read_done = 8'd4, Read_status_done = 8'd5, Read_error = 8'hFF;

  // Read operation accept sub states
  reg [7:0] r_read_accept_state = 8'd0;

  assign o_status = r_status;
  assign o_data = r_data;
  assign o_addr = r_addr;
  assign o_wr_nrd = r_wr_nrd;
  assign o_send_cmd = r_send_cmd;
  assign o_cmd_arg = r_cmd_arg;
  assign o_cmd_select = r_cmd;
  assign o_read_done = r_read_done;

  always @(posedge i_clk) begin

    r_shifting_one <= {r_shifting_one[6:0], r_shifting_one[7]};

    case (r_state)

      Read_Idle: begin

        if (i_start_read) r_state <= Read_CMD17_send;

      end

      Read_CMD17_send: begin

        case (r_cmd_send_sub_state)

          Cmd_send_select: begin

            r_cmd <= CMD17; // Biranje komande za slanje
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
              r_shifting_one <= 8'h04;
              if (i_response_status == Rsp_no_error) r_cmd_send_sub_state <= Cmd_send_done;
              else begin
                r_error_code <= i_response_status;
                r_cmd_send_sub_state <= Cmd_send_error;
              end
            end

          end

          Cmd_send_error: begin

            r_cmd_send_sub_state <= Cmd_send_select;

            case (r_error_code) // Stanja posle gresaka pri slanju komande

              Rsp_idle_error: r_state <= Read_error;

              Rsp_erase_reset: r_state <= Read_error;

              Rsp_illegal_command: r_state <= Read_error;

              Rsp_crc_error: r_state <= Read_error;

              Rsp_erase_sequence_error: r_state <= Read_error;

              Rsp_address_error: r_state <= Read_error;

              Rsp_Parameter_error: r_state <= Read_error;

            endcase

          end

          Cmd_send_done: begin

            r_cmd_send_sub_state <= Cmd_send_select;
            r_state <= Read_data_accept; // Stanje posle poslate komande

          end

        endcase

      end

      Read_data_accept: begin

        case (r_read_accept_state)

          8'd0: begin

            if (r_shifting_one[7]) begin

              if (i_accept_register == 8'hFE) begin
                r_shifting_one <= 8'd0;
                r_read_accept_state <= 8'd1;
              end
              else if (i_accept_register[7] == 1'b0 && i_accept_register[6] == 1'b0 && i_accept_register[5] == 1'b0) begin 
                r_shifting_one <= 8'd0;
                r_error_save_register <= i_accept_register;
                r_read_accept_state <= 8'd29;
              end

            end

          end

          8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7: begin

            r_wr_nrd <= 1'b0;
            r_read_accept_state <= r_read_accept_state + 8'd1;

          end

          8'd8: begin

            r_data <= i_accept_register;
            r_addr <= r_byte_counter;
            r_wr_nrd <= 1'b1;

            if (r_byte_counter == 32'd511) begin
              r_byte_counter <= 32'd0;
              r_read_accept_state <= 8'd10;
            end

            else begin
              r_byte_counter <= r_byte_counter + 32'd1;
              r_read_accept_state <= 8'd1;
            end

          end

          8'd10: begin
            r_wr_nrd <= 1'b0;
            r_read_accept_state <= r_read_accept_state + 8'd1;
          end

          8'd11, 8'd12, 8'd13, 8'd14, 8'd15, 8'd16, 8'd17, 8'd18, 8'd19, 8'd20, 8'd21, 8'd22, 8'd23, 8'd24, 8'd25: r_read_accept_state <= r_read_accept_state + 8'd1; 

          8'd26: begin

            r_read_accept_state <= 8'd0;
            r_state <= Read_done;

          end

          8'd29: begin // Error

            r_error_code <= 8'd0;
            r_read_accept_state <= 8'd0;
            r_state <= Read_error;

            if (r_error_save_register[4]) r_error_code <= R_error_card_locked;

            else if (r_error_save_register[3]) r_error_code <= R_error_out_of_range;

            else if (r_error_save_register[2]) r_error_code <= R_error_card_ECC_failed;

            else if (r_error_save_register[1]) r_error_code <= R_error_card_controller_error;

            else if (r_error_save_register[0]) r_error_code <= R_error_unspecified_error;


          end

        endcase

      end

      Read_done: begin

        r_status <= 8'd1; // Kod za zavrseno citanje
        r_read_done <= 1'b1;
        r_state <= Read_status_done;

      end

      Read_status_done: begin

        r_read_done <= 1'b0;
        r_state <= Read_Idle;

      end

      Read_error: r_state <= Read_error;

    endcase

  end

endmodule
