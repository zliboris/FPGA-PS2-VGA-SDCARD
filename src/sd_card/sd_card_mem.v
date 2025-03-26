module sd_card_mem(
  input i_clk,
  input [31:0] i_addr,
  input [7:0] i_controlreg,
  input [7:0] i_data,
  output [7:0] o_statusreg,
  output o_write_status,
  output [7:0] o_data,
  output [8:0] o_addr,
  output o_wr_nrd,

  //sd card io
  inout io_SD_DAT0_DO,
  inout io_SD_DAT3_nCS,
  inout io_SD_CMD_DI,
  output o_SD_CLK,
  input i_SD_WP_N
);


//reg r_drive_SD_DAT0 = 1'b0;
reg r_drive_SD_DAT3 = 1'b0;
reg r_drive_SD_CMD = 1'b0;
reg r_mode = 1'b0;
reg r_sd_cs = 1'b0;
reg [7:0] r_delay_counter = 8'b0; 
reg [31:0] r_cmd_arg = 32'b0;

wire w_confirm_pin;
wire w_CMD_LINE;
wire w_response_status;

clock_divider cd(.i_clk(i_clk),.o_clk(o_SD_CLK),.i_mode(r_mode));
sd_card_cmd sd_cmd(.i_clk(o_SD_CLK),.i_send_cmd(r_send_cmd),.i_cmd_select(r_cmd),.i_cmd_arg(r_cmd_arg),.io_sd_response(io_SD_DAT0_DO),.o_confirm_pin(w_confirm_pin),.o_CMD_OUTPUT(w_CMD_LINE),.o_response_status(w_response_status));

assign io_SD_DAT3_nCS = r_drive_SD_DAT3 ? r_sd_cs : 1'bz;
assign io_SD_CMD_DI = r_drive_SD_CMD ? w_CMD_LINE : 1'bz;
assign io_SD_DAT0_DO = 1'bz; // ovo samo ako treba da
//se posalje nesto na dat0 liniju

// Stanja sd kartice
reg [7:0] r_state = 8'b0;
localparam Init = 8'b0, Idle = 8'h01; 

// Pod stanja prilikom inicijalizacije
reg [7:0] r_init_sub_state = 8'b0;
localparam Asertcs = 8'd0, Delay75 = 8'd1, Delay16 = 8'd2, CMD0_send = 8'd3, CMD55_send = 8'd4, CMD41_send = 8'd5, CMD58_send = 8'd6, Set_clk_max = 8'd7, Ups = 8'hFF;

// Komande i response
reg [2:0] r_cmd = 3'b0;
reg r_send_cmd = 1'b0;
localparam NO_CMD = 3'h0, CMD0 = 3'h1, CMD16 = 3'h2, CMD17 = 3'h3, CMD24 = 3'h4, CMD55 = 3'h5, CMD58 = 3'h6, CMD41 = 3'h7;
localparam No_rsp = 8'd0, No_error = 8'd1, Idle_error = 8'd2, Bad_error = 8'd3;

//Command send sub states
reg [7:0] r_cmd_send_sub_state = 8'b0;
localparam Cmd_send_select = 8'd0, Cmd_send_drive_pin = 8'd2, Cmd_send_confirm_wait = 8'd3, Cmd_send_response = 8'd4, Cmd_send_done = 8'd5, Cmd_send_default_err = 8'd6, Cmd_send_Idle_err = 8'd7;


always @(posedge o_SD_CLK) begin

  case(r_state)

    Init: begin

      case (r_init_sub_state)

        Asertcs: begin

          r_drive_SD_DAT3 <= 1'b1;
          r_mode <= 1'b0;
          r_sd_cs <= 1'b1;
          r_delay_counter <= 8'b0;
          r_init_sub_state <= Delay75;

        end

        Delay75: begin

          if (r_delay_counter == 8'd75) begin
            r_delay_counter <= 8'b0;
            r_sd_cs <= 1'b0;
            r_init_sub_state <= Delay16;
          end
          else r_delay_counter <= r_delay_counter + 8'd1;

        end

        Delay16: begin

          if (r_delay_counter == 8'd15) begin
            r_delay_counter <= 8'b0;
            r_init_sub_state <= CMD0_send;
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

              r_drive_SD_CMD <= 1'b1;
              r_send_cmd <= 1'b0;
              r_cmd_send_sub_state <= Cmd_send_confirm_wait;

            end

            Cmd_send_confirm_wait: begin

              if (w_confirm_pin) begin
                r_cmd <= NO_CMD;
                r_drive_SD_CMD <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_response;
              end

            end

            Cmd_send_response: begin

              if (w_confirm_pin) begin
                case (w_response_status)
                  No_error: r_cmd_send_sub_state <= Cmd_send_done;
                  default: r_cmd_send_sub_state <= Cmd_send_default_err;
                endcase
              end

            end

            Cmd_send_done: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= CMD55_send; // Stanje posle poslate komande

            end

            Cmd_send_default_err: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= Ups; // Stanje posle default gresle posle poslate komande

            end

          endcase

        end

        CMD55_send: begin

          case (r_cmd_send_sub_state)

            Cmd_send_select: begin

              r_cmd <= CMD55; // Biranje komande za slanje
              r_cmd_arg <= 32'b0; // Biranje argumenta komande
              r_send_cmd <=  1'b1;
              r_cmd_send_sub_state <= Cmd_send_drive_pin;

            end

            Cmd_send_drive_pin: begin

              r_drive_SD_CMD <= 1'b1;
              r_send_cmd <= 1'b0;
              r_cmd_send_sub_state <= Cmd_send_confirm_wait;

            end

            Cmd_send_confirm_wait: begin

              if (w_confirm_pin) begin
                r_cmd <= NO_CMD;
                r_drive_SD_CMD <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_response;
              end

            end

            Cmd_send_response: begin

              if (w_confirm_pin) begin
                case (w_response_status)
                  No_error: r_cmd_send_sub_state <= Cmd_send_done;
                  default: r_cmd_send_sub_state <= Cmd_send_default_err;
                endcase
              end

            end

            Cmd_send_done: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= CMD41_send; // Stanje posle poslate komande

            end

            Cmd_send_default_err: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= Ups; // Stanje posle default gresle posle poslate komande

            end

          endcase

        end

        CMD41_send: begin

          case (r_cmd_send_sub_state)

            Cmd_send_select: begin

              r_cmd <= CMD41; // Biranje komande za slanje
              r_cmd_arg <= 32'b0; // Biranje argumenta komande
              r_send_cmd <=  1'b1;
              r_cmd_send_sub_state <= Cmd_send_drive_pin;

            end

            Cmd_send_drive_pin: begin

              r_drive_SD_CMD <= 1'b1;
              r_send_cmd <= 1'b0;
              r_cmd_send_sub_state <= Cmd_send_confirm_wait;

            end

            Cmd_send_confirm_wait: begin

              if (w_confirm_pin) begin
                r_cmd <= NO_CMD;
                r_drive_SD_CMD <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_response;
              end

            end

            Cmd_send_response: begin

              if (w_confirm_pin) begin
                case (w_response_status)
                  No_error: r_cmd_send_sub_state <= Cmd_send_done;
                  Idle_error: r_cmd_send_sub_state <= Cmd_send_Idle_err;
                  default: r_cmd_send_sub_state <= Cmd_send_default_err;
                endcase
              end

            end

            Cmd_send_done: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= CMD58_send; // Stanje posle poslate komande

            end

            Cmd_send_Idle_err: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= CMD55_send; // Stanje posle Idle greske

            end

            Cmd_send_default_err: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= Ups; // Stanje posle default gresle posle poslate komande

            end

          endcase

        end

        CMD58_send: begin

          case (r_cmd_send_sub_state)

            Cmd_send_select: begin

              r_cmd <= CMD58; // Biranje komande za slanje
              r_cmd_arg <= 32'b0; // Biranje argumenta komande
              r_send_cmd <=  1'b1;
              r_cmd_send_sub_state <= Cmd_send_drive_pin;

            end

            Cmd_send_drive_pin: begin

              r_drive_SD_CMD <= 1'b1;
              r_send_cmd <= 1'b0;
              r_cmd_send_sub_state <= Cmd_send_confirm_wait;

            end

            Cmd_send_confirm_wait: begin

              if (w_confirm_pin) begin
                r_cmd <= NO_CMD;
                r_drive_SD_CMD <= 1'b0;
                r_cmd_send_sub_state <= Cmd_send_response;
              end

            end

            Cmd_send_response: begin

              if (w_confirm_pin) begin
                case (w_response_status)
                  No_error: r_cmd_send_sub_state <= Cmd_send_done;
                  Idle_error: r_cmd_send_sub_state <= Cmd_send_Idle_err;
                  default: r_cmd_send_sub_state <= Cmd_send_default_err;
                endcase
              end

            end

            Cmd_send_done: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= Set_clk_max; // Stanje posle poslate komande

            end

            Cmd_send_Idle_err: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= Ups; // Stanje posle Idle greske

            end

            Cmd_send_default_err: begin

              r_cmd_send_sub_state <= Cmd_send_select;
              r_init_sub_state <= Ups; // Stanje posle default gresle posle poslate komande

            end

          endcase

        end

        Set_clk_max: begin

          r_mode <= 1'b1;
          r_state <= Idle;

        end

        Ups: begin

          r_init_sub_state <= Ups;

        end

      endcase

    end

    Idle: begin

    end

  endcase
end

endmodule
