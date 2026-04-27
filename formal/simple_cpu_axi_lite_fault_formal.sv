module simple_cpu_axi_lite_fault_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_CONTROL = 8'h30;
  localparam logic [7:0] SHADOW0_RUN_UPDATE = 8'h19;
  localparam logic [7:0] SHADOW0_AW_GLITCH = 8'hA9;
  localparam logic [7:0] SHADOW0_W_GLITCH = 8'hA7;
  localparam logic [7:0] SHADOW1_PENDING_GLITCH = 8'h36;

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
  wire [1:0] state;
  wire [3:0] load_index;
  wire core_rst_n;
  wire prog_we;
  wire [3:0] prog_addr;
  wire [7:0] prog_data;
  wire [127:0] shadow_flat;

  (* anyconst *) logic [2:0] scenario_seed;
  logic [2:0] scenario;
  reg [5:0] step = 6'd0;
  reg past_valid = 1'b0;

  wire write_accept = mmio_ready && !axi_bvalid && axi_awvalid && axi_wvalid;
  wire read_accept = mmio_ready && !axi_rvalid && !write_accept && axi_arvalid;

  function automatic [7:0] shadow_byte(input [127:0] flat, input [3:0] index);
    begin
      shadow_byte = flat[{index, 3'b000}+:8];
    end
  endfunction

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
      .formal_read_addr_q(),
      .formal_state(state),
      .formal_load_index(load_index),
      .formal_core_rst_n(core_rst_n),
      .formal_prog_we(prog_we),
      .formal_prog_addr(prog_addr),
      .formal_prog_data(prog_data),
      .formal_shadow_flat(shadow_flat),
      .formal_dbg_mem_data(),
      .formal_dbg_acc(),
      .formal_dbg_pc(),
      .formal_dbg_zero(),
      .formal_dbg_carry(),
      .formal_dbg_neg(),
      .formal_dbg_overflow(),
      .formal_dbg_halted()
  );

  always_comb begin
    scenario = (scenario_seed > 3'd4) ? 3'd4 : scenario_seed;

    aresetn = (step >= 6'd2);
    axi_awvalid = 1'b0;
    axi_awaddr = 8'h00;
    axi_wvalid = 1'b0;
    axi_wdata = 8'h00;
    axi_bready = 1'b0;
    axi_arvalid = 1'b0;
    axi_araddr = 8'h00;
    axi_rready = 1'b0;

    case (scenario)
      3'd0: begin
        case (step)
          6'd2: begin
            axi_awvalid = 1'b1;
            axi_awaddr = 8'h00;
            axi_wvalid = 1'b0;
            axi_wdata = SHADOW0_AW_GLITCH;
            axi_bready = 1'b1;
          end
          default: begin
          end
        endcase
      end
      3'd1: begin
        case (step)
          6'd2: begin
            axi_awvalid = 1'b0;
            axi_awaddr = 8'h00;
            axi_wvalid = 1'b1;
            axi_wdata = SHADOW0_W_GLITCH;
            axi_bready = 1'b1;
          end
          6'd3: begin
            axi_awvalid = 1'b0;
            axi_awaddr = ADDR_CONTROL;
            axi_wvalid = 1'b1;
            axi_wdata = 8'h01;
            axi_bready = 1'b1;
          end
          default: begin
          end
        endcase
      end
      3'd2: begin
        case (step)
          6'd2: begin
            axi_awvalid = 1'b1;
            axi_awaddr = 8'h00;
            axi_wvalid = 1'b0;
            axi_wdata = SHADOW0_AW_GLITCH;
            axi_bready = 1'b1;
          end
          6'd3: begin
            axi_awvalid = 1'b0;
            axi_awaddr = 8'h00;
            axi_wvalid = 1'b1;
            axi_wdata = SHADOW0_W_GLITCH;
            axi_bready = 1'b1;
          end
          default: begin
          end
        endcase
      end
      3'd3: begin
        case (step)
          6'd2: begin
            axi_awvalid = 1'b1;
            axi_awaddr = 8'h00;
            axi_wvalid = 1'b1;
            axi_wdata = SHADOW0_AW_GLITCH;
            axi_bready = 1'b0;
          end
          6'd3: begin
            axi_awvalid = 1'b1;
            axi_awaddr = 8'h01;
            axi_wvalid = 1'b1;
            axi_wdata = SHADOW1_PENDING_GLITCH;
            axi_bready = 1'b0;
          end
          6'd4: begin
            axi_bready = 1'b1;
          end
          default: begin
          end
        endcase
      end
      default: begin
        axi_bready = 1'b1;
        case (step)
          6'd2: begin
            axi_awvalid = 1'b1;
            axi_awaddr = ADDR_CONTROL;
            axi_wvalid = 1'b1;
            axi_wdata = 8'h01;
          end
          6'd19: begin
            axi_awvalid = 1'b1;
            axi_awaddr = 8'h00;
            axi_wvalid = 1'b1;
            axi_wdata = SHADOW0_RUN_UPDATE;
          end
          6'd21: begin
            axi_awvalid = 1'b1;
            axi_awaddr = ADDR_CONTROL;
            axi_wvalid = 1'b1;
            axi_wdata = 8'h00;
          end
          6'd23: begin
            axi_awvalid = 1'b1;
            axi_awaddr = ADDR_CONTROL;
            axi_wvalid = 1'b1;
            axi_wdata = 8'h01;
          end
          default: begin
          end
        endcase
      end
    endcase
  end

  always @(posedge $global_clock) begin
    past_valid <= 1'b1;
    if (step < 6'd28) begin
      step <= step + 6'd1;
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
      assert (!axi_awready && !axi_wready && !axi_bvalid && !mmio_valid);
    end
    if (!axi_awvalid && axi_wvalid) begin
      assert (!axi_awready && !axi_wready && !axi_bvalid && !mmio_valid);
    end
    if (axi_bvalid && !axi_bready) begin
      assert (!axi_awready && !axi_wready);
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && (step == 6'd3) && (scenario == 3'd0)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
      assert (shadow_byte(shadow_flat, 4'd0) == 8'h00);
      assert (!axi_bvalid);
    end

    if (past_valid && (step == 6'd4) && (scenario == 3'd1)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
      assert (shadow_byte(shadow_flat, 4'd0) == 8'h00);
      assert (!axi_bvalid);
    end

    if (past_valid && (step == 6'd4) && (scenario == 3'd2)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
      assert (shadow_byte(shadow_flat, 4'd0) == 8'h00);
      assert (!axi_bvalid);
    end

    if (past_valid && (step == 6'd3) && (scenario == 3'd3)) begin
      assert (axi_bvalid);
      assert (state == STATE_HOLD);
      assert (shadow_byte(shadow_flat, 4'd0) == SHADOW0_AW_GLITCH);
      assert (shadow_byte(shadow_flat, 4'd1) == 8'h00);
    end

    if (past_valid && (step == 6'd4) && (scenario == 3'd3)) begin
      assert (axi_bvalid);
      assert (!axi_awready && !axi_wready);
      assert (shadow_byte(shadow_flat, 4'd0) == SHADOW0_AW_GLITCH);
      assert (shadow_byte(shadow_flat, 4'd1) == 8'h00);
    end

    if (past_valid && (step == 6'd20) && (scenario == 3'd4)) begin
      assert (state == STATE_RUN);
      assert (!prog_we);
      assert (shadow_byte(shadow_flat, 4'd0) == SHADOW0_RUN_UPDATE);
    end

    if (past_valid && (step == 6'd22) && (scenario == 3'd4)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
    end

    if (past_valid && (step == 6'd24) && (scenario == 3'd4)) begin
      assert (state == STATE_LOAD);
      assert (prog_we);
      assert (prog_addr == 4'h0);
      assert (prog_data == SHADOW0_RUN_UPDATE);
    end
  end
endmodule
