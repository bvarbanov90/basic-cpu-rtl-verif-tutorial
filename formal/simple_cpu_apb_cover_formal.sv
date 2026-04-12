module simple_cpu_apb_cover_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;

  reg presetn = 1'b0;
  reg psel = 1'b0;
  reg penable = 1'b0;
  reg pwrite = 1'b0;
  reg [7:0] paddr = 8'h00;
  reg [7:0] pwdata = 8'h00;

  wire pready;
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

  simple_cpu_apb dut (
      .pclk($global_clock),
      .presetn(presetn),
      .psel(psel),
      .penable(penable),
      .pwrite(pwrite),
      .paddr(paddr),
      .pwdata(pwdata),
      .pready(pready),
      .prdata(),
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
      presetn <= 1'b0;
      psel <= 1'b0;
      penable <= 1'b0;
      pwrite <= 1'b0;
      paddr <= 8'h00;
      pwdata <= 8'h00;
      saw_setup <= 1'b0;
      saw_access <= 1'b0;
      saw_start <= 1'b0;
    end else begin
      presetn <= 1'b1;
      psel <= $anyseq;
      penable <= $anyseq;
      pwrite <= $anyseq;
      paddr <= $anyseq;
      pwdata <= $anyseq;
      saw_setup <= saw_setup || (psel && !penable);
      saw_access <= saw_access || (psel && penable);
      saw_start <= saw_start || (psel && penable && pwrite && (paddr == 8'h30) && pwdata[0]);
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && presetn) begin
      assert (mmio_valid == (psel && penable));
      assert (pready == (mmio_valid && mmio_ready));
      assert (prog_we == (state == 2'd1));
      assert (core_rst_n == (state != STATE_HOLD));
      assert (prog_addr == load_index);
    end
  end

  always @(posedge $global_clock) begin
    cover (past_valid && saw_setup && saw_access && saw_start && dbg_halted);
  end
endmodule
