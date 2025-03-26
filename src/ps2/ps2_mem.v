module ps2_mem(
  input i_ps2_data,
  input i_ps2_clk,
  input [31:0] i_addr,
  input i_clk,
  input i_req,
  input i_wren,
  output [7:0] o_out,
  output done
);

  wire [7:0] w_code;
  wire w_ncode;
  reg [7:0] r_control = 8'b0;
  reg r_break = 1'b0;
  reg r_done = 1'b0;

  localparam Break = 8'hf0, W = 8'h1d, A = 8'h1c, S = 8'h1b, D = 8'h23, Space = 8'h29, Esc = 8'h76, Ctrl = 8'h14, Shift = 8'h12;

  assign o_out = r_control;
  assign done = r_done;

  ps2 keyboard(.i_ps2_clk(i_ps2_clk),.i_ps2_data(i_ps2_data),.i_clk(i_clk),.i_spa(1'b1),.o_cap(w_ncode),.o_dap(w_code));
  
  always @(posedge i_clk) begin
    r_done <= 1'b0;
    if (i_req) begin
      r_done <= 1'b1;
    end
    if (w_ncode) begin
      case(w_code)
        Break: begin
          r_break <= 1'b1;
        end
        W: begin
          if(r_break) begin
            r_control[2] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[2] <= 1'b1;
        end
        A: begin
          if(r_break) begin
            r_control[3] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[3] <= 1'b1;
        end
        S: begin
          if(r_break) begin
            r_control[4] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[4] <= 1'b1;
        end
        D: begin
          if(r_break) begin
            r_control[5] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[5] <= 1'b1;
        end
        Space: begin
          if(r_break) begin
            r_control[6] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[6] <= 1'b1;
        end
        Esc: begin
          if(r_break) begin
            r_control[7] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[7] <= 1'b1;
        end
        Ctrl: begin
          if(r_break) begin
            r_control[0] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[0] <= 1'b1;
        end
        Shift: begin
          if(r_break) begin
            r_control[1] <= 1'b0;
            r_break <= 1'b0;
          end
          else r_control[1] <= 1'b1;
        end
      endcase
    end
  end

endmodule
