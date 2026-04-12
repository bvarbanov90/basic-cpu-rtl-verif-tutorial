module simple_cpu_mmio_wait_cover_formal;
  reg rst_n = 1'b0;
  reg bus_valid = 1'b0;
  reg bus_write = 1'b0;
  reg [7:0] bus_addr = 8'h00;
  reg [7:0] bus_wdata = 8'h00;

  wire bus_ready;
  wire [7:0] bus_rdata;
  wire formal_pending;
  wire [1:0] formal_wait_count;
  wire formal_inner_valid;
  wire formal_inner_ready;
  wire [7:0] formal_inner_rdata;

  reg [1:0] reset_counter = 2'd0;
  reg past_valid = 1'b0;
  reg saw_pending = 1'b0;
  reg saw_wait_cycle = 1'b0;

  simple_cpu_mmio_wait dut (
      .clk($global_clock),
      .rst_n(rst_n),
      .bus_valid(bus_valid),
      .bus_write(bus_write),
      .bus_addr(bus_addr),
      .bus_wdata(bus_wdata),
      .bus_ready(bus_ready),
      .bus_rdata(bus_rdata),
      .formal_pending(formal_pending),
      .formal_wait_count(formal_wait_count),
      .formal_inner_bus_valid(formal_inner_valid),
      .formal_inner_bus_ready(formal_inner_ready),
      .formal_inner_bus_rdata(formal_inner_rdata)
  );

  always @(posedge $global_clock) begin
    past_valid <= 1'b1;

    if (reset_counter < 2'd2) begin
      reset_counter <= reset_counter + 2'd1;
      rst_n <= 1'b0;
      bus_valid <= 1'b0;
      bus_write <= 1'b0;
      bus_addr <= 8'h00;
      bus_wdata <= 8'h00;
      saw_pending <= 1'b0;
      saw_wait_cycle <= 1'b0;
    end else begin
      rst_n <= 1'b1;
      bus_valid <= $anyseq;
      bus_write <= $anyseq;
      bus_addr <= $anyseq;
      bus_wdata <= $anyseq;
      saw_pending <= saw_pending || formal_pending;
      saw_wait_cycle <= saw_wait_cycle || (formal_pending && (formal_wait_count != 2'd0));
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && rst_n) begin
      assert (bus_rdata == formal_inner_rdata);
      assert (bus_ready == (formal_inner_valid && formal_inner_ready));
    end

    cover (past_valid && saw_pending && saw_wait_cycle && bus_ready);
  end
endmodule
