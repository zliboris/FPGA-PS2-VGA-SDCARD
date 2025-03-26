module sd_card_cmd(
  input i_clk,
  input i_send_cmd,
  input [2:0] i_cmd_select,
  input [31:0] i_cmd_arg,
  inout io_sd_response,
  output o_confirm_pin,
  output o_CMD_OUTPUT,
  output [7:0] o_response_status
);

  reg [7:0] r_state = 8'b0;
  reg [47:0] r_cmd_code = 48'b0;
  reg [7:0] r_bit_counter = 8'b0;
  reg r_confirm_pin = 1'b0;
  reg [7:0] r_R1_response = 8'hFF;
  reg [39:0] r_R3_response = 40'hFFFFFFFFFF;
  reg [7:0] r_response_status = 8'b0;
  reg r_rsp_type = 1'b0;
  reg [7:0] r_saved_rsp = 8'b0;


  wire [47:0] w_cmd0 = { 2'b01, 6'd0, 32'h0 , 8'h95};
  wire [47:0] w_cmd16 = { 2'b01, 6'd16, i_cmd_arg , 8'h95};
  wire [47:0] w_cmd17 = { 2'b01, 6'd17, i_cmd_arg , 8'h95};
  wire [47:0] w_cmd41 = { 2'b01, 6'd41, 32'h0 , 8'h95};
  wire [47:0] w_cmd55 = { 2'b01, 6'd55, 32'h0 , 8'h95};
  wire [47:0] w_cmd24 = { 2'b01, 6'd24, i_cmd_arg , 8'h95};
  wire [47:0] w_cmd58 = { 2'b01, 6'd58, 32'h0 , 8'h95};


  localparam NO_CMD = 3'h0, CMD0 = 3'h1, CMD16 = 3'h2, CMD17 = 3'h3, CMD24 = 3'h4, CMD55 = 3'h5, CMD58 = 3'h6, CMD41 = 3'h7;
  localparam rsp_R1 = 1'b0, rsp_R3 = 1'b1;
  localparam Idle = 8'd0, Select_Cmd = 8'd1, Send_Cmd = 8'd2, Get_Rsp = 8'd3, Good_Rsp = 8'd4, Error = 8'd5;
  localparam No_rsp = 8'd0, No_error = 8'd1, Idle_error = 8'd2, Bad_error = 8'd3;


  assign o_confirm_pin = r_confirm_pin;
  assign o_CMD_OUTPUT = r_cmd_code[47];
  assign o_response_status = r_response_status;

  always @(posedge i_clk) begin

    if (r_confirm_pin) r_confirm_pin <= 1'b0;

    case (r_state) 

      Idle: begin

        if (i_send_cmd) r_state <= Select_Cmd;

      end

      Select_Cmd: begin

        case (i_cmd_select)

          CMD0: begin

            r_cmd_code <= w_cmd0;
            r_rsp_type <= rsp_R1;

          end

          CMD16: begin

            r_cmd_code <= w_cmd16;
            r_rsp_type <= rsp_R1;

          end

          CMD17: begin

            r_cmd_code <= w_cmd17;
            r_rsp_type <= rsp_R1;

          end

          CMD24: begin

            r_cmd_code <= w_cmd24;
            r_rsp_type <= rsp_R1;

          end

          CMD55: begin

            r_cmd_code <= w_cmd55;
            r_rsp_type <= rsp_R1;

          end

          CMD58: begin

            r_cmd_code <= w_cmd58;
            r_rsp_type <= rsp_R3;

          end

          CMD41: begin

            r_cmd_code <= w_cmd41;
            r_rsp_type <= rsp_R1;

          end

        endcase

        r_state <= Send_Cmd;

      end

      Send_Cmd: begin

        if (r_bit_counter == 8'd47) begin
          r_bit_counter <= 8'b0;
          r_state <= Get_Rsp;
        end

        else begin
          r_bit_counter <= r_bit_counter + 1;
          r_cmd_code <= { r_cmd_code[46:0] , 1'b0};
        end

        if (r_bit_counter == 8'd46)  r_confirm_pin <= 1'b1;

      end

      Get_Rsp: begin

        case (r_rsp_type)

          rsp_R1: begin//rework rsp

            r_R1_response <= { r_R1_response[6:0], io_sd_response };
            if (!r_R1_response[7]) begin
              r_R1_response <= 8'hFF;
              if (r_R1_response[6] || r_R1_response[5] || r_R1_response[4] || r_R1_response[3] || r_R1_response[2] || r_R1_response[1] || r_R1_response[0]) begin
                r_saved_rsp <= r_R1_response;
                r_state <= Error;
              end
              else r_state <= Good_Rsp;
            end
          end

          rsp_R3: begin

            r_R3_response <= { r_R3_response[38:0], io_sd_response };
            if (!r_R3_response[39]) begin
              r_R3_response = 40'hFFFFFFFFFF;
              if (r_R3_response[6] || r_R3_response[5] || r_R3_response[4] || r_R3_response[3] || r_R3_response[2] || r_R3_response[1] || r_R3_response[0]) begin 
                r_saved_rsp <= r_R3_response [7:0];
                r_state <= Error;//moguce da treba da se doda ovde za ogranicenje napona ali nemam pojma isk
              end
              else r_state <= Good_Rsp;
            end

          end

        endcase

      end

      Good_Rsp: begin

        r_response_status <= No_error;
        r_state <= Idle;

      end

      Error: begin

        if (r_saved_rsp[0]) begin
          r_response_status <= Idle_error;
          r_confirm_pin <= 1'b1;
          r_state <= Idle;
        end
        else begin
          r_response_status <= Bad_error;
          r_confirm_pin <= 1'b1;
          r_state <= Idle;
        end

      end

    endcase

  end

endmodule
