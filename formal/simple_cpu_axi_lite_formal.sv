module simple_cpu_axi_lite_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_CONTROL = 8'h30;

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
  wire [1:0] axi_bresp;
  wire axi_arready;
  wire axi_rvalid;
  wire [7:0] axi_rdata;
  wire [1:0] axi_rresp;
  wire mmio_valid;
  wire mmio_ready;
  wire [7:0] mmio_rdata;
  wire mmio_write;
  wire [7:0] mmio_addr;
  wire [7:0] read_addr_q;
  wire [1:0] state;
  wire [3:0] load_index;
  wire core_rst_n;
  wire prog_we;
  wire [3:0] prog_addr;
  wire [7:0] prog_data;
  wire [127:0] shadow_flat;
  wire [7:0] dbg_mem_data;
  wire [7:0] dbg_acc;
  wire [3:0] dbg_pc;
  wire dbg_zero;
  wire dbg_carry;
  wire dbg_neg;
  wire dbg_overflow;
  wire dbg_halted;

  wire write_accept = mmio_ready && !axi_bvalid && axi_awvalid && axi_wvalid;
  wire read_accept = mmio_ready && !axi_rvalid && !write_accept && axi_arvalid;

  reg [1:0] reset_counter = 2'd0;
  reg past_valid = 1'b0;
  reg saw_aw_only = 1'b0;
  reg saw_w_only = 1'b0;
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
      .axi_bresp(axi_bresp),
      .axi_arvalid(axi_arvalid),
      .axi_arready(axi_arready),
      .axi_araddr(axi_araddr),
      .axi_rvalid(axi_rvalid),
      .axi_rready(axi_rready),
      .axi_rdata(axi_rdata),
      .axi_rresp(axi_rresp),
      .formal_mmio_valid(mmio_valid),
      .formal_mmio_ready(mmio_ready),
      .formal_mmio_rdata(mmio_rdata),
      .formal_mmio_write(mmio_write),
      .formal_mmio_addr(mmio_addr),
      .formal_read_addr_q(read_addr_q),
      .formal_state(state),
      .formal_load_index(load_index),
      .formal_core_rst_n(core_rst_n),
      .formal_prog_we(prog_we),
      .formal_prog_addr(prog_addr),
      .formal_prog_data(prog_data),
      .formal_shadow_flat(shadow_flat),
      .formal_dbg_mem_data(dbg_mem_data),
      .formal_dbg_acc(dbg_acc),
      .formal_dbg_pc(dbg_pc),
      .formal_dbg_zero(dbg_zero),
      .formal_dbg_carry(dbg_carry),
      .formal_dbg_neg(dbg_neg),
      .formal_dbg_overflow(dbg_overflow),
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
      saw_aw_only <= 1'b0;
      saw_w_only <= 1'b0;
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
      saw_aw_only <= saw_aw_only || (axi_awvalid && !axi_wvalid);
      saw_w_only <= saw_w_only || (!axi_awvalid && axi_wvalid);
      saw_write <= saw_write || write_accept;
      saw_read <= saw_read || read_accept;
      saw_start <= saw_start || (write_accept && (axi_awaddr == ADDR_CONTROL) && axi_wdata[0]);
    end
  end

  always_comb begin
    assert (axi_awready == write_accept);
    assert (axi_wready == write_accept);
    assert (axi_arready == read_accept);
    assert (axi_bresp == 2'b00);
    assert (axi_rresp == 2'b00);
    assert (mmio_valid == (write_accept || read_accept));
    assert (mmio_write == write_accept);

    if (write_accept) begin
      assert (mmio_addr == axi_awaddr);
    end
    if (read_accept) begin
      assert (mmio_addr == axi_araddr);
    end
    if (axi_awvalid && !axi_wvalid) begin
      assert (!axi_awready && !axi_wready);
    end
    if (!axi_awvalid && axi_wvalid) begin
      assert (!axi_awready && !axi_wready);
    end
    if (axi_bvalid && !axi_bready) begin
      assert (!axi_awready && !axi_wready);
    end
    if (axi_rvalid && !axi_rready) begin
      assert (!axi_arready);
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && $past(aresetn)) begin
      if ($past(write_accept)) begin
        assert (axi_bvalid);
      end
      if ($past(axi_bvalid && !axi_bready)) begin
        assert (axi_bvalid);
      end
      if ($past(read_accept)) begin
        assert (axi_rvalid);
        assert (axi_rdata == $past(mmio_rdata));
        assert (read_addr_q == $past(axi_araddr));
      end
      if ($past(axi_rvalid && !axi_rready)) begin
        assert (axi_rvalid);
      end

      assert (core_rst_n == (state != STATE_HOLD));
      assert (prog_we == (state == STATE_LOAD));
      assert (prog_addr == load_index);
      assert (prog_data == shadow_flat[{load_index, 3'b000} +: 8]);
    end
  end

  always @(posedge $global_clock) begin
    cover (past_valid && saw_aw_only);
    cover (past_valid && saw_w_only);
    cover (past_valid && saw_write);
    cover (past_valid && saw_read);
    cover (past_valid && saw_start && (state == STATE_RUN));
    cover (past_valid && saw_start && saw_read && dbg_halted);
  end
endmodule
