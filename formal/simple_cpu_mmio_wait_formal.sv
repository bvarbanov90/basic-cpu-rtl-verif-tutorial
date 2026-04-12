module simple_cpu_mmio_wait_formal;
  localparam logic [1:0] WAIT_CYCLES = 2'd1;

  reg rst_n = 1'b0;
  reg bus_valid = 1'b0;
  reg bus_write = 1'b0;
  reg [7:0] bus_addr = 8'h00;
  reg [7:0] bus_wdata = 8'h00;

  wire bus_ready;
  wire [7:0] bus_rdata;
  wire formal_pending;
  wire [1:0] formal_wait_count;
  wire formal_req_write;
  wire [7:0] formal_req_addr;
  wire [7:0] formal_req_wdata;
  wire formal_inner_valid;
  wire formal_inner_ready;
  wire [7:0] formal_inner_rdata;

  reg [1:0] reset_counter = 2'd0;
  reg past_valid = 1'b0;
  reg saw_request = 1'b0;
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
      .formal_req_write(formal_req_write),
      .formal_req_addr(formal_req_addr),
      .formal_req_wdata(formal_req_wdata),
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
      saw_request <= 1'b0;
      saw_wait_cycle <= 1'b0;
    end else begin
      rst_n <= 1'b1;
      bus_valid <= $anyseq;
      bus_write <= $anyseq;
      bus_addr <= $anyseq;
      bus_wdata <= $anyseq;
      saw_request <= saw_request || (!formal_pending && bus_valid);
      saw_wait_cycle <= saw_wait_cycle || (formal_pending && (formal_wait_count != 2'd0));
    end
  end

  always_comb begin
    assert (formal_inner_ready == 1'b1);
    assert (formal_inner_valid == (formal_pending && (formal_wait_count == 2'd0)));
    assert (bus_ready == (formal_inner_valid && formal_inner_ready));
    assert (bus_rdata == formal_inner_rdata);

    if (!formal_pending) begin
      assert (!formal_inner_valid);
      assert (!bus_ready);
    end

    if (formal_pending && (formal_wait_count != 2'd0)) begin
      assert (!formal_inner_valid);
      assert (!bus_ready);
    end

    if (formal_pending && (formal_wait_count == 2'd0)) begin
      assert (formal_inner_valid);
      assert (bus_ready);
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && $past(!rst_n)) begin
      assert (!formal_pending);
      assert (formal_wait_count == WAIT_CYCLES);
    end

    if (past_valid && $past(rst_n)) begin
      if (!$past(formal_pending)) begin
        if ($past(bus_valid)) begin
          assert (formal_pending);
          assert (formal_wait_count == WAIT_CYCLES);
          assert (formal_req_write == $past(bus_write));
          assert (formal_req_addr == $past(bus_addr));
          assert (formal_req_wdata == $past(bus_wdata));
        end else begin
          assert (!formal_pending);
        end
      end else begin
        assert (formal_req_write == $past(formal_req_write));
        assert (formal_req_addr == $past(formal_req_addr));
        assert (formal_req_wdata == $past(formal_req_wdata));

        if ($past(formal_wait_count != 2'd0)) begin
          assert (formal_pending);
          assert (formal_wait_count == ($past(formal_wait_count) - 2'd1));
        end else begin
          assert (!formal_pending);
        end
      end
    end
  end

  always @(posedge $global_clock) begin
    cover (past_valid && saw_request && saw_wait_cycle && bus_ready);
  end
endmodule
