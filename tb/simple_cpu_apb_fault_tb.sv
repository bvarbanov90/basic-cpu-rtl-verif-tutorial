`timescale 1ns / 1ps

module simple_cpu_apb_fault_tb;
  reg pclk = 1'b0;
  reg presetn = 1'b0;
  reg psel = 1'b0;
  reg penable = 1'b0;
  reg pwrite = 1'b0;
  reg [7:0] paddr = 8'h00;
  reg [7:0] pwdata = 8'h00;

  wire pready;
  wire [7:0] prdata;

  reg [7:0] program_mem[0:15];
  integer cov_setup_only_writes_ignored;
  integer cov_aborted_writes_ignored;
  integer cov_setup_only_starts_ignored;
  integer cov_penable_without_select_ignored;
  integer cov_shadow_fault_write_observed;
  integer cov_deferred_shadow_updates;
  integer cov_reload_observed_updates;
  integer cov_program_runs;
  integer cov_fault_readbacks;

  localparam logic [7:0] ADDR_STATUS = 8'h10;
  localparam logic [7:0] ADDR_CONTROL = 8'h30;
  localparam logic [7:0] ADDR_DMEM_BASE = 8'h20;

  localparam logic [3:0] OPC_NOP = 4'h0;
  localparam logic [3:0] OPC_LDI = 4'h1;
  localparam logic [3:0] OPC_SUB = 4'h3;
  localparam logic [3:0] OPC_STA = 4'h4;
  localparam logic [3:0] OPC_LDA = 4'h5;
  localparam logic [3:0] OPC_JMP = 4'h6;
  localparam logic [3:0] OPC_JZ = 4'h7;
  localparam logic [3:0] OPC_HLT = 4'h8;

  integer i;

  simple_cpu_apb dut (
      .pclk(pclk),
      .presetn(presetn),
      .psel(psel),
      .penable(penable),
      .pwrite(pwrite),
      .paddr(paddr),
      .pwdata(pwdata),
      .pready(pready),
      .prdata(prdata)
  );

  simple_cpu_apb_assertions apb_assertions (
      .pclk(pclk),
      .presetn(presetn),
      .psel(psel),
      .penable(penable),
      .pwrite(pwrite),
      .paddr(paddr),
      .pready(pready),
      .prdata(prdata),
      .mmio_valid(dut.mmio_valid),
      .mmio_ready(dut.mmio_ready),
      .mmio_rdata(dut.mmio_rdata),
      .state(dut.inner.state),
      .load_index(dut.inner.load_index),
      .core_rst_n(dut.inner.core_rst_n),
      .prog_we(dut.inner.prog_we),
      .prog_addr(dut.inner.prog_addr)
  );

  always #5 pclk = ~pclk;

  function automatic [7:0] ins;
    input [3:0] opcode;
    input [3:0] operand;
    begin
      ins = {opcode, operand};
    end
  endfunction

  task automatic cov_init;
    begin
      cov_setup_only_writes_ignored = 0;
      cov_aborted_writes_ignored = 0;
      cov_setup_only_starts_ignored = 0;
      cov_penable_without_select_ignored = 0;
      cov_shadow_fault_write_observed = 0;
      cov_deferred_shadow_updates = 0;
      cov_reload_observed_updates = 0;
      cov_program_runs = 0;
      cov_fault_readbacks = 0;
    end
  endtask

  task automatic apb_idle;
    begin
      psel = 1'b0;
      penable = 1'b0;
      pwrite = 1'b0;
      paddr = 8'h00;
      pwdata = 8'h00;
    end
  endtask

  task automatic clear_program;
    integer idx;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        program_mem[idx] = 8'h00;
      end
    end
  endtask

  task automatic global_reset;
    begin
      presetn = 1'b0;
      apb_idle();
      repeat (3) @(posedge pclk);
      presetn = 1'b1;
    end
  endtask

  task automatic apb_write;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge pclk);
      psel = 1'b1;
      penable = 1'b0;
      pwrite = 1'b1;
      paddr = addr;
      pwdata = data;
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB fault bench expected PREADY low during setup");
      end

      @(negedge pclk);
      penable = 1'b1;
      #1;
      if (pready !== 1'b1) begin
        $fatal(1, "APB fault bench expected PREADY high during access");
      end

      @(posedge pclk);
      @(negedge pclk);
      apb_idle();
    end
  endtask

  task automatic apb_read_now;
    input [7:0] addr;
    output [7:0] data;
    begin
      @(negedge pclk);
      psel = 1'b1;
      penable = 1'b0;
      pwrite = 1'b0;
      paddr = addr;
      pwdata = 8'h00;
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB fault bench expected PREADY low during setup");
      end

      @(negedge pclk);
      penable = 1'b1;
      #1;
      if (pready !== 1'b1) begin
        $fatal(1, "APB fault bench expected PREADY high during access");
      end
      data = prdata;
      cov_fault_readbacks = cov_fault_readbacks + 1;

      @(posedge pclk);
      @(negedge pclk);
      apb_idle();
    end
  endtask

  task automatic apb_setup_write_only;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge pclk);
      psel = 1'b1;
      penable = 1'b0;
      pwrite = 1'b1;
      paddr = addr;
      pwdata = data;
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB setup-only write observed PREADY high");
      end

      @(posedge pclk);
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB setup-only write changed PREADY unexpectedly");
      end

      @(negedge pclk);
      apb_idle();
    end
  endtask

  task automatic apb_setup_then_abort;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge pclk);
      psel = 1'b1;
      penable = 1'b0;
      pwrite = 1'b1;
      paddr = addr;
      pwdata = data;
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB aborted write observed PREADY high during setup");
      end

      @(negedge pclk);
      apb_idle();
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB aborted write left PREADY high while idle");
      end
    end
  endtask

  task automatic apb_penable_without_select_write;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge pclk);
      psel = 1'b0;
      penable = 1'b1;
      pwrite = 1'b1;
      paddr = addr;
      pwdata = data;
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB fault bench saw PREADY high with PENABLE but no PSEL");
      end

      @(posedge pclk);
      #1;
      if (pready !== 1'b0) begin
        $fatal(1, "APB fault bench saw PREADY change during PENABLE-without-PSEL glitch");
      end

      @(negedge pclk);
      apb_idle();
    end
  endtask

  task automatic load_program_shadow;
    integer idx;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        apb_write(idx[7:0], program_mem[idx]);
      end
    end
  endtask

  task automatic wait_for_halt;
    input integer max_polls;
    integer poll;
    reg [7:0] status;
    begin
      status = 8'h00;
      begin : poll_loop
        for (poll = 0; poll < max_polls; poll = poll + 1) begin
          apb_read_now(ADDR_STATUS, status);
          if (status[4]) begin
            disable poll_loop;
          end
        end
      end
      if (!status[4]) begin
        $fatal(1, "APB fault bench timeout waiting for HALT");
      end
    end
  endtask

  task automatic wait_for_run_state;
    input integer max_polls;
    integer poll;
    reg [7:0] control;
    begin
      control = 8'h00;
      begin : poll_loop
        for (poll = 0; poll < max_polls; poll = poll + 1) begin
          apb_read_now(ADDR_CONTROL, control);
          if (control == 8'h01) begin
            disable poll_loop;
          end
        end
      end
      if (control != 8'h01) begin
        $fatal(1, "APB fault bench timeout waiting for RUN state");
      end
    end
  endtask

  task automatic expect_shadow_byte;
    input [7:0] addr;
    input [7:0] expected;
    reg [7:0] observed;
    begin
      apb_read_now(addr, observed);
      if (observed !== expected) begin
        $fatal(1, "APB fault bench shadow mismatch at %0h: got %0h expected %0h", addr, observed,
               expected);
      end
    end
  endtask

  task automatic expect_control;
    input [7:0] expected;
    reg [7:0] observed;
    begin
      apb_read_now(ADDR_CONTROL, observed);
      if (observed !== expected) begin
        $fatal(1, "APB fault bench control mismatch: got %0h expected %0h", observed, expected);
      end
    end
  endtask

  task automatic expect_dmem_byte;
    input [3:0] addr;
    input [7:0] expected;
    reg [7:0] observed;
    begin
      apb_read_now(ADDR_DMEM_BASE + {4'h0, addr}, observed);
      if (observed !== expected) begin
        $fatal(1, "APB fault bench dmem[%0d] mismatch: got %0h expected %0h", addr, observed,
               expected);
      end
    end
  endtask

  task automatic test_setup_only_shadow_write_ignored;
    begin
      global_reset();
      clear_program();
      expect_shadow_byte(8'h00, 8'h00);
      apb_setup_write_only(8'h00, ins(OPC_LDI, 4'd9));
      expect_shadow_byte(8'h00, 8'h00);
      cov_setup_only_writes_ignored = cov_setup_only_writes_ignored + 1;
      $display("[PASS] apb_fault_setup_only_shadow_write_ignored");
    end
  endtask

  task automatic test_aborted_shadow_write_ignored;
    begin
      global_reset();
      clear_program();
      expect_shadow_byte(8'h01, 8'h00);
      apb_setup_then_abort(8'h01, ins(OPC_LDI, 4'd6));
      expect_shadow_byte(8'h01, 8'h00);
      cov_aborted_writes_ignored = cov_aborted_writes_ignored + 1;
      $display("[PASS] apb_fault_aborted_shadow_write_ignored");
    end
  endtask

  task automatic test_setup_only_control_start_ignored;
    begin
      global_reset();
      apb_setup_write_only(ADDR_CONTROL, 8'h01);
      repeat (4) @(posedge pclk);
      expect_control(8'h00);
      cov_setup_only_starts_ignored = cov_setup_only_starts_ignored + 1;
      $display("[PASS] apb_fault_setup_only_start_ignored");
    end
  endtask

  task automatic test_penable_without_select_ignored;
    begin
      global_reset();
      apb_penable_without_select_write(8'h00, ins(OPC_LDI, 4'd7));
      expect_shadow_byte(8'h00, 8'h00);
      apb_penable_without_select_write(ADDR_CONTROL, 8'h01);
      repeat (4) @(posedge pclk);
      expect_control(8'h00);
      cov_penable_without_select_ignored = cov_penable_without_select_ignored + 1;
      $display("[PASS] apb_fault_penable_without_select_ignored");
    end
  endtask

  task automatic test_run_phase_shadow_update_requires_reload;
    reg [7:0] observed;
    begin
      global_reset();
      clear_program();
      program_mem[0]  = ins(OPC_LDI, 4'd4);
      program_mem[1]  = ins(OPC_STA, 4'd0);
      program_mem[2]  = ins(OPC_LDI, 4'd4);
      program_mem[3]  = ins(OPC_STA, 4'd1);
      program_mem[4]  = ins(OPC_LDI, 4'd1);
      program_mem[5]  = ins(OPC_STA, 4'd2);
      program_mem[6]  = ins(OPC_LDA, 4'd1);
      program_mem[7]  = ins(OPC_SUB, 4'd2);
      program_mem[8]  = ins(OPC_STA, 4'd1);
      program_mem[9]  = ins(OPC_JZ, 4'd12);
      program_mem[10] = ins(OPC_JMP, 4'd6);
      program_mem[11] = ins(OPC_NOP, 4'd0);
      program_mem[12] = ins(OPC_LDA, 4'd0);
      program_mem[13] = ins(OPC_STA, 4'd3);
      program_mem[14] = ins(OPC_HLT, 4'd0);

      load_program_shadow();
      apb_write(ADDR_CONTROL, 8'h01);
      wait_for_run_state(32);

      apb_write(8'h00, ins(OPC_LDI, 4'd9));
      apb_read_now(8'h00, observed);
      if (observed !== ins(OPC_LDI, 4'd9)) begin
        $fatal(1, "APB fault bench expected shadow update to be visible immediately");
      end
      cov_shadow_fault_write_observed = cov_shadow_fault_write_observed + 1;

      wait_for_halt(160);
      expect_dmem_byte(4'd3, 8'h04);
      cov_program_runs = cov_program_runs + 1;
      cov_deferred_shadow_updates = cov_deferred_shadow_updates + 1;

      apb_write(ADDR_CONTROL, 8'h00);
      expect_control(8'h00);
      apb_write(ADDR_CONTROL, 8'h01);
      wait_for_halt(160);
      expect_dmem_byte(4'd3, 8'h09);
      cov_program_runs = cov_program_runs + 1;
      cov_reload_observed_updates = cov_reload_observed_updates + 1;

      $display("[PASS] apb_fault_run_phase_shadow_update_requires_reload");
    end
  endtask

  task automatic write_apb_fault_coverage_reports;
    input coverage_pass;
    integer fd_json;
    integer fd_csv;
    begin
      fd_json = $fopen("sim_build/apb_fault_coverage.json", "w");
      if (fd_json == 0) begin
        $fatal(1, "Could not open sim_build/apb_fault_coverage.json for write");
      end

      $fwrite(fd_json, "{\n");
      $fwrite(fd_json, "  \"coverage_pass\": %0d,\n", coverage_pass);
      $fwrite(fd_json, "  \"setup_only_writes_ignored\": %0d,\n", cov_setup_only_writes_ignored);
      $fwrite(fd_json, "  \"aborted_writes_ignored\": %0d,\n", cov_aborted_writes_ignored);
      $fwrite(fd_json, "  \"setup_only_starts_ignored\": %0d,\n", cov_setup_only_starts_ignored);
      $fwrite(fd_json, "  \"penable_without_select_ignored\": %0d,\n",
              cov_penable_without_select_ignored);
      $fwrite(fd_json, "  \"shadow_fault_write_observed\": %0d,\n",
              cov_shadow_fault_write_observed);
      $fwrite(fd_json, "  \"deferred_shadow_updates\": %0d,\n", cov_deferred_shadow_updates);
      $fwrite(fd_json, "  \"reload_observed_updates\": %0d,\n", cov_reload_observed_updates);
      $fwrite(fd_json, "  \"program_runs\": %0d,\n", cov_program_runs);
      $fwrite(fd_json, "  \"fault_readbacks\": %0d,\n", cov_fault_readbacks);
      $fwrite(fd_json, "  \"coverage_goals\": {\n");
      $fwrite(fd_json, "    \"setup_only_writes_ignored_min\": 1,\n");
      $fwrite(fd_json, "    \"aborted_writes_ignored_min\": 1,\n");
      $fwrite(fd_json, "    \"setup_only_starts_ignored_min\": 1,\n");
      $fwrite(fd_json, "    \"penable_without_select_ignored_min\": 1,\n");
      $fwrite(fd_json, "    \"shadow_fault_write_observed_min\": 1,\n");
      $fwrite(fd_json, "    \"deferred_shadow_updates_min\": 1,\n");
      $fwrite(fd_json, "    \"reload_observed_updates_min\": 1,\n");
      $fwrite(fd_json, "    \"program_runs_min\": 2,\n");
      $fwrite(fd_json, "    \"fault_readbacks_min\": 8\n");
      $fwrite(fd_json, "  }\n");
      $fwrite(fd_json, "}\n");
      $fclose(fd_json);

      fd_csv = $fopen("sim_build/apb_fault_coverage.csv", "w");
      if (fd_csv == 0) begin
        $fatal(1, "Could not open sim_build/apb_fault_coverage.csv for write");
      end

      $fwrite(fd_csv, "metric,value\n");
      $fwrite(fd_csv, "coverage_pass,%0d\n", coverage_pass);
      $fwrite(fd_csv, "setup_only_writes_ignored,%0d\n", cov_setup_only_writes_ignored);
      $fwrite(fd_csv, "aborted_writes_ignored,%0d\n", cov_aborted_writes_ignored);
      $fwrite(fd_csv, "setup_only_starts_ignored,%0d\n", cov_setup_only_starts_ignored);
      $fwrite(fd_csv, "penable_without_select_ignored,%0d\n", cov_penable_without_select_ignored);
      $fwrite(fd_csv, "shadow_fault_write_observed,%0d\n", cov_shadow_fault_write_observed);
      $fwrite(fd_csv, "deferred_shadow_updates,%0d\n", cov_deferred_shadow_updates);
      $fwrite(fd_csv, "reload_observed_updates,%0d\n", cov_reload_observed_updates);
      $fwrite(fd_csv, "program_runs,%0d\n", cov_program_runs);
      $fwrite(fd_csv, "fault_readbacks,%0d\n", cov_fault_readbacks);
      $fclose(fd_csv);
    end
  endtask

  task automatic report_and_check_apb_fault_coverage;
    reg coverage_pass;
    begin
      coverage_pass = 1'b1;

      if (cov_setup_only_writes_ignored < 1) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] setup_only_writes_ignored >= 1");
      end
      if (cov_aborted_writes_ignored < 1) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] aborted_writes_ignored >= 1");
      end
      if (cov_setup_only_starts_ignored < 1) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] setup_only_starts_ignored >= 1");
      end
      if (cov_penable_without_select_ignored < 1) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] penable_without_select_ignored >= 1");
      end
      if (cov_shadow_fault_write_observed < 1) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] shadow_fault_write_observed >= 1");
      end
      if (cov_deferred_shadow_updates < 1) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] deferred_shadow_updates >= 1");
      end
      if (cov_reload_observed_updates < 1) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] reload_observed_updates >= 1");
      end
      if (cov_program_runs < 2) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] program_runs >= 2");
      end
      if (cov_fault_readbacks < 8) begin
        coverage_pass = 1'b0;
        $display("[APB-FAULT-COVERAGE][MISS] fault_readbacks >= 8");
      end

      write_apb_fault_coverage_reports(coverage_pass);
      $display(
          "[APB-FAULT-COVERAGE] wrote sim_build/apb_fault_coverage.json and sim_build/apb_fault_coverage.csv");

      if (!coverage_pass) begin
        $fatal(1, "APB fault coverage goals not met.");
      end
    end
  endtask

  initial begin
`ifndef NO_WAVES
    $dumpfile("sim_build/simple_cpu_apb_fault_tb.vcd");
    $dumpvars(0, simple_cpu_apb_fault_tb);
`endif

    cov_init();
    test_setup_only_shadow_write_ignored();
    test_aborted_shadow_write_ignored();
    test_setup_only_control_start_ignored();
    test_penable_without_select_ignored();
    test_run_phase_shadow_update_requires_reload();
    report_and_check_apb_fault_coverage();
    $display("[PASS] all apb fault tests");
    $finish;
  end
endmodule
