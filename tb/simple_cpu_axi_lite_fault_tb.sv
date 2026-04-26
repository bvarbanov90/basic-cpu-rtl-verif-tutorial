`timescale 1ns / 1ps

module simple_cpu_axi_lite_fault_tb;
  reg aclk = 1'b0;
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

  reg [7:0] program_mem[0:15];
  integer cov_aw_only_writes_ignored;
  integer cov_w_only_writes_ignored;
  integer cov_split_write_attempts_ignored;
  integer cov_pending_response_blocks_writes;
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

  simple_cpu_axi_lite dut (
      .aclk(aclk),
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
      .axi_rresp(axi_rresp)
  );

  simple_cpu_axi_lite_assertions axi_lite_assertions (
      .aclk(aclk),
      .aresetn(aresetn),
      .axi_awvalid(axi_awvalid),
      .axi_awready(axi_awready),
      .axi_awaddr(axi_awaddr),
      .axi_wvalid(axi_wvalid),
      .axi_wready(axi_wready),
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
      .mmio_valid(dut.mmio_valid),
      .mmio_ready(dut.mmio_ready),
      .mmio_rdata(dut.mmio_rdata),
      .mmio_write(dut.mmio_write),
      .mmio_addr(dut.mmio_addr),
      .read_addr_q(dut.read_addr_q),
      .state(dut.inner.state),
      .load_index(dut.inner.load_index),
      .core_rst_n(dut.inner.core_rst_n),
      .prog_we(dut.inner.prog_we),
      .prog_addr(dut.inner.prog_addr)
  );

  always #5 aclk = ~aclk;

  function automatic [7:0] ins;
    input [3:0] opcode;
    input [3:0] operand;
    begin
      ins = {opcode, operand};
    end
  endfunction

  task automatic cov_init;
    begin
      cov_aw_only_writes_ignored = 0;
      cov_w_only_writes_ignored = 0;
      cov_split_write_attempts_ignored = 0;
      cov_pending_response_blocks_writes = 0;
      cov_shadow_fault_write_observed = 0;
      cov_deferred_shadow_updates = 0;
      cov_reload_observed_updates = 0;
      cov_program_runs = 0;
      cov_fault_readbacks = 0;
    end
  endtask

  task automatic axi_idle;
    begin
      axi_awvalid = 1'b0;
      axi_awaddr = 8'h00;
      axi_wvalid = 1'b0;
      axi_wdata = 8'h00;
      axi_bready = 1'b0;
      axi_arvalid = 1'b0;
      axi_araddr = 8'h00;
      axi_rready = 1'b0;
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
      aresetn = 1'b0;
      axi_idle();
      repeat (3) @(posedge aclk);
      aresetn = 1'b1;
      @(negedge aclk);
    end
  endtask

  task automatic axi_write;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge aclk);
      axi_awvalid = 1'b1;
      axi_awaddr = addr;
      axi_wvalid = 1'b1;
      axi_wdata = data;
      axi_bready = 1'b0;
      #1;
      if (axi_awready !== 1'b1 || axi_wready !== 1'b1) begin
        $fatal(1, "AXI-Lite fault bench expected coupled AW/W ready");
      end

      @(posedge aclk);
      @(negedge aclk);
      axi_awvalid = 1'b0;
      axi_awaddr = 8'h00;
      axi_wvalid = 1'b0;
      axi_wdata = 8'h00;
      #1;
      if (axi_bvalid !== 1'b1 || axi_bresp !== 2'b00) begin
        $fatal(1, "AXI-Lite fault bench expected OKAY B response");
      end

      axi_bready = 1'b1;
      @(posedge aclk);
      @(negedge aclk);
      axi_bready = 1'b0;
    end
  endtask

  task automatic axi_read_now;
    input [7:0] addr;
    output [7:0] data;
    begin
      @(negedge aclk);
      axi_arvalid = 1'b1;
      axi_araddr = addr;
      axi_rready = 1'b0;
      #1;
      if (axi_arready !== 1'b1) begin
        $fatal(1, "AXI-Lite fault bench expected ARREADY");
      end

      @(posedge aclk);
      @(negedge aclk);
      axi_arvalid = 1'b0;
      axi_araddr = 8'h00;
      #1;
      if (axi_rvalid !== 1'b1 || axi_rresp !== 2'b00) begin
        $fatal(1, "AXI-Lite fault bench expected OKAY R response");
      end
      data = axi_rdata;
      cov_fault_readbacks = cov_fault_readbacks + 1;

      axi_rready = 1'b1;
      @(posedge aclk);
      @(negedge aclk);
      axi_rready = 1'b0;
    end
  endtask

  task automatic axi_aw_only_write;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge aclk);
      axi_awvalid = 1'b1;
      axi_awaddr = addr;
      axi_wvalid = 1'b0;
      axi_wdata = data;
      axi_bready = 1'b1;
      #1;
      if (axi_awready !== 1'b0 || axi_wready !== 1'b0 || axi_bvalid !== 1'b0) begin
        $fatal(1, "AXI-Lite AW-only write should not be accepted");
      end

      @(posedge aclk);
      #1;
      if (axi_bvalid !== 1'b0) begin
        $fatal(1, "AXI-Lite AW-only write created a B response");
      end

      @(negedge aclk);
      axi_idle();
    end
  endtask

  task automatic axi_w_only_write;
    input [7:0] data;
    begin
      @(negedge aclk);
      axi_awvalid = 1'b0;
      axi_awaddr = 8'h00;
      axi_wvalid = 1'b1;
      axi_wdata = data;
      axi_bready = 1'b1;
      #1;
      if (axi_awready !== 1'b0 || axi_wready !== 1'b0 || axi_bvalid !== 1'b0) begin
        $fatal(1, "AXI-Lite W-only write should not be accepted");
      end

      @(posedge aclk);
      #1;
      if (axi_bvalid !== 1'b0) begin
        $fatal(1, "AXI-Lite W-only write created a B response");
      end

      @(negedge aclk);
      axi_idle();
    end
  endtask

  task automatic axi_split_write_attempt;
    input [7:0] addr;
    input [7:0] data;
    begin
      axi_aw_only_write(addr, data);
      axi_w_only_write(data);
    end
  endtask

  task automatic axi_write_hold_response;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge aclk);
      axi_awvalid = 1'b1;
      axi_awaddr = addr;
      axi_wvalid = 1'b1;
      axi_wdata = data;
      axi_bready = 1'b0;
      #1;
      if (axi_awready !== 1'b1 || axi_wready !== 1'b1) begin
        $fatal(1, "AXI-Lite held-response write expected ready");
      end

      @(posedge aclk);
      @(negedge aclk);
      axi_awvalid = 1'b0;
      axi_awaddr = 8'h00;
      axi_wvalid = 1'b0;
      axi_wdata = 8'h00;
      #1;
      if (axi_bvalid !== 1'b1) begin
        $fatal(1, "AXI-Lite held-response write expected pending BVALID");
      end
    end
  endtask

  task automatic load_program_shadow;
    integer idx;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        axi_write(idx[7:0], program_mem[idx]);
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
          axi_read_now(ADDR_STATUS, status);
          if (status[4]) begin
            disable poll_loop;
          end
        end
      end
      if (!status[4]) begin
        $fatal(1, "AXI-Lite fault bench timeout waiting for HALT");
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
          axi_read_now(ADDR_CONTROL, control);
          if (control == 8'h01) begin
            disable poll_loop;
          end
        end
      end
      if (control != 8'h01) begin
        $fatal(1, "AXI-Lite fault bench timeout waiting for RUN state");
      end
    end
  endtask

  task automatic expect_shadow_byte;
    input [7:0] addr;
    input [7:0] expected;
    reg [7:0] observed;
    begin
      axi_read_now(addr, observed);
      if (observed !== expected) begin
        $fatal(1, "AXI-Lite fault bench shadow mismatch at %0h: got %0h expected %0h", addr,
               observed, expected);
      end
    end
  endtask

  task automatic expect_control;
    input [7:0] expected;
    reg [7:0] observed;
    begin
      axi_read_now(ADDR_CONTROL, observed);
      if (observed !== expected) begin
        $fatal(1, "AXI-Lite fault bench control mismatch: got %0h expected %0h", observed,
               expected);
      end
    end
  endtask

  task automatic expect_dmem_byte;
    input [3:0] addr;
    input [7:0] expected;
    reg [7:0] observed;
    begin
      axi_read_now(ADDR_DMEM_BASE + {4'h0, addr}, observed);
      if (observed !== expected) begin
        $fatal(1, "AXI-Lite fault bench dmem[%0d] mismatch: got %0h expected %0h", addr,
               observed, expected);
      end
    end
  endtask

  task automatic test_aw_only_shadow_write_ignored;
    begin
      global_reset();
      clear_program();
      expect_shadow_byte(8'h00, 8'h00);
      axi_aw_only_write(8'h00, ins(OPC_LDI, 4'd9));
      expect_shadow_byte(8'h00, 8'h00);
      cov_aw_only_writes_ignored = cov_aw_only_writes_ignored + 1;
      $display("[PASS] axi_lite_fault_aw_only_shadow_write_ignored");
    end
  endtask

  task automatic test_w_only_shadow_write_ignored;
    begin
      global_reset();
      clear_program();
      expect_shadow_byte(8'h00, 8'h00);
      axi_w_only_write(ins(OPC_LDI, 4'd7));
      expect_shadow_byte(8'h00, 8'h00);
      cov_w_only_writes_ignored = cov_w_only_writes_ignored + 1;
      $display("[PASS] axi_lite_fault_w_only_shadow_write_ignored");
    end
  endtask

  task automatic test_split_write_attempt_ignored;
    begin
      global_reset();
      clear_program();
      expect_shadow_byte(8'h01, 8'h00);
      axi_split_write_attempt(8'h01, ins(OPC_LDI, 4'd6));
      expect_shadow_byte(8'h01, 8'h00);
      cov_split_write_attempts_ignored = cov_split_write_attempts_ignored + 1;
      $display("[PASS] axi_lite_fault_split_write_attempt_ignored");
    end
  endtask

  task automatic test_partial_control_start_ignored;
    begin
      global_reset();
      axi_aw_only_write(ADDR_CONTROL, 8'h01);
      axi_w_only_write(8'h01);
      repeat (4) @(posedge aclk);
      expect_control(8'h00);
      cov_aw_only_writes_ignored = cov_aw_only_writes_ignored + 1;
      cov_w_only_writes_ignored = cov_w_only_writes_ignored + 1;
      $display("[PASS] axi_lite_fault_partial_control_start_ignored");
    end
  endtask

  task automatic test_pending_response_blocks_new_write;
    begin
      global_reset();
      clear_program();
      axi_write_hold_response(8'h00, ins(OPC_LDI, 4'd2));

      @(negedge aclk);
      axi_awvalid = 1'b1;
      axi_awaddr = 8'h02;
      axi_wvalid = 1'b1;
      axi_wdata = ins(OPC_LDI, 4'd8);
      axi_bready = 1'b0;
      #1;
      if (axi_awready !== 1'b0 || axi_wready !== 1'b0) begin
        $fatal(1, "AXI-Lite pending B response should block new write acceptance");
      end
      if (axi_bvalid !== 1'b1) begin
        $fatal(1, "AXI-Lite pending B response should remain valid");
      end

      @(posedge aclk);
      @(negedge aclk);
      axi_awvalid = 1'b0;
      axi_awaddr = 8'h00;
      axi_wvalid = 1'b0;
      axi_wdata = 8'h00;
      axi_bready = 1'b1;
      @(posedge aclk);
      @(negedge aclk);
      axi_bready = 1'b0;

      expect_shadow_byte(8'h02, 8'h00);
      cov_pending_response_blocks_writes = cov_pending_response_blocks_writes + 1;
      $display("[PASS] axi_lite_fault_pending_response_blocks_new_write");
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
      axi_write(ADDR_CONTROL, 8'h01);
      wait_for_run_state(32);

      axi_write(8'h00, ins(OPC_LDI, 4'd9));
      axi_read_now(8'h00, observed);
      if (observed !== ins(OPC_LDI, 4'd9)) begin
        $fatal(1, "AXI-Lite fault bench expected shadow update to be visible immediately");
      end
      cov_shadow_fault_write_observed = cov_shadow_fault_write_observed + 1;

      wait_for_halt(160);
      expect_dmem_byte(4'd3, 8'h04);
      cov_program_runs = cov_program_runs + 1;
      cov_deferred_shadow_updates = cov_deferred_shadow_updates + 1;

      axi_write(ADDR_CONTROL, 8'h00);
      expect_control(8'h00);
      axi_write(ADDR_CONTROL, 8'h01);
      wait_for_halt(160);
      expect_dmem_byte(4'd3, 8'h09);
      cov_program_runs = cov_program_runs + 1;
      cov_reload_observed_updates = cov_reload_observed_updates + 1;

      $display("[PASS] axi_lite_fault_run_phase_shadow_update_requires_reload");
    end
  endtask

  task automatic write_axi_lite_fault_coverage_reports;
    input coverage_pass;
    integer fd_json;
    integer fd_csv;
    begin
      fd_json = $fopen("sim_build/axi_lite_fault_coverage.json", "w");
      if (fd_json == 0) begin
        $fatal(1, "Could not open sim_build/axi_lite_fault_coverage.json for write");
      end

      $fwrite(fd_json, "{\n");
      $fwrite(fd_json, "  \"coverage_pass\": %0d,\n", coverage_pass);
      $fwrite(fd_json, "  \"aw_only_writes_ignored\": %0d,\n", cov_aw_only_writes_ignored);
      $fwrite(fd_json, "  \"w_only_writes_ignored\": %0d,\n", cov_w_only_writes_ignored);
      $fwrite(fd_json, "  \"split_write_attempts_ignored\": %0d,\n",
              cov_split_write_attempts_ignored);
      $fwrite(fd_json, "  \"pending_response_blocks_writes\": %0d,\n",
              cov_pending_response_blocks_writes);
      $fwrite(fd_json, "  \"shadow_fault_write_observed\": %0d,\n",
              cov_shadow_fault_write_observed);
      $fwrite(fd_json, "  \"deferred_shadow_updates\": %0d,\n", cov_deferred_shadow_updates);
      $fwrite(fd_json, "  \"reload_observed_updates\": %0d,\n", cov_reload_observed_updates);
      $fwrite(fd_json, "  \"program_runs\": %0d,\n", cov_program_runs);
      $fwrite(fd_json, "  \"fault_readbacks\": %0d,\n", cov_fault_readbacks);
      $fwrite(fd_json, "  \"coverage_goals\": {\n");
      $fwrite(fd_json, "    \"aw_only_writes_ignored_min\": 2,\n");
      $fwrite(fd_json, "    \"w_only_writes_ignored_min\": 2,\n");
      $fwrite(fd_json, "    \"split_write_attempts_ignored_min\": 1,\n");
      $fwrite(fd_json, "    \"pending_response_blocks_writes_min\": 1,\n");
      $fwrite(fd_json, "    \"shadow_fault_write_observed_min\": 1,\n");
      $fwrite(fd_json, "    \"deferred_shadow_updates_min\": 1,\n");
      $fwrite(fd_json, "    \"reload_observed_updates_min\": 1,\n");
      $fwrite(fd_json, "    \"program_runs_min\": 2,\n");
      $fwrite(fd_json, "    \"fault_readbacks_min\": 10\n");
      $fwrite(fd_json, "  }\n");
      $fwrite(fd_json, "}\n");
      $fclose(fd_json);

      fd_csv = $fopen("sim_build/axi_lite_fault_coverage.csv", "w");
      if (fd_csv == 0) begin
        $fatal(1, "Could not open sim_build/axi_lite_fault_coverage.csv for write");
      end

      $fwrite(fd_csv, "metric,value\n");
      $fwrite(fd_csv, "coverage_pass,%0d\n", coverage_pass);
      $fwrite(fd_csv, "aw_only_writes_ignored,%0d\n", cov_aw_only_writes_ignored);
      $fwrite(fd_csv, "w_only_writes_ignored,%0d\n", cov_w_only_writes_ignored);
      $fwrite(fd_csv, "split_write_attempts_ignored,%0d\n", cov_split_write_attempts_ignored);
      $fwrite(fd_csv, "pending_response_blocks_writes,%0d\n", cov_pending_response_blocks_writes);
      $fwrite(fd_csv, "shadow_fault_write_observed,%0d\n", cov_shadow_fault_write_observed);
      $fwrite(fd_csv, "deferred_shadow_updates,%0d\n", cov_deferred_shadow_updates);
      $fwrite(fd_csv, "reload_observed_updates,%0d\n", cov_reload_observed_updates);
      $fwrite(fd_csv, "program_runs,%0d\n", cov_program_runs);
      $fwrite(fd_csv, "fault_readbacks,%0d\n", cov_fault_readbacks);
      $fclose(fd_csv);
    end
  endtask

  task automatic report_and_check_axi_lite_fault_coverage;
    reg coverage_pass;
    begin
      coverage_pass = 1'b1;

      if (cov_aw_only_writes_ignored < 2) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] aw_only_writes_ignored >= 2");
      end
      if (cov_w_only_writes_ignored < 2) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] w_only_writes_ignored >= 2");
      end
      if (cov_split_write_attempts_ignored < 1) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] split_write_attempts_ignored >= 1");
      end
      if (cov_pending_response_blocks_writes < 1) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] pending_response_blocks_writes >= 1");
      end
      if (cov_shadow_fault_write_observed < 1) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] shadow_fault_write_observed >= 1");
      end
      if (cov_deferred_shadow_updates < 1) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] deferred_shadow_updates >= 1");
      end
      if (cov_reload_observed_updates < 1) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] reload_observed_updates >= 1");
      end
      if (cov_program_runs < 2) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] program_runs >= 2");
      end
      if (cov_fault_readbacks < 10) begin
        coverage_pass = 1'b0;
        $display("[AXI-LITE-FAULT-COVERAGE][MISS] fault_readbacks >= 10");
      end

      write_axi_lite_fault_coverage_reports(coverage_pass);
      $display(
          "[AXI-LITE-FAULT-COVERAGE] wrote sim_build/axi_lite_fault_coverage.json and sim_build/axi_lite_fault_coverage.csv");

      if (!coverage_pass) begin
        $fatal(1, "AXI-Lite fault coverage goals not met.");
      end
    end
  endtask

  initial begin
`ifndef NO_WAVES
    $dumpfile("sim_build/simple_cpu_axi_lite_fault_tb.vcd");
    $dumpvars(0, simple_cpu_axi_lite_fault_tb);
`endif

    cov_init();
    test_aw_only_shadow_write_ignored();
    test_w_only_shadow_write_ignored();
    test_split_write_attempt_ignored();
    test_partial_control_start_ignored();
    test_pending_response_blocks_new_write();
    test_run_phase_shadow_update_requires_reload();
    report_and_check_axi_lite_fault_coverage();
    $display("[PASS] all AXI-Lite fault tests");
    $finish;
  end
endmodule
