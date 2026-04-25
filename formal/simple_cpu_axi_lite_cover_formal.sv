module simple_cpu_axi_lite_cover_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;

  reg aresetn = 1'b0;
  reg axi_awvalid = 1'b0;
  reg [7:0] axi_awaddr = 8'h00;
  reg axi_wvalid = 1'b0;
  reg [7:0] axi_wdata = 8'h00;
  reg axi_bready = 1'b0;
  reg axi_arvalid = 1'b0;
  reg [7:0] axi_araddr = 8'h00;
  reg axi_rready = 1'b0;

  wire axi_awready;
  wire axi_wready;
  wire axi_bvalid;
  wire axi_arready;
  wire axi_rvalid;
  wire mmio_valid;
  wire mmio_ready;
  wire mmio_write;
  wire [1:0] state;
  wire core_rst_n;
  wire prog_we;
  wire [3:0] prog_addr;
  wire [3:0] load_index;
  wire dbg_halted;

  wire write_accept = mmio_ready && !axi_bvalid && axi_awvalid && axi_wvalid;
  wire read_accept = mmio_ready && !axi_rvalid && !write_accept && axi_arvalid;

  reg [1:0] reset_counter = 2'd0;
  reg past_valid = 1'b0;
  reg saw_partial = 1'b0;
  reg saw_write = 1'b0;
  reg saw_read = 1'b0;
  reg saw_start = 1'b0;

  simple_cpu_axi_lite dut (
      .aclk($global_clock),
      .aresetn(aresetn),
      .axi_awvalid(axi_awvalid),
      .axi_awready(axi_awready),
      .axi_awaddr(axi_awaddr),
      .axi_wvalid(axi_wvalid),
      .axi_wready(axi_wready),
      .axi_wdata(axi_wdata),
      .axi_bvalid(axi_bvalid),
      .axi_bready(axi_bready),
      .axi_bresp(),
      .axi_arvalid(axi_arvalid),
      .axi_arready(axi_arready),
      .axi_araddr(axi_araddr),
      .axi_rvalid(axi_rvalid),
      .axi_rready(axi_rready),
      .axi_rdata(),
      .axi_rresp(),
      .formal_mmio_valid(mmio_valid),
      .formal_mmio_ready(mmio_ready),
      .formal_mmio_rdata(),
      .formal_mmio_write(mmio_write),
      .formal_mmio_addr(),
      .formal_read_addr_q(),
      .formal_state(state),
      .formal_load_index(load_index),
      .formal_core_rst_n(core_rst_n),
      .formal_prog_we(prog_we),
      .formal_prog_addr(prog_addr),
      .formal_prog_data(),
      .formal_shadow_flat(),
      .formal_dbg_mem_data(),
      .formal_dbg_acc(),
      .formal_dbg_pc(),
      .formal_dbg_zero(),
      .formal_dbg_carry(),
      .formal_dbg_neg(),
      .formal_dbg_overflow(),
      .formal_dbg_halted(dbg_halted)
  );

  always @(posedge $global_clock) begin
    past_valid <= 1'b1;

    if (reset_counter < 2'd2) begin
      reset_counter <= reset_counter + 2'd1;
      aresetn <= 1'b0;
      axi_awvalid <= 1'b0;
      axi_awaddr <= 8'h00;
      axi_wvalid <= 1'b0;
      axi_wdata <= 8'h00;
      axi_bready <= 1'b0;
      axi_arvalid <= 1'b0;
      axi_araddr <= 8'h00;
      axi_rready <= 1'b0;
      saw_partial <= 1'b0;
      saw_write <= 1'b0;
      saw_read <= 1'b0;
      saw_start <= 1'b0;
    end else begin
      aresetn <= 1'b1;
      axi_awvalid <= $anyseq;
      axi_awaddr <= $anyseq;
      axi_wvalid <= $anyseq;
      axi_wdata <= $anyseq;
      axi_bready <= $anyseq;
      axi_arvalid <= $anyseq;
      axi_araddr <= $anyseq;
      axi_rready <= $anyseq;
      saw_partial <= saw_partial || (axi_awvalid ^ axi_wvalid);
      saw_write <= saw_write || write_accept;
      saw_read <= saw_read || read_accept;
      saw_start <= saw_start || (write_accept && (axi_awaddr == 8'h30) && axi_wdata[0]);
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && aresetn) begin
      assert (axi_awready == write_accept);
      assert (axi_wready == write_accept);
      assert (axi_arready == read_accept);
      assert (mmio_valid == (write_accept || read_accept));
      assert (mmio_write == write_accept);
      assert (prog_we == (state == 2'd1));
      assert (core_rst_n == (state != STATE_HOLD));
      assert (prog_addr == load_index);
    end
  end

  always @(posedge $global_clock) begin
    cover (past_valid && saw_partial && saw_write && saw_read && saw_start && dbg_halted);
  end
endmodule
