`timescale 1ns / 1ps

module simple_cpu_wishbone_tb;
  reg wb_clk_i = 1'b0;
  reg wb_rst_i = 1'b1;
  reg wb_cyc_i = 1'b0;
  reg wb_stb_i = 1'b0;
  reg wb_we_i = 1'b0;
  reg [7:0] wb_adr_i = 8'h00;
  reg [7:0] wb_dat_i = 8'h00;

  wire wb_ack_o;
  wire [7:0] wb_dat_o;

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
  integer cov_setup_phases;
  integer cov_access_phases;
  integer cov_read_accesses;
  integer cov_write_accesses;
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

  simple_cpu_wishbone dut (
      .wb_clk_i(wb_clk_i),
      .wb_rst_i(wb_rst_i),
      .wb_cyc_i(wb_cyc_i),
      .wb_stb_i(wb_stb_i),
      .wb_we_i(wb_we_i),
      .wb_adr_i(wb_adr_i),
      .wb_dat_i(wb_dat_i),
      .wb_ack_o(wb_ack_o),
      .wb_dat_o(wb_dat_o)
  );

  simple_cpu_wishbone_assertions wishbone_assertions (
      .wb_clk_i(wb_clk_i),
      .wb_rst_i(wb_rst_i),
      .wb_cyc_i(wb_cyc_i),
      .wb_stb_i(wb_stb_i),
      .wb_we_i(wb_we_i),
      .wb_adr_i(wb_adr_i),
      .wb_ack_o(wb_ack_o),
      .wb_dat_o(wb_dat_o),
      .mmio_valid(dut.mmio_valid),
      .mmio_ready(dut.mmio_ready),
      .mmio_rdata(dut.mmio_rdata),
      .state(dut.inner.state),
      .load_index(dut.inner.load_index),
      .core_rst_n(dut.inner.core_rst_n),
      .prog_we(dut.inner.prog_we),
      .prog_addr(dut.inner.prog_addr)
  );

  always #5 wb_clk_i = ~wb_clk_i;

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
      cov_setup_phases = 0;
      cov_access_phases = 0;
      cov_read_accesses = 0;
      cov_write_accesses = 0;
      cov_hold_state_seen = 1'b0;
      cov_load_state_seen = 1'b0;
      cov_run_state_seen = 1'b0;
    end
  endtask

  task automatic Wishbone_idle;
    begin
      wb_cyc_i = 1'b0;
      wb_stb_i = 1'b0;
      wb_we_i = 1'b0;
      wb_adr_i = 8'h00;
      wb_dat_i = 8'h00;
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
      wb_rst_i = 1'b1;
      Wishbone_idle();
      repeat (3) @(posedge wb_clk_i);
      wb_rst_i = 1'b0;
    end
  endtask

  task automatic Wishbone_write;
    input [7:0] addr;
    input [7:0] data;
    begin
      @(negedge wb_clk_i);
      wb_cyc_i = 1'b1;
      wb_stb_i = 1'b0;
      wb_we_i = 1'b1;
      wb_adr_i = addr;
      wb_dat_i = data;
      #1;
      cov_setup_phases = cov_setup_phases + 1;
      if (wb_ack_o !== 1'b0) begin
        $fatal(1, "Wishbone write setup observed wb_ack_o asserted");
      end

      @(negedge wb_clk_i);
      wb_stb_i = 1'b1;
      #1;
      cov_access_phases  = cov_access_phases + 1;
      cov_write_accesses = cov_write_accesses + 1;
      if (wb_ack_o !== 1'b1) begin
        $fatal(1, "Wishbone write access observed wb_ack_o deasserted");
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

      @(posedge wb_clk_i);
      #1;
      if (wb_ack_o !== 1'b1) begin
        $fatal(1, "Wishbone write access did not hold wb_ack_o through the active cycle");
      end

      @(negedge wb_clk_i);
      Wishbone_idle();
    end
  endtask

  task automatic Wishbone_read_now;
    input [7:0] addr;
    output [7:0] data;
    begin
      @(negedge wb_clk_i);
      wb_cyc_i = 1'b1;
      wb_stb_i = 1'b0;
      wb_we_i = 1'b0;
      wb_adr_i = addr;
      wb_dat_i = 8'h00;
      #1;
      cov_setup_phases = cov_setup_phases + 1;
      if (wb_ack_o !== 1'b0) begin
        $fatal(1, "Wishbone read setup observed wb_ack_o asserted");
      end

      @(negedge wb_clk_i);
      wb_stb_i = 1'b1;
      #1;
      cov_access_phases = cov_access_phases + 1;
      cov_read_accesses = cov_read_accesses + 1;
      if (wb_ack_o !== 1'b1) begin
        $fatal(1, "Wishbone read access observed wb_ack_o deasserted");
      end
      data = wb_dat_o;
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

      @(posedge wb_clk_i);
      #1;
      if (wb_ack_o !== 1'b1) begin
        $fatal(1, "Wishbone read access did not hold wb_ack_o through the active cycle");
      end

      @(negedge wb_clk_i);
      Wishbone_idle();
    end
  endtask

  task automatic load_program_shadow;
    integer idx;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        Wishbone_write(idx[7:0], program_mem[idx]);
      end
    end
  endtask

  task automatic check_program_shadow;
    integer idx;
    reg [7:0] observed;
    begin
      for (idx = 0; idx < 16; idx = idx + 1) begin
        Wishbone_read_now(idx[7:0], observed);
        if (observed !== program_mem[idx]) begin
          $fatal(1, "Wishbone shadow mismatch at imem[%0d]: got %0h expected %0h", idx, observed,
                 program_mem[idx]);
        end
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
          Wishbone_read_now(ADDR_STATUS, status);
          if (status[4]) begin
            disable poll_loop;
          end
        end
      end
      if (!status[4]) begin
        $fatal(1, "Wishbone timeout: wrapper/core did not halt within %0d polls", max_polls);
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
          Wishbone_read_now(ADDR_CONTROL, control);
          if (control == 8'h01) begin
            disable poll_loop;
          end
        end
      end
      if (control != 8'h01) begin
        $fatal(1, "Wishbone timeout: wrapper did not reach RUN within %0d polls", max_polls);
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
        $fatal(1, "Wishbone reference model timeout");
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
      Wishbone_read_now(ADDR_STATUS, status);
      Wishbone_read_now(ADDR_ACC, observed);
      if (observed !== ref_acc) begin
        $fatal(1, "Wishbone ACC mismatch: got %0h expected %0h", observed, ref_acc);
      end

      Wishbone_read_now(ADDR_PC, observed);
      if (observed[3:0] !== ref_pc) begin
        $fatal(1, "Wishbone PC mismatch: got %0h expected %0h", observed[3:0], ref_pc);
      end

      if (status[0] !== ref_zero) begin
        $fatal(1, "Wishbone ZERO mismatch");
      end
      if (status[1] !== ref_carry) begin
        $fatal(1, "Wishbone CARRY mismatch");
      end
      if (status[2] !== ref_neg) begin
        $fatal(1, "Wishbone NEG mismatch");
      end
      if (status[3] !== ref_overflow) begin
        $fatal(1, "Wishbone OVERFLOW mismatch");
      end
      if (status[4] !== ref_halted) begin
        $fatal(1, "Wishbone HALTED mismatch");
      end

      for (idx = 0; idx < 16; idx = idx + 1) begin
        Wishbone_read_now(8'h20 + idx[7:0], observed);
        if (observed !== ref_dmem[idx]) begin
          $fatal(1, "Wishbone dmem[%0d] mismatch: got %0h expected %0h", idx, observed, ref_dmem[idx]);
        end
      end
    end
  endtask

  task automatic run_program_via_Wishbone;
    input integer max_cycles;
    reg [7:0] control;
    begin
      Wishbone_write(ADDR_CONTROL, 8'h00);
      Wishbone_read_now(ADDR_CONTROL, control);
      if (control !== 8'h00) begin
        $fatal(1, "Wishbone control expected HOLD state before programming, got %0h", control);
      end

      load_program_shadow();
      check_program_shadow();
      run_reference_model(max_cycles);

      Wishbone_write(ADDR_CONTROL, 8'h01);
      Wishbone_read_now(ADDR_CONTROL, control);
      if (control[1] !== 1'b1) begin
        $fatal(1, "Wishbone expected loader-active state immediately after start, got %0h", control);
      end

      wait_for_halt(max_cycles + 64);
      Wishbone_read_now(ADDR_CONTROL, control);
      if (control[0] !== 1'b1) begin
        $fatal(1, "Wishbone expected RUN state after execution, got %0h", control);
      end

      check_against_reference();
      cov_program_runs = cov_program_runs + 1;
    end
  endtask

  task automatic write_wishbone_coverage_reports;
    input coverage_pass;
    integer fd_json;
    integer fd_csv;
    begin
      fd_json = $fopen("sim_build/wishbone_coverage.json", "w");
      if (fd_json == 0) begin
        $fatal(1, "Could not open sim_build/wishbone_coverage.json for write");
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
      $fwrite(fd_json, "  \"setup_phases\": %0d,\n", cov_setup_phases);
      $fwrite(fd_json, "  \"access_phases\": %0d,\n", cov_access_phases);
      $fwrite(fd_json, "  \"read_accesses\": %0d,\n", cov_read_accesses);
      $fwrite(fd_json, "  \"write_accesses\": %0d,\n", cov_write_accesses);
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
      $fwrite(fd_json, "    \"setup_equals_access\": 1,\n");
      $fwrite(fd_json, "    \"access_equals_transactions\": 1,\n");
      $fwrite(fd_json, "    \"state_hold_seen\": 1,\n");
      $fwrite(fd_json, "    \"state_load_seen\": 1,\n");
      $fwrite(fd_json, "    \"state_run_seen\": 1\n");
      $fwrite(fd_json, "  }\n");
      $fwrite(fd_json, "}\n");
      $fclose(fd_json);

      fd_csv = $fopen("sim_build/wishbone_coverage.csv", "w");
      if (fd_csv == 0) begin
        $fatal(1, "Could not open sim_build/wishbone_coverage.csv for write");
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
      $fwrite(fd_csv, "setup_phases,%0d\n", cov_setup_phases);
      $fwrite(fd_csv, "access_phases,%0d\n", cov_access_phases);
      $fwrite(fd_csv, "read_accesses,%0d\n", cov_read_accesses);
      $fwrite(fd_csv, "write_accesses,%0d\n", cov_write_accesses);
      $fwrite(fd_csv, "state_hold_seen,%0d\n", cov_hold_state_seen);
      $fwrite(fd_csv, "state_load_seen,%0d\n", cov_load_state_seen);
      $fwrite(fd_csv, "state_run_seen,%0d\n", cov_run_state_seen);
      $fclose(fd_csv);
    end
  endtask

  task automatic report_and_check_wishbone_coverage;
    reg coverage_pass;
    begin
      coverage_pass = 1'b1;

      if (cov_program_runs < 4) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] program_runs >= 4");
      end
      if (cov_shadow_writes < (16 * cov_program_runs)) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] shadow_writes per run");
      end
      if (cov_shadow_reads < (16 * cov_program_runs)) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] shadow_reads per run");
      end
      if (cov_dmem_reads < (16 * cov_program_runs)) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] dmem_reads per run");
      end
      if (cov_status_reads < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] status_reads per run");
      end
      if (cov_acc_reads < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] acc_reads per run");
      end
      if (cov_pc_reads < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] pc_reads per run");
      end
      if (cov_control_start_writes < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] control_start_writes per run");
      end
      if (cov_control_stop_writes < cov_program_runs) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] control_stop_writes per run");
      end
      if (cov_setup_phases != cov_access_phases) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] setup_phases must equal access_phases");
      end
      if (cov_access_phases != (cov_read_accesses + cov_write_accesses)) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] access_phases must equal total transactions");
      end
      if (!cov_hold_state_seen || !cov_load_state_seen || !cov_run_state_seen) begin
        coverage_pass = 1'b0;
        $display("[Wishbone-COVERAGE][MISS] hold/load/run states all seen");
      end

      write_wishbone_coverage_reports(coverage_pass);
      $display("[WISHBONE-COVERAGE] wrote sim_build/wishbone_coverage.json and sim_build/wishbone_coverage.csv");

      if (!coverage_pass) begin
        $fatal(1, "Wishbone coverage goals not met.");
      end
    end
  endtask

  task automatic test_Wishbone_smoke;
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
      run_program_via_Wishbone(80);
      $display("[PASS] Wishbone_smoke_and_shadow_readback");
    end
  endtask

  task automatic test_Wishbone_reprogram_sequence;
    begin
      clear_program();
      program_mem[0] = ins(OPC_NOP, 4'd0);
      program_mem[1] = ins(OPC_LDI, 4'd1);
      program_mem[2] = ins(OPC_JZ, 4'd5);
      program_mem[3] = ins(OPC_LDI, 4'd9);
      program_mem[4] = ins(OPC_HLT, 4'd0);
      program_mem[5] = ins(OPC_LDI, 4'd0);
      run_program_via_Wishbone(64);

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
      run_program_via_Wishbone(96);
      $display("[PASS] Wishbone_reprogram_and_shift_status");
    end
  endtask

  task automatic test_Wishbone_illegal_opcode;
    begin
      clear_program();
      program_mem[0] = 8'hF0;
      program_mem[1] = ins(OPC_LDI, 4'd9);
      run_program_via_Wishbone(16);
      if (ref_pc !== 4'd0) begin
        $fatal(1, "Wishbone illegal-opcode reference expected PC 0");
      end
      $display("[PASS] Wishbone_illegal_opcode_halts");
    end
  endtask

  task automatic test_Wishbone_jump_sub_cmp_sequence;
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
      run_program_via_Wishbone(64);
      $display("[PASS] Wishbone_jump_sub_cmp_reference_compare");
    end
  endtask

  task automatic test_Wishbone_shadow_fault_injection;
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

      Wishbone_write(ADDR_CONTROL, 8'h00);
      load_program_shadow();
      check_program_shadow();
      run_reference_model(128);

      Wishbone_write(ADDR_CONTROL, 8'h01);
      wait_for_run_state(32);
      Wishbone_write(8'h00, ins(OPC_LDI, 4'd9));
      Wishbone_read_now(8'h00, observed);
      if (observed !== ins(OPC_LDI, 4'd9)) begin
        $fatal(1, "Wishbone fault-injection shadow update did not stick");
      end

      wait_for_halt(160);
      check_against_reference();
      cov_program_runs = cov_program_runs + 1;
      if (ref_dmem[3] !== 8'h04) begin
        $fatal(1, "Wishbone fault injection expected first run to preserve original shadow image");
      end

      Wishbone_write(ADDR_CONTROL, 8'h00);
      Wishbone_read_now(ADDR_CONTROL, observed);
      if (observed !== 8'h00) begin
        $fatal(1, "Wishbone fault injection expected HOLD after explicit stop");
      end

      program_mem[0] = ins(OPC_LDI, 4'd9);
      load_program_shadow();
      check_program_shadow();
      run_reference_model(128);
      Wishbone_write(ADDR_CONTROL, 8'h01);
      wait_for_halt(160);
      check_against_reference();
      cov_program_runs = cov_program_runs + 1;
      if (ref_dmem[3] !== 8'h09) begin
        $fatal(1, "Wishbone fault injection expected second run to observe the updated shadow image");
      end

      $display("[PASS] Wishbone_shadow_fault_injection_isolated_until_reload");
    end
  endtask

  task automatic test_external_program;
    input [8*260-1:0] hex_path;
    begin
      clear_program();
      $readmemh(hex_path, program_mem);
      run_program_via_Wishbone(256);
      cov_external_program_runs = cov_external_program_runs + 1;
      $display("[PASS] Wishbone_external_program_reference_compare (%0s)", hex_path);
    end
  endtask

  initial begin
`ifndef NO_WAVES
    $dumpfile("sim_build/simple_cpu_wishbone_tb.vcd");
    $dumpvars(0, simple_cpu_wishbone_tb);
`endif

    cov_init();
    global_reset();
    test_Wishbone_smoke();
    test_Wishbone_reprogram_sequence();
    test_Wishbone_illegal_opcode();
    test_Wishbone_jump_sub_cmp_sequence();
    test_Wishbone_shadow_fault_injection();

    if ($value$plusargs("PROGRAM_HEX=%s", external_program_hex)) begin
      $display("[INFO] Running Wishbone external program from %0s", external_program_hex);
      test_external_program(external_program_hex);
    end

    report_and_check_wishbone_coverage();
    $display("[PASS] all Wishbone tests");
    $finish;
  end
endmodule

