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
      if (w_response_status == Rsp_no_error) r_cmd_send_sub_state <= Cmd_send_done;
      else begin 
        r_error_code <= w_response_status;
        r_cmd_send_sub_state <= Cmd_send_error;
      end
    end

  end

  Cmd_send_error: begin

    r_cmd_send_sub_state <= Cmd_send_select;

    case (r_error_code)// Stanja posle gresaka pri slanju komande

      Rsp_idle_error: r_read_sub_states <= Read_error;

      Rsp_erase_reset: r_read_sub_states <= Read_error;

      Rsp_illegal_command: r_read_sub_states <= Read_error;

      Rsp_crc_error: r_read_sub_states <= Read_error;

      Rsp_erase_sequence_error: r_read_sub_states <= Read_error;

      Rsp_address_error: r_read_sub_states <= Read_error;

      Rsp_Parameter_error: r_read_sub_states <= Read_error;

    endcase

  end

  Cmd_send_done: begin

    r_cmd_send_sub_state <= Cmd_send_select;
    r_init_sub_state <= Novo Stanje; // Stanje posle poslate komande

  end

endcase
