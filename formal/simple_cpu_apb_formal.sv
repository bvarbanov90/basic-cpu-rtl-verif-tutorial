module simple_cpu_apb_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_STATUS = 8'h10;
  localparam logic [7:0] ADDR_ACC = 8'h11;
  localparam logic [7:0] ADDR_PC = 8'h12;
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

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
  wire [7:0] dbg_mem_data;
  wire [7:0] dbg_acc;
  wire [3:0] dbg_pc;
  wire dbg_zero;
  wire dbg_carry;
  wire dbg_neg;
  wire dbg_overflow;
  wire dbg_halted;

  reg [1:0] reset_counter = 2'd0;
  reg past_valid = 1'b0;
  reg saw_setup = 1'b0;
  reg saw_access = 1'b0;
  reg saw_start = 1'b0;
  reg saw_read = 1'b0;

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
      presetn <= 1'b0;
      psel <= 1'b0;
      penable <= 1'b0;
      pwrite <= 1'b0;
      paddr <= 8'h00;
      pwdata <= 8'h00;
      saw_setup <= 1'b0;
      saw_access <= 1'b0;
      saw_start <= 1'b0;
      saw_read <= 1'b0;
    end else begin
      presetn <= 1'b1;
      psel <= $anyseq;
      penable <= $anyseq;
      pwrite <= $anyseq;
      paddr <= $anyseq;
      pwdata <= $anyseq;
      saw_setup <= saw_setup || (psel && !penable);
      saw_access <= saw_access || (psel && penable);
      saw_start <= saw_start || (psel && penable && pwrite && (paddr == ADDR_CONTROL) && pwdata[0]);
      saw_read <= saw_read || (psel && penable && !pwrite && ((paddr == ADDR_CONTROL) || (paddr == ADDR_STATUS)));
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

    if (paddr[7:4] == 4'h0) begin
      assert (prdata == shadow_flat[{paddr[3:0], 3'b000} +: 8]);
    end else if (paddr[7:4] == 4'h2) begin
      assert (prdata == dbg_mem_data);
    end else begin
      case (paddr)
        ADDR_STATUS: begin
          assert (prdata == {3'b000, dbg_halted, dbg_overflow, dbg_neg, dbg_carry, dbg_zero});
        end
        ADDR_ACC: begin
          assert (prdata == dbg_acc);
        end
        ADDR_PC: begin
          assert (prdata == {4'h0, dbg_pc});
        end
        ADDR_CONTROL: begin
          assert (prdata == {6'b000000, (state == STATE_LOAD), (state == STATE_RUN)});
        end
        default: begin
          assert (prdata == 8'h00);
        end
      endcase
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && presetn) begin
      assert (core_rst_n == (state != STATE_HOLD));
      assert (prog_we == (state == STATE_LOAD));
      assert (prog_addr == load_index);
      assert (prog_data == shadow_flat[{load_index, 3'b000} +: 8]);
    end
  end

  always @(posedge $global_clock) begin
    cover (past_valid && saw_setup);
    cover (past_valid && saw_access);
    cover (past_valid && saw_start && (state == STATE_RUN));
    cover (past_valid && saw_setup && saw_access && saw_read);
    cover (past_valid && saw_start && saw_read && dbg_halted);
  end
endmodule
