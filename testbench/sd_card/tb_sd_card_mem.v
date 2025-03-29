module tb_sd_card_mem;

  reg clk = 1'b0;
  reg [31:0] r_addr = 32'b0;
  reg [7:0] r_cotrolreg = 8'b0;
  reg [8:0] r_data = 8'b0;
  reg r_SD_WP_N = 1'b0;
  reg r_SD_DAT0_DO = 1'b0;
  reg r_SD_DAT3_nCS = 1'b0;
  reg r_SD_CMD_DI = 1'b0;
  reg r_drive_sd_dat0 = 1'b0;
  reg r_drive_sd_dat3 = 1'b0;
  reg r_drive_sd_cmd = 1'b0;

  wire w_statusreg;
  wire w_write_statusreg;
  wire w_data;
  wire w_addr;
  wire w_wr_nrd;
  wire w_req;
  wire w_SD_CLK;

  wire w_SD_DAT0_DO;
  wire w_SD_DAT3_nCS;
  wire w_SD_CMD_DI;

  assign w_SD_DAT0_DO = r_drive_sd_dat0 ? r_SD_DAT0_DO : 1'bz;
  assign w_SD_DAT3_nCS = r_drive_sd_dat3 ? r_SD_DAT3_nCS : 1'bz;
  assign w_SD_CMD_DI = r_drive_sd_cmd ? r_SD_CMD_DI : 1'bz;

  sd_card_mem scm(
  .i_clk(clk),
  .i_addr(r_addr),
  .i_controlreg(r_cotrolreg),
  .i_data(r_data),
  .o_statusreg(w_statusreg),
  .o_write_statusreg(w_write_statusreg),
  .o_data(w_data),
  .o_addr(w_addr),
  .o_wr_nrd(w_wr_nrd),
  .o_req(w_req),
  .io_SD_DAT0_DO(w_SD_DAT0_DO),
  .io_SD_DAT3_nCS(w_SD_DAT3_nCS),
  .io_SD_CMD_DI(w_SD_CMD_DI),
  .o_SD_CLK(w_SD_CLK),
  .i_SD_WP_N(r_SD_WP_N)
  );

  always #5 clk = ~clk;

  initial begin



  end

endmodule
