module simple_cpu_wishbone_cover_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;

  reg wb_rst_i = 1'b1;
  reg wb_cyc_i = 1'b0;
  reg wb_stb_i = 1'b0;
  reg wb_we_i = 1'b0;
  reg [7:0] wb_adr_i = 8'h00;
  reg [7:0] wb_dat_i = 8'h00;

  wire wb_ack_o;
  wire mmio_valid;
  wire mmio_ready;
  wire [1:0] state;
  wire core_rst_n;
  wire prog_we;
  wire [3:0] prog_addr;
  wire [3:0] load_index;
  wire dbg_halted;

  reg [1:0] reset_counter = 2'd0;
  reg past_valid = 1'b0;
  reg saw_setup = 1'b0;
  reg saw_access = 1'b0;
  reg saw_start = 1'b0;

  simple_cpu_wishbone dut (
      .wb_clk_i($global_clock),
      .wb_rst_i(wb_rst_i),
      .wb_cyc_i(wb_cyc_i),
      .wb_stb_i(wb_stb_i),
      .wb_we_i(wb_we_i),
      .wb_adr_i(wb_adr_i),
      .wb_dat_i(wb_dat_i),
      .wb_ack_o(wb_ack_o),
      .wb_dat_o(),
      .formal_mmio_valid(mmio_valid),
      .formal_mmio_ready(mmio_ready),
      .formal_mmio_rdata(),
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
      wb_rst_i <= 1'b1;
      wb_cyc_i <= 1'b0;
      wb_stb_i <= 1'b0;
      wb_we_i <= 1'b0;
      wb_adr_i <= 8'h00;
      wb_dat_i <= 8'h00;
      saw_setup <= 1'b0;
      saw_access <= 1'b0;
      saw_start <= 1'b0;
    end else begin
      wb_rst_i <= 1'b0;
      wb_cyc_i <= $anyseq;
      wb_stb_i <= $anyseq;
      wb_we_i <= $anyseq;
      wb_adr_i <= $anyseq;
      wb_dat_i <= $anyseq;
      saw_setup <= saw_setup || (wb_cyc_i && !wb_stb_i);
      saw_access <= saw_access || (wb_cyc_i && wb_stb_i);
      saw_start <= saw_start || (wb_cyc_i && wb_stb_i && wb_we_i && (wb_adr_i == 8'h30) && wb_dat_i[0]);
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && !wb_rst_i) begin
      assert (mmio_valid == (wb_cyc_i && wb_stb_i));
      assert (wb_ack_o == (mmio_valid && mmio_ready));
      assert (prog_we == (state == 2'd1));
      assert (core_rst_n == (state != STATE_HOLD));
      assert (prog_addr == load_index);
    end
  end

  always @(posedge $global_clock) begin
    cover (past_valid && saw_setup && saw_access && saw_start && dbg_halted);
  end
endmodule

