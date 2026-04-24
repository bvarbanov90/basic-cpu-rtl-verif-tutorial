module simple_cpu_wishbone_fault_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_CONTROL = 8'h30;
  localparam logic [7:0] SHADOW0_RUN_UPDATE = 8'h19;
  localparam logic [7:0] SHADOW0_CYCLE_GLITCH = 8'hA9;
  localparam logic [7:0] SHADOW0_STROBE_GLITCH = 8'hA7;

  reg wb_rst_i = 1'b0;
  reg wb_cyc_i = 1'b0;
  reg wb_stb_i = 1'b0;
  reg wb_we_i = 1'b0;
  reg [7:0] wb_adr_i = 8'h00;
  reg [7:0] wb_dat_i = 8'h00;

  wire wb_ack_o;
  wire [7:0] wb_dat_o;
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

  simple_cpu_wishbone dut (
      .wb_clk_i($global_clock),
      .wb_rst_i(wb_rst_i),
      .wb_cyc_i(wb_cyc_i),
      .wb_stb_i(wb_stb_i),
      .wb_we_i(wb_we_i),
      .wb_adr_i(wb_adr_i),
      .wb_dat_i(wb_dat_i),
      .wb_ack_o(wb_ack_o),
      .wb_dat_o(wb_dat_o),
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

    wb_rst_i = (step < 6'd2);
    wb_cyc_i = 1'b0;
    wb_stb_i = 1'b0;
    wb_we_i  = 1'b0;
    wb_adr_i = 8'h00;
    wb_dat_i = 8'h00;

    case (scenario)
      2'd0: begin
        case (step)
          6'd2: begin
            wb_cyc_i = 1'b1;
            wb_stb_i = 1'b0;
            wb_we_i  = 1'b1;
            wb_adr_i = 8'h00;
            wb_dat_i = SHADOW0_CYCLE_GLITCH;
          end
          default: begin
          end
        endcase
      end
      2'd1: begin
        case (step)
          6'd2: begin
            wb_cyc_i = 1'b1;
            wb_stb_i = 1'b0;
            wb_we_i  = 1'b1;
            wb_adr_i = ADDR_CONTROL;
            wb_dat_i = 8'h01;
          end
          6'd3: begin
            wb_cyc_i = 1'b0;
            wb_stb_i = 1'b1;
            wb_we_i  = 1'b1;
            wb_adr_i = 8'h00;
            wb_dat_i = SHADOW0_STROBE_GLITCH;
          end
          6'd4: begin
            wb_cyc_i = 1'b0;
            wb_stb_i = 1'b1;
            wb_we_i  = 1'b1;
            wb_adr_i = ADDR_CONTROL;
            wb_dat_i = 8'h01;
          end
          default: begin
          end
        endcase
      end
      default: begin
        case (step)
          6'd2: begin
            wb_cyc_i = 1'b1;
            wb_stb_i = 1'b1;
            wb_we_i  = 1'b1;
            wb_adr_i = ADDR_CONTROL;
            wb_dat_i = 8'h01;
          end
          6'd19: begin
            wb_cyc_i = 1'b1;
            wb_stb_i = 1'b1;
            wb_we_i  = 1'b1;
            wb_adr_i = 8'h00;
            wb_dat_i = SHADOW0_RUN_UPDATE;
          end
          6'd20: begin
            wb_cyc_i = 1'b1;
            wb_stb_i = 1'b1;
            wb_we_i  = 1'b1;
            wb_adr_i = ADDR_CONTROL;
            wb_dat_i = 8'h00;
          end
          6'd21: begin
            wb_cyc_i = 1'b1;
            wb_stb_i = 1'b1;
            wb_we_i  = 1'b1;
            wb_adr_i = ADDR_CONTROL;
            wb_dat_i = 8'h01;
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
    assert (mmio_valid == (wb_cyc_i && wb_stb_i));
    assert (wb_ack_o == (mmio_valid && mmio_ready));
    assert (wb_dat_o == mmio_rdata);
    if (!wb_cyc_i) begin
      assert (wb_ack_o == 1'b0);
    end
    if (wb_cyc_i && !wb_stb_i) begin
      assert (wb_ack_o == 1'b0);
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
