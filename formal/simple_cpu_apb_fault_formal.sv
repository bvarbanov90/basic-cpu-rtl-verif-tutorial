module simple_cpu_apb_fault_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_CONTROL = 8'h30;
  localparam logic [7:0] SHADOW0_RUN_UPDATE = 8'h19;
  localparam logic [7:0] SHADOW0_SETUP_GLITCH = 8'hA9;
  localparam logic [7:0] SHADOW0_PENABLE_GLITCH = 8'hA7;

  reg presetn = 1'b0;
  reg psel = 1'b0;
  reg penable = 1'b0;
  reg pwrite = 1'b0;
  reg [7:0] paddr = 8'h00;
  reg [7:0] pwdata = 8'h00;

  wire pready;
  wire [7:0] prdata;
  wire mmio_valid;
  wire mmio_ready;
  wire [7:0] mmio_rdata;
  wire [1:0] state;
  wire [3:0] load_index;
  wire core_rst_n;
  wire prog_we;
  wire [3:0] prog_addr;
  wire [7:0] prog_data;
  wire [127:0] shadow_flat;

  (* anyconst *) logic [1:0] scenario_seed;
  logic [1:0] scenario;
  reg [5:0] step = 6'd0;
  reg past_valid = 1'b0;

  function automatic [7:0] shadow_byte(input [127:0] flat, input [3:0] index);
    begin
      shadow_byte = flat[{index, 3'b000}+:8];
    end
  endfunction

  simple_cpu_apb dut (
      .pclk($global_clock),
      .presetn(presetn),
      .psel(psel),
      .penable(penable),
      .pwrite(pwrite),
      .paddr(paddr),
      .pwdata(pwdata),
      .pready(pready),
      .prdata(prdata),
      .formal_mmio_valid(mmio_valid),
      .formal_mmio_ready(mmio_ready),
      .formal_mmio_rdata(mmio_rdata),
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
    scenario = (scenario_seed > 2'd3) ? 2'd3 : scenario_seed;

    presetn = (step >= 6'd2);
    psel = 1'b0;
    penable = 1'b0;
    pwrite = 1'b0;
    paddr = 8'h00;
    pwdata = 8'h00;

    case (scenario)
      2'd0: begin
        case (step)
          6'd2: begin
            psel = 1'b1;
            penable = 1'b0;
            pwrite = 1'b1;
            paddr = 8'h00;
            pwdata = SHADOW0_SETUP_GLITCH;
          end
          default: begin
          end
        endcase
      end
      2'd1: begin
        case (step)
          6'd2: begin
            psel = 1'b1;
            penable = 1'b0;
            pwrite = 1'b1;
            paddr = ADDR_CONTROL;
            pwdata = 8'h01;
          end
          6'd3: begin
            psel = 1'b0;
            penable = 1'b1;
            pwrite = 1'b1;
            paddr = 8'h00;
            pwdata = SHADOW0_PENABLE_GLITCH;
          end
          6'd4: begin
            psel = 1'b0;
            penable = 1'b1;
            pwrite = 1'b1;
            paddr = ADDR_CONTROL;
            pwdata = 8'h01;
          end
          default: begin
          end
        endcase
      end
      default: begin
        case (step)
          6'd2: begin
            psel = 1'b1;
            penable = 1'b1;
            pwrite = 1'b1;
            paddr = ADDR_CONTROL;
            pwdata = 8'h01;
          end
          6'd19: begin
            psel = 1'b1;
            penable = 1'b1;
            pwrite = 1'b1;
            paddr = 8'h00;
            pwdata = SHADOW0_RUN_UPDATE;
          end
          6'd20: begin
            psel = 1'b1;
            penable = 1'b1;
            pwrite = 1'b1;
            paddr = ADDR_CONTROL;
            pwdata = 8'h00;
          end
          6'd21: begin
            psel = 1'b1;
            penable = 1'b1;
            pwrite = 1'b1;
            paddr = ADDR_CONTROL;
            pwdata = 8'h01;
          end
          default: begin
          end
        endcase
      end
    endcase
  end

  always @(posedge $global_clock) begin
    past_valid <= 1'b1;
    if (step < 6'd24) begin
      step <= step + 6'd1;
    end
  end

  always_comb begin
    assert (mmio_valid == (psel && penable));
    assert (pready == (mmio_valid && mmio_ready));
    assert (prdata == mmio_rdata);
    if (!psel) begin
      assert (pready == 1'b0);
    end
    if (psel && !penable) begin
      assert (pready == 1'b0);
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && (step == 6'd3) && (scenario == 2'd0)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
      assert (shadow_byte(shadow_flat, 4'd0) == 8'h00);
    end

    if (past_valid && (step == 6'd4) && (scenario == 2'd0)) begin
      assert (state == STATE_HOLD);
      assert (shadow_byte(shadow_flat, 4'd0) == 8'h00);
    end

    if (past_valid && (step == 6'd3) && (scenario == 2'd1)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
    end

    if (past_valid && (step == 6'd4) && (scenario == 2'd1)) begin
      assert (state == STATE_HOLD);
      assert (shadow_byte(shadow_flat, 4'd0) == 8'h00);
    end

    if (past_valid && (step == 6'd5) && (scenario == 2'd1)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
      assert (shadow_byte(shadow_flat, 4'd0) == 8'h00);
    end

    if (past_valid && (step == 6'd20) && (scenario[1] == 1'b1)) begin
      assert (state == STATE_RUN);
      assert (!prog_we);
      assert (shadow_byte(shadow_flat, 4'd0) == SHADOW0_RUN_UPDATE);
    end

    if (past_valid && (step == 6'd21) && (scenario[1] == 1'b1)) begin
      assert (state == STATE_HOLD);
      assert (load_index == 4'h0);
    end

    if (past_valid && (step == 6'd22) && (scenario[1] == 1'b1)) begin
      assert (state == STATE_LOAD);
      assert (prog_we);
      assert (prog_addr == 4'h0);
      assert (prog_data == SHADOW0_RUN_UPDATE);
    end
  end
endmodule
