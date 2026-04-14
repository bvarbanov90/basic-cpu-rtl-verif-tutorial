module simple_cpu_mmio_wait_fault_formal;
  localparam logic [1:0] WAIT_CYCLES = 2'd1;
  localparam logic [7:0] REQUEST_ADDR = 8'h23;
  localparam logic [7:0] REQUEST_WDATA = 8'h55;
  localparam logic [7:0] DISTRACTOR_ADDR = 8'h2F;
  localparam logic [7:0] DISTRACTOR_WDATA = 8'hAA;
  localparam logic [7:0] EXPECTED_RDATA = {4'hA, REQUEST_ADDR[3:0]};

  logic rst_n;
  logic bus_valid;
  logic bus_write;
  logic [7:0] bus_addr;
  logic [7:0] bus_wdata;

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
  reg [2:0] step = 3'd0;
  reg past_valid = 1'b0;

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
      step <= 3'd0;
    end else if (step < 3'd4) begin
      step <= step + 3'd1;
    end
  end

  always_comb begin
    rst_n = (reset_counter >= 2'd2);
    bus_valid = 1'b0;
    bus_write = 1'b0;
    bus_addr = 8'h00;
    bus_wdata = 8'h00;

    if (rst_n) begin
      case (step)
        3'd0: begin
          bus_valid = 1'b1;
          bus_write = 1'b0;
          bus_addr  = REQUEST_ADDR;
          bus_wdata = REQUEST_WDATA;
        end
        3'd1: begin
          bus_valid = 1'b1;
          bus_write = 1'b1;
          bus_addr  = DISTRACTOR_ADDR;
          bus_wdata = DISTRACTOR_WDATA;
        end
        default: begin
        end
      endcase
    end

    assert (formal_inner_ready == 1'b1);
    assert (formal_inner_rdata == {4'hA, formal_req_addr[3:0]});
    assert (bus_rdata == formal_inner_rdata);
  end

  always @(posedge $global_clock) begin
    if (past_valid && $past(!rst_n)) begin
      assert (!formal_pending);
      assert (formal_wait_count == WAIT_CYCLES);
      assert (!bus_ready);
    end

    if (rst_n) begin
      case (step)
        3'd1: begin
          assert (formal_pending);
          assert (formal_wait_count == WAIT_CYCLES);
          assert (formal_req_write == 1'b0);
          assert (formal_req_addr == REQUEST_ADDR);
          assert (formal_req_wdata == REQUEST_WDATA);
          assert (!formal_inner_valid);
          assert (!bus_ready);
        end
        3'd2: begin
          assert (formal_pending);
          assert (formal_wait_count == 2'd0);
          assert (formal_req_write == 1'b0);
          assert (formal_req_addr == REQUEST_ADDR);
          assert (formal_req_wdata == REQUEST_WDATA);
          assert (formal_inner_valid);
          assert (bus_ready);
          assert (bus_rdata == EXPECTED_RDATA);
        end
        3'd3: begin
          assert (!formal_pending);
          assert (!formal_inner_valid);
          assert (!bus_ready);
        end
        default: begin
        end
      endcase
    end

    cover (rst_n && (step == 3'd2) && bus_ready && (bus_rdata == EXPECTED_RDATA));
  end
endmodule
