module simple_cpu_wishbone_formal;
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_STATUS = 8'h10;
  localparam logic [7:0] ADDR_ACC = 8'h11;
  localparam logic [7:0] ADDR_PC = 8'h12;
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  reg wb_rst_i = 1'b1;
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
      wb_rst_i <= 1'b1;
      wb_cyc_i <= 1'b0;
      wb_stb_i <= 1'b0;
      wb_we_i <= 1'b0;
      wb_adr_i <= 8'h00;
      wb_dat_i <= 8'h00;
      saw_setup <= 1'b0;
      saw_access <= 1'b0;
      saw_start <= 1'b0;
      saw_read <= 1'b0;
    end else begin
      wb_rst_i <= 1'b0;
      wb_cyc_i <= $anyseq;
      wb_stb_i <= $anyseq;
      wb_we_i <= $anyseq;
      wb_adr_i <= $anyseq;
      wb_dat_i <= $anyseq;
      saw_setup <= saw_setup || (wb_cyc_i && !wb_stb_i);
      saw_access <= saw_access || (wb_cyc_i && wb_stb_i);
      saw_start <= saw_start || (wb_cyc_i && wb_stb_i && wb_we_i && (wb_adr_i == ADDR_CONTROL) && wb_dat_i[0]);
      saw_read <= saw_read || (wb_cyc_i && wb_stb_i && !wb_we_i && ((wb_adr_i == ADDR_CONTROL) || (wb_adr_i == ADDR_STATUS)));
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

    if (wb_adr_i[7:4] == 4'h0) begin
      assert (wb_dat_o == shadow_flat[{wb_adr_i[3:0], 3'b000} +: 8]);
    end else if (wb_adr_i[7:4] == 4'h2) begin
      assert (wb_dat_o == dbg_mem_data);
    end else begin
      case (wb_adr_i)
        ADDR_STATUS: begin
          assert (wb_dat_o == {3'b000, dbg_halted, dbg_overflow, dbg_neg, dbg_carry, dbg_zero});
        end
        ADDR_ACC: begin
          assert (wb_dat_o == dbg_acc);
        end
        ADDR_PC: begin
          assert (wb_dat_o == {4'h0, dbg_pc});
        end
        ADDR_CONTROL: begin
          assert (wb_dat_o == {6'b000000, (state == STATE_LOAD), (state == STATE_RUN)});
        end
        default: begin
          assert (wb_dat_o == 8'h00);
        end
      endcase
    end
  end

  always @(posedge $global_clock) begin
    if (past_valid && !wb_rst_i) begin
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

