module tb_sd_card_controller;

  reg i_clk = 1'b0;
  reg [31:0] i_addr = 32'b0;
  reg [7:0] i_controlreg = 8'h00;
  localparam ctrlreg_no_operation = 8'd0, ctrlreg_read_operation = 8'd1, ctrlreg_write_operation = 8'd2;
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

  wire [40:0] w_resonse_idle = {9'b100000001, 32'h0000000};
  wire [40:0] w_resonse = {9'b100000000, 32'h0000000};
  wire [40:0] w_resonse_nothing = 41'h1FFFFFFFFFF;

  reg r_pod_res = 1'b0;

  reg [40:0] r_response = {9'b100000001, 32'h0000000};
  reg r_shift = 1'b0;

  reg [4128:0] r_podaci = {8'hFF, 8'hFE,
                          {512{8'h48}},
                          16'b0, 1'b1};

  assign io_SD_DAT0_DO = r_pod_res ? r_podaci[4128] : r_response[40];

  always @(posedge o_SD_CLK) begin
    if (r_shift && !r_pod_res) r_response <= {r_response[39:0] , r_response[40]};
    if (o_write_statusreg) i_controlreg <= ctrlreg_no_operation;
    if (r_shift && r_pod_res) r_podaci <= {r_podaci[4127:0], 1'b1};
  end

  initial begin

    #358755
    r_response <= w_resonse_idle;
    r_shift <= 1'b1;
    #20001
    r_response <= w_resonse_nothing;
    r_shift <= 1'b0;

  end

  initial begin

    #516255
    r_response <= w_resonse_idle;
    r_shift <= 1'b1;
    #20001
    r_response <= w_resonse_nothing;
    r_shift <= 1'b0;

  end

  initial begin

    #673755
    r_response <= w_resonse;
    r_shift <= 1'b1;
    #20001
    r_response <= w_resonse_nothing;
    r_shift <= 1'b0;

  end

  initial begin

    #831255
    r_response <= w_resonse;
    r_shift <= 1'b1;
    #100001
    r_response <= w_resonse_nothing;
    r_shift <= 1'b0;

  end

  initial begin

    #950000
    i_controlreg <= ctrlreg_read_operation;
    #2155
    r_response <= w_resonse;
    r_shift <= 1'b1;
    #321
    r_response <= w_resonse_nothing;
    r_pod_res <= 1'b1;
    #200000
    r_pod_res <= 1'b0;

  end

  initial begin

    #1200000
    i_controlreg <= ctrlreg_write_operation;
    #2155
    r_response <= w_resonse;
    r_shift <= 1'b1;
    #321
    r_response <= w_resonse_nothing;
    r_shift <= 1'b0;

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

  mem_for_testing mft(.i_clk(o_SD_CLK), .i_data(o_data), .i_addr(o_addr), .i_write(o_wr_nrd), .o_data(i_data));

endmodule
