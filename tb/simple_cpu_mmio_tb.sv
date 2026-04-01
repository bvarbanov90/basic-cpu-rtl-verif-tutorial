`timescale 1ns / 1ps

module simple_cpu_mmio_tb;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg bus_valid = 1'b0;
  reg bus_write = 1'b0;
  reg [7:0] bus_addr = 8'h00;
  reg [7:0] bus_wdata = 8'h00;

  wire bus_ready;
  wire [7:0] bus_rdata;

  reg [7:0] program_mem[0:15];
  reg [7:0] ref_dmem[0:15];
  reg [7:0] ref_acc;
  reg [3:0] ref_pc;
  reg ref_zero;
  reg ref_carry;
  reg ref_neg;
  reg ref_overflow;
  reg ref_halted;
  reg [8*260-1:0] external_program_hex;
  integer cov_shadow_writes;
  integer cov_shadow_reads;
  integer cov_status_reads;
  integer cov_acc_reads;
  integer cov_pc_reads;
  integer cov_dmem_reads;
  integer cov_control_reads;
  integer cov_control_start_writes;
  integer cov_control_stop_writes;
  integer cov_program_runs;
  integer cov_external_program_runs;
  reg cov_hold_state_seen;
  reg cov_load_state_seen;
  reg cov_run_state_seen;

  localparam logic [7:0] ADDR_STATUS = 8'h10;
  localparam logic [7:0] ADDR_ACC = 8'h11;
  localparam logic [7:0] ADDR_PC = 8'h12;
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  localparam logic [3:0] OPC_NOP = 4'h0;
  localparam logic [3:0] OPC_LDI = 4'h1;
  localparam logic [3:0] OPC_ADD = 4'h2;
  localparam logic [3:0] OPC_SUB = 4'h3;
  localparam logic [3:0] OPC_STA = 4'h4;
  localparam logic [3:0] OPC_LDA = 4'h5;
  localparam logic [3:0] OPC_JMP = 4'h6;
  localparam logic [3:0] OPC_JZ = 4'h7;
  localparam logic [3:0] OPC_HLT = 4'h8;
  localparam logic [3:0] OPC_AND = 4'h9;
  localparam logic [3:0] OPC_OR = 4'hA;
  localparam logic [3:0] OPC_XOR = 4'hB;
  localparam logic [3:0] OPC_SHL = 4'hC;
  localparam logic [3:0] OPC_SHR = 4'hD;
  localparam logic [3:0] OPC_CMP = 4'hE;
  integer i;

  simple_cpu_mmio dut (
      .clk(clk),
      .rst_n(rst_n),
      .bus_valid(bus_valid),
      .bus_write(bus_write),
      .bus_addr(bus_addr),
      .bus_wdata(bus_wdata),
      .bus_ready(bus_ready),
      .bus_rdata(bus_rdata)
  );

  simple_cpu_mmio_assertions mmio_assertions (
      .clk(clk),
      .rst_n(rst_n),
      .bus_valid(bus_valid),
      .bus_write(bus_write),
      .bus_addr(bus_addr),
      .bus_ready(bus_ready),
      .bus_rdata(bus_rdata),
      .state(dut.state),
      .load_index(dut.load_index),
      .core_rst_n(dut.core_rst_n),
      .prog_we(dut.prog_we),
      .prog_addr(dut.prog_addr)
  );

  always #5 clk = ~clk;

  always @(posedge clk) begin
    if (rst_n && bus_valid && (bus_ready !== 1'b1)) begin
      $fatal(1, "MMIO protocol violation: bus_ready must stay asserted");
    end
  end

  function automatic [7:0] ins;
    input [3:0] opcode;
    input [3:0] operand;
    begin
      ins = {opcode, operand};
    end
  endfunction

  task automatic cov_init;
    begin
      cov_shadow_writes = 0;
      cov_shadow_reads = 0;
      cov_status_reads = 0;
      cov_acc_reads = 0;
      cov_pc_reads = 0;
      cov_dmem_reads = 0;
      cov_control_reads = 0;
      cov_control_start_writes = 0;
      cov_control_stop_writes = 0;
      cov_program_runs = 0;
      cov_external_program_runs = 0;
      cov_hold_state_seen = 1'b0;
      cov_load_state_seen = 1'b0;
      cov_run_state_seen = 1'b0;
    end
  endtask

  task automatic bus_idle;
    begin
      bus_valid = 1'b0;
      bus_write = 1'b0;
      bus_addr  = 8'h00;
      bus_wdata = 8'h00;
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
      rst_n = 1'b0;
      bus_idle();
      repeat (3) @(posedge clk);
      rst_n = 1'b1;
    end
  endtask

  task automatic mmio_write;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge clk);
      bus_valid = 1'b1;
      bus_write = 1'b1;
      bus_addr  = addr;
      bus_wdata = data;
      @(posedge clk);
      #1;
      if (bus_ready !== 1'b1) begin
        $fatal(1, "MMIO write observed bus_ready deasserted");
      end
      if (addr[7:4] == 4'h0) begin
        cov_shadow_writes = cov_shadow_writes + 1;
      end else if (addr == ADDR_CONTROL) begin
        if (data[0]) begin
          cov_control_start_writes = cov_control_start_writes + 1;
        end else begin
          cov_control_stop_writes = cov_control_stop_writes + 1;
        end
      end
      bus_idle();
    end
  endtask

  task automatic mmio_read_now;
    input [7:0] addr;
    output [7:0] data;
    begin
      bus_valid = 1'b1;
      bus_write = 1'b0;
      bus_addr  = addr;
      bus_wdata = 8'h00;
      #1;
      if (bus_ready !== 1'b1) begin
        $fatal(1, "MMIO read observed bus_ready deasserted");
      end
      data = bus_rdata;
      if (addr[7:4] == 4'h0) begin
        cov_shadow_reads = cov_shadow_reads + 1;
      end else if (addr[7:4] == 4'h2) begin
        cov_dmem_reads = cov_dmem_reads + 1;
      end else begin
        case (addr)
          ADDR_STATUS: cov_status_reads = cov_status_reads + 1;
          ADDR_ACC: cov_acc_reads = cov_acc_reads + 1;
          ADDR_PC: cov_pc_reads = cov_pc_reads + 1;
          ADDR_CONTROL: begin
            cov_control_reads = cov_control_reads + 1;
            if (data[1]) begin
              cov_load_state_seen = 1'b1;
            end else if (data[0]) begin
              cov_run_state_seen = 1'b1;
            end else begin
              cov_hold_state_seen = 1'b1;
            end
          end
          default: begin
          end
        endcase
      end
      bus_idle();
    end
  endtask

  task automatic load_program_shadow;
    integer idx;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        mmio_write(idx[7:0], program_mem[idx]);
      end
    end
  endtask

  task automatic check_program_shadow;
    integer idx;
    reg [7:0] observed;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        mmio_read_now(idx[7:0], observed);
        if (observed !== program_mem[idx]) begin
          $fatal(1, "MMIO shadow mismatch at imem[%0d]: got %0h expected %0h", idx, observed,
                 program_mem[idx]);
        end
      end
    end
  endtask

  task automatic wait_for_halt;
    input integer max_cycles;
    integer cycle;
    reg [7:0] status;
    begin
      begin : poll_loop
        for (cycle = 0; cycle < max_cycles; cycle = cycle + 1) begin
          @(posedge clk);
          mmio_read_now(ADDR_STATUS, status);
          if (status[4]) begin
            disable poll_loop;
          end
        end
      end
      if (!status[4]) begin
        $fatal(1, "MMIO timeout: wrapper/core did not halt in %0d cycles", max_cycles);
      end
    end
  endtask

  task automatic wait_for_run_state;
    input integer max_cycles;
    integer cycle;
    reg [7:0] control;
    begin
      control = 8'h00;
      begin : poll_loop
        for (cycle = 0; cycle < max_cycles; cycle = cycle + 1) begin
          @(posedge clk);
          mmio_read_now(ADDR_CONTROL, control);
          if (control == 8'h01) begin
            disable poll_loop;
          end
        end
      end
      if (control != 8'h01) begin
        $fatal(1, "MMIO timeout: wrapper did not reach RUN in %0d cycles", max_cycles);
      end
    end
  endtask

  task automatic run_reference_model;
    input integer max_cycles;
    reg [7:0] model_imem[0:15];
    reg [7:0] model_dmem[0:15];
    reg [7:0] model_acc;
    reg [3:0] model_pc;
    reg model_zero;
    reg model_carry;
    reg model_neg;
    reg model_overflow;
    reg model_halted;
    reg [7:0] instr;
    reg [3:0] opcode;
    reg [3:0] operand;
    reg [7:0] next_acc;
    reg [3:0] next_pc;
    reg next_zero;
    reg next_carry;
    reg next_neg;
    reg next_overflow;
    reg next_halted;
    reg [7:0] op_b;
    reg [8:0] add_result;
    reg [8:0] sub_result;
    reg [7:0] shift_left_result;
    reg [7:0] shift_right_result;
    integer cycle;
    integer idx;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        model_imem[idx] = program_mem[idx];
        model_dmem[idx] = 8'h00;
      end

      model_acc = 8'h00;
      model_pc = 4'h0;
      model_zero = 1'b1;
      model_carry = 1'b0;
      model_neg = 1'b0;
      model_overflow = 1'b0;
      model_halted = 1'b0;
      cycle = 0;

      while (!model_halted && cycle < max_cycles) begin
        instr = model_imem[model_pc];
        opcode = instr[7:4];
        operand = instr[3:0];
        op_b = model_dmem[operand];
        add_result = {1'b0, model_acc} + {1'b0, op_b};
        sub_result = {1'b0, model_acc} - {1'b0, op_b};
        shift_left_result = {model_acc[6:0], 1'b0};
        shift_right_result = {1'b0, model_acc[7:1]};

        next_acc = model_acc;
        next_pc = model_pc + 4'd1;
        next_zero = model_zero;
        next_carry = model_carry;
        next_neg = model_neg;
        next_overflow = model_overflow;
        next_halted = model_halted;

        case (opcode)
          OPC_NOP: begin
          end
          OPC_LDI: begin
            next_acc = {4'h0, operand};
            next_zero = ({4'h0, operand} == 8'h00);
            next_neg = 1'b0;
            next_carry = 1'b0;
            next_overflow = 1'b0;
          end
          OPC_ADD: begin
            next_acc = add_result[7:0];
            next_zero = (add_result[7:0] == 8'h00);
            next_neg = add_result[7];
            next_carry = add_result[8];
            next_overflow = (~(model_acc[7] ^ op_b[7])) & (model_acc[7] ^ add_result[7]);
          end
          OPC_SUB: begin
            next_acc = sub_result[7:0];
            next_zero = (sub_result[7:0] == 8'h00);
            next_neg = sub_result[7];
            next_carry = ~sub_result[8];
            next_overflow = (model_acc[7] ^ op_b[7]) & (model_acc[7] ^ sub_result[7]);
          end
          OPC_STA: begin
          end
          OPC_LDA: begin
            next_acc = op_b;
            next_zero = (op_b == 8'h00);
            next_neg = op_b[7];
            next_carry = 1'b0;
            next_overflow = 1'b0;
          end
          OPC_JMP: begin
            next_pc = operand;
          end
          OPC_JZ: begin
            if (model_zero) begin
              next_pc = operand;
            end
          end
          OPC_HLT: begin
            next_pc = model_pc;
            next_halted = 1'b1;
          end
          OPC_AND: begin
            next_acc = model_acc & op_b;
            next_zero = ((model_acc & op_b) == 8'h00);
            next_neg = ((model_acc & op_b & 8'h80) != 8'h00);
            next_carry = 1'b0;
            next_overflow = 1'b0;
          end
          OPC_OR: begin
            next_acc = model_acc | op_b;
            next_zero = ((model_acc | op_b) == 8'h00);
            next_neg = (((model_acc | op_b) & 8'h80) != 8'h00);
            next_carry = 1'b0;
            next_overflow = 1'b0;
          end
          OPC_XOR: begin
            next_acc = model_acc ^ op_b;
            next_zero = ((model_acc ^ op_b) == 8'h00);
            next_neg = (((model_acc ^ op_b) & 8'h80) != 8'h00);
            next_carry = 1'b0;
            next_overflow = 1'b0;
          end
          OPC_SHL: begin
            next_acc = shift_left_result;
            next_zero = (shift_left_result == 8'h00);
            next_neg = shift_left_result[7];
            next_carry = model_acc[7];
            next_overflow = model_acc[7] ^ shift_left_result[7];
          end
          OPC_SHR: begin
            next_acc = shift_right_result;
            next_zero = (shift_right_result == 8'h00);
            next_neg = shift_right_result[7];
            next_carry = model_acc[0];
            next_overflow = 1'b0;
          end
          OPC_CMP: begin
            next_zero = (sub_result[7:0] == 8'h00);
            next_neg = sub_result[7];
            next_carry = ~sub_result[8];
            next_overflow = (model_acc[7] ^ op_b[7]) & (model_acc[7] ^ sub_result[7]);
          end
          default: begin
            next_pc = model_pc;
            next_halted = 1'b1;
          end
        endcase

        if (opcode == OPC_STA) begin
          model_dmem[operand] = model_acc;
        end

        model_acc = next_acc;
        model_pc = next_pc;
        model_zero = next_zero;
        model_carry = next_carry;
        model_neg = next_neg;
        model_overflow = next_overflow;
        model_halted = next_halted;
        cycle = cycle + 1;
      end

      if (!model_halted) begin
        $fatal(1, "MMIO reference model timeout");
      end

      ref_acc = model_acc;
      ref_pc = model_pc;
      ref_zero = model_zero;
      ref_carry = model_carry;
      ref_neg = model_neg;
      ref_overflow = model_overflow;
      ref_halted = model_halted;
      for (idx = 0; idx < 16; idx = idx + 1) begin
        ref_dmem[idx] = model_dmem[idx];
      end
    end
  endtask

  task automatic check_against_reference;
    integer idx;
    reg [7:0] observed;
    reg [7:0] status;
    begin
      mmio_read_now(ADDR_STATUS, status);
      mmio_read_now(ADDR_ACC, observed);
      if (observed !== ref_acc) begin
        $fatal(1, "MMIO ACC mismatch: got %0h expected %0h", observed, ref_acc);
      end

      mmio_read_now(ADDR_PC, observed);
      if (observed[3:0] !== ref_pc) begin
        $fatal(1, "MMIO PC mismatch: got %0h expected %0h", observed[3:0], ref_pc);
      end

      if (status[0] !== ref_zero) begin
        $fatal(1, "MMIO ZERO mismatch");
      end
      if (status[1] !== ref_carry) begin
        $fatal(1, "MMIO CARRY mismatch");
      end
      if (status[2] !== ref_neg) begin
        $fatal(1, "MMIO NEG mismatch");
      end
      if (status[3] !== ref_overflow) begin
        $fatal(1, "MMIO OVERFLOW mismatch");
      end
      if (status[4] !== ref_halted) begin
        $fatal(1, "MMIO HALTED mismatch");
      end

      for (idx = 0; idx < 16; idx = idx + 1) begin
        mmio_read_now(8'h20 + idx[7:0], observed);
        if (observed !== ref_dmem[idx]) begin
          $fatal(1, "MMIO dmem[%0d] mismatch: got %0h expected %0h", idx, observed, ref_dmem[idx]);
        end
      end
    end
  endtask

  task automatic run_program_via_mmio;
    input integer max_cycles;
    reg [7:0] control;
    begin
      mmio_write(ADDR_CONTROL, 8'h00);
      mmio_read_now(ADDR_CONTROL, control);
      if (control !== 8'h00) begin
        $fatal(1, "MMIO control expected HOLD state before programming, got %0h", control);
      end

      load_program_shadow();
      check_program_shadow();
      run_reference_model(max_cycles);

      mmio_write(ADDR_CONTROL, 8'h01);
      mmio_read_now(ADDR_CONTROL, control);
      if (control[1] !== 1'b1) begin
        $fatal(1, "MMIO expected loader-active state immediately after start, got %0h", control);
      end

      wait_for_halt(max_cycles + 48);
      mmio_read_now(ADDR_CONTROL, control);
      if (control[0] !== 1'b1) begin
        $fatal(1, "MMIO expected RUN state after execution, got %0h", control);
      end

      check_against_reference();
      cov_program_runs = cov_program_runs + 1;
    end
  endtask

  task automatic write_mmio_coverage_reports;
    input coverage_pass;
    integer fd_json;
    integer fd_csv;
    begin
      fd_json = $fopen("sim_build/mmio_coverage.json", "w");
      if (fd_json == 0) begin
        $fatal(1, "Could not open sim_build/mmio_coverage.json for write");
      end

      $fwrite(fd_json, "{\n");
      $fwrite(fd_json, "  \"coverage_pass\": %0d,\n", coverage_pass);
      $fwrite(fd_json, "  \"shadow_writes\": %0d,\n", cov_shadow_writes);
      $fwrite(fd_json, "  \"shadow_reads\": %0d,\n", cov_shadow_reads);
      $fwrite(fd_json, "  \"status_reads\": %0d,\n", cov_status_reads);
      $fwrite(fd_json, "  \"acc_reads\": %0d,\n", cov_acc_reads);
      $fwrite(fd_json, "  \"pc_reads\": %0d,\n", cov_pc_reads);
      $fwrite(fd_json, "  \"dmem_reads\": %0d,\n", cov_dmem_reads);
      $fwrite(fd_json, "  \"control_reads\": %0d,\n", cov_control_reads);
      $fwrite(fd_json, "  \"control_start_writes\": %0d,\n", cov_control_start_writes);
      $fwrite(fd_json, "  \"control_stop_writes\": %0d,\n", cov_control_stop_writes);
      $fwrite(fd_json, "  \"program_runs\": %0d,\n", cov_program_runs);
      $fwrite(fd_json, "  \"external_program_runs\": %0d,\n", cov_external_program_runs);
      $fwrite(fd_json, "  \"state_seen\": {\n");
      $fwrite(fd_json, "    \"hold\": %0d,\n", cov_hold_state_seen);
      $fwrite(fd_json, "    \"load\": %0d,\n", cov_load_state_seen);
      $fwrite(fd_json, "    \"run\": %0d\n", cov_run_state_seen);
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"coverage_goals\": {\n");
      $fwrite(fd_json, "    \"program_runs_min\": 4,\n");
      $fwrite(fd_json, "    \"shadow_writes_per_run\": 16,\n");
      $fwrite(fd_json, "    \"shadow_reads_per_run\": 16,\n");
      $fwrite(fd_json, "    \"dmem_reads_per_run\": 16,\n");
      $fwrite(fd_json, "    \"status_reads_min_per_run\": 1,\n");
      $fwrite(fd_json, "    \"acc_reads_min_per_run\": 1,\n");
      $fwrite(fd_json, "    \"pc_reads_min_per_run\": 1,\n");
      $fwrite(fd_json, "    \"control_start_writes_per_run\": 1,\n");
      $fwrite(fd_json, "    \"control_stop_writes_per_run\": 1,\n");
      $fwrite(fd_json, "    \"state_hold_seen\": 1,\n");
      $fwrite(fd_json, "    \"state_load_seen\": 1,\n");
      $fwrite(fd_json, "    \"state_run_seen\": 1\n");
      $fwrite(fd_json, "  }\n");
      $fwrite(fd_json, "}\n");
      $fclose(fd_json);

      fd_csv = $fopen("sim_build/mmio_coverage.csv", "w");
      if (fd_csv == 0) begin
        $fatal(1, "Could not open sim_build/mmio_coverage.csv for write");
      end

      $fwrite(fd_csv, "metric,value\n");
      $fwrite(fd_csv, "coverage_pass,%0d\n", coverage_pass);
      $fwrite(fd_csv, "shadow_writes,%0d\n", cov_shadow_writes);
      $fwrite(fd_csv, "shadow_reads,%0d\n", cov_shadow_reads);
      $fwrite(fd_csv, "status_reads,%0d\n", cov_status_reads);
      $fwrite(fd_csv, "acc_reads,%0d\n", cov_acc_reads);
      $fwrite(fd_csv, "pc_reads,%0d\n", cov_pc_reads);
      $fwrite(fd_csv, "dmem_reads,%0d\n", cov_dmem_reads);
      $fwrite(fd_csv, "control_reads,%0d\n", cov_control_reads);
      $fwrite(fd_csv, "control_start_writes,%0d\n", cov_control_start_writes);
      $fwrite(fd_csv, "control_stop_writes,%0d\n", cov_control_stop_writes);
      $fwrite(fd_csv, "program_runs,%0d\n", cov_program_runs);
      $fwrite(fd_csv, "external_program_runs,%0d\n", cov_external_program_runs);
      $fwrite(fd_csv, "state_hold_seen,%0d\n", cov_hold_state_seen);
      $fwrite(fd_csv, "state_load_seen,%0d\n", cov_load_state_seen);
      $fwrite(fd_csv, "state_run_seen,%0d\n", cov_run_state_seen);
      $fclose(fd_csv);
    end
  endtask

  task automatic report_and_check_mmio_coverage;
    reg coverage_pass;
    begin
      coverage_pass = 1'b1;

      if (cov_program_runs < 4) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] program_runs >= 4");
      end
      if (cov_shadow_writes < (16 * cov_program_runs)) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] shadow_writes per run");
      end
      if (cov_shadow_reads < (16 * cov_program_runs)) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] shadow_reads per run");
      end
      if (cov_dmem_reads < (16 * cov_program_runs)) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] dmem_reads per run");
      end
      if (cov_status_reads < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] status_reads per run");
      end
      if (cov_acc_reads < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] acc_reads per run");
      end
      if (cov_pc_reads < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] pc_reads per run");
      end
      if (cov_control_start_writes < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] control_start_writes per run");
      end
      if (cov_control_stop_writes < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] control_stop_writes per run");
      end
      if (!cov_hold_state_seen || !cov_load_state_seen || !cov_run_state_seen) begin
        coverage_pass = 1'b0;
        $display("[MMIO-COVERAGE][MISS] hold/load/run states all seen");
      end

      write_mmio_coverage_reports(coverage_pass);
      $display(
          "[MMIO-COVERAGE] wrote sim_build/mmio_coverage.json and sim_build/mmio_coverage.csv");

      if (!coverage_pass) begin
        $fatal(1, "MMIO coverage goals not met.");
      end
    end
  endtask

  task automatic test_mmio_smoke;
    begin
      clear_program();
      program_mem[0] = ins(OPC_LDI, 4'd3);
      program_mem[1] = ins(OPC_STA, 4'd0);
      program_mem[2] = ins(OPC_LDI, 4'd4);
      program_mem[3] = ins(OPC_ADD, 4'd0);
      program_mem[4] = ins(OPC_STA, 4'd1);
      program_mem[5] = ins(OPC_LDI, 4'd0);
      program_mem[6] = ins(OPC_JZ, 4'd8);
      program_mem[7] = ins(OPC_LDI, 4'd15);
      program_mem[8] = ins(OPC_HLT, 4'd0);
      run_program_via_mmio(80);
      $display("[PASS] mmio_smoke_and_shadow_readback");
    end
  endtask

  task automatic test_mmio_reprogram_sequence;
    begin
      clear_program();
      program_mem[0] = ins(OPC_NOP, 4'd0);
      program_mem[1] = ins(OPC_LDI, 4'd1);
      program_mem[2] = ins(OPC_JZ, 4'd5);
      program_mem[3] = ins(OPC_LDI, 4'd9);
      program_mem[4] = ins(OPC_HLT, 4'd0);
      program_mem[5] = ins(OPC_LDI, 4'd0);
      run_program_via_mmio(64);

      clear_program();
      program_mem[0] = ins(OPC_LDI, 4'd1);
      program_mem[1] = ins(OPC_SHL, 4'd0);
      program_mem[2] = ins(OPC_SHL, 4'd0);
      program_mem[3] = ins(OPC_SHL, 4'd0);
      program_mem[4] = ins(OPC_SHL, 4'd0);
      program_mem[5] = ins(OPC_SHL, 4'd0);
      program_mem[6] = ins(OPC_SHL, 4'd0);
      program_mem[7] = ins(OPC_SHL, 4'd0);
      program_mem[8] = ins(OPC_SHL, 4'd0);
      program_mem[9] = ins(OPC_HLT, 4'd0);
      run_program_via_mmio(96);
      $display("[PASS] mmio_reprogram_and_shift_status");
    end
  endtask

  task automatic test_mmio_illegal_opcode;
    begin
      clear_program();
      program_mem[0] = 8'hF0;
      program_mem[1] = ins(OPC_LDI, 4'd9);
      run_program_via_mmio(16);
      if (ref_pc !== 4'd0) begin
        $fatal(1, "MMIO illegal-opcode reference expected PC 0");
      end
      $display("[PASS] mmio_illegal_opcode_halts");
    end
  endtask

  task automatic test_mmio_jump_sub_cmp_sequence;
    begin
      clear_program();
      program_mem[0] = ins(OPC_LDI, 4'd7);
      program_mem[1] = ins(OPC_STA, 4'd0);
      program_mem[2] = ins(OPC_LDI, 4'd2);
      program_mem[3] = ins(OPC_SUB, 4'd0);
      program_mem[4] = ins(OPC_CMP, 4'd0);
      program_mem[5] = ins(OPC_JMP, 4'd7);
      program_mem[6] = ins(OPC_LDI, 4'd0);
      program_mem[7] = ins(OPC_HLT, 4'd0);
      run_program_via_mmio(64);
      $display("[PASS] mmio_jump_sub_cmp_reference_compare");
    end
  endtask

  task automatic test_mmio_shadow_fault_injection;
    reg [7:0] observed;
    begin
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

      mmio_write(ADDR_CONTROL, 8'h00);
      load_program_shadow();
      check_program_shadow();
      run_reference_model(128);

      mmio_write(ADDR_CONTROL, 8'h01);
      wait_for_run_state(32);
      mmio_write(8'h00, ins(OPC_LDI, 4'd9));
      mmio_read_now(8'h00, observed);
      if (observed !== ins(OPC_LDI, 4'd9)) begin
        $fatal(1, "MMIO fault-injection shadow update did not stick");
      end

      wait_for_halt(160);
      check_against_reference();
      cov_program_runs = cov_program_runs + 1;
      if (ref_dmem[3] !== 8'h04) begin
        $fatal(1, "MMIO fault injection expected first run to preserve original shadow image");
      end

      mmio_write(ADDR_CONTROL, 8'h00);
      mmio_read_now(ADDR_CONTROL, observed);
      if (observed !== 8'h00) begin
        $fatal(1, "MMIO fault injection expected HOLD after explicit stop");
      end

      program_mem[0] = ins(OPC_LDI, 4'd9);
      load_program_shadow();
      check_program_shadow();
      run_reference_model(128);
      mmio_write(ADDR_CONTROL, 8'h01);
      wait_for_halt(160);
      check_against_reference();
      cov_program_runs = cov_program_runs + 1;
      if (ref_dmem[3] !== 8'h09) begin
        $fatal(1, "MMIO fault injection expected second run to observe the updated shadow image");
      end

      $display("[PASS] mmio_shadow_fault_injection_isolated_until_reload");
    end
  endtask

  task automatic test_external_program;
    input [8*260-1:0] hex_path;
    begin
      clear_program();
      $readmemh(hex_path, program_mem);
      run_program_via_mmio(256);
      cov_external_program_runs = cov_external_program_runs + 1;
      $display("[PASS] mmio_external_program_reference_compare (%0s)", hex_path);
    end
  endtask

  initial begin
`ifndef NO_WAVES
    $dumpfile("sim_build/simple_cpu_mmio_tb.vcd");
    $dumpvars(0, simple_cpu_mmio_tb);
`endif

    cov_init();
    global_reset();
    test_mmio_smoke();
    test_mmio_reprogram_sequence();
    test_mmio_illegal_opcode();
    test_mmio_jump_sub_cmp_sequence();
    test_mmio_shadow_fault_injection();

    if ($value$plusargs("PROGRAM_HEX=%s", external_program_hex)) begin
      $display("[INFO] Running MMIO external program from %0s", external_program_hex);
      test_external_program(external_program_hex);
    end

    report_and_check_mmio_coverage();
    $display("[PASS] all mmio tests");
    $finish;
  end
endmodule
