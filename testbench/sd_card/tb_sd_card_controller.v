module tb_sd_card_controller;

reg i_clk = 1'b0;
reg [31:0] i_addr = 32'b0;
reg [7:0] i_controlreg = 8'h01;
wire [7:0] i_data;
wire [7:0] o_statusreg;
wire o_write_statusreg;
wire [7:0] o_data;
wire [31:0] o_addr;
wire o_wr_nrd;
wire o_req;

wire io_SD_DAT0_DO;
wire io_SD_DAT3_nCS;
wire io_SD_CMD_DI;
wire o_SD_CLK;
wire i_SD_WP_N;

initial forever #5 i_clk = ~i_clk;
initial #10000000 $finish;

reg [8:0] r_response = 9'b111111111;

initial #200000 r_response <= 9'b000000000;

assign io_SD_DAT0_DO = r_response[0];

always @(posedge o_SD_CLK) begin
  r_response <= {r_response[7:0] , r_response[8]};
end

sd_card_controller m_sd_card(
  .i_clk(i_clk),
  .i_addr(i_addr),
  .i_controlreg(i_controlreg),
  .i_data(i_data),
  .o_statusreg(o_statusreg),
  .o_write_statusreg(o_write_statusreg),
  .o_data(o_data),
  .o_addr(o_addr),
  .o_wr_nrd(o_wr_nrd),
  .o_req(o_req),

  .io_SD_DAT0_DO(io_SD_DAT0_DO),
  .io_SD_DAT3_nCS(io_SD_DAT3_nCS),
  .io_SD_CMD_DI(io_SD_CMD_DI),
  .o_SD_CLK(o_SD_CLK),
  .i_SD_WP_N(i_SD_WP_N)
);

  mem_for_testing mft(.i_clk(i_clk), .i_data(o_data), .i_addr(o_addr), .i_write(o_wr_nrd), .o_data(i_data));

endmodule
