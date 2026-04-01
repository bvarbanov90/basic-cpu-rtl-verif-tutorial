`timescale 1ns / 1ps

module simple_cpu_tb;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg prog_we = 1'b0;
  reg [3:0] prog_addr = 4'h0;
  reg [7:0] prog_data = 8'h00;
  reg [3:0] dbg_mem_addr = 4'h0;

  wire [7:0] dbg_mem_data;
  wire [7:0] dbg_acc;
  wire [3:0] dbg_pc;
  wire dbg_zero;
  wire dbg_carry;
  wire dbg_neg;
  wire dbg_overflow;
  wire dbg_halted;

  reg [7:0] program_mem[0:15];
  reg [7:0] ref_dmem[0:15];
  reg [7:0] ref_acc;
  reg [3:0] ref_pc;
  reg ref_zero;
  reg ref_carry;
  reg ref_neg;
  reg ref_overflow;
  reg ref_halted;

  reg [14:0] cov_opcode_hit;
  reg cov_illegal_opcode_hit;
  integer cov_jz_taken;
  integer cov_jz_not_taken;
  integer cov_zero_00;
  integer cov_zero_01;
  integer cov_zero_10;
  integer cov_zero_11;
  integer cov_carry_0;
  integer cov_carry_1;
  integer cov_neg_0;
  integer cov_neg_1;
  integer cov_overflow_0;
  integer cov_overflow_1;
  integer cov_opcode_count[0:14];
  integer cov_opcode_zero_cross[0:14][0:1];
  integer cov_opcode_carry_cross[0:14][0:1];
  integer cov_opcode_neg_cross[0:14][0:1];
  integer cov_opcode_overflow_cross[0:14][0:1];
  integer cov_total_cycles;
  integer cov_program_runs;

  reg [8*260-1:0] external_program_hex;

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

  localparam integer MAX_VALID_OPCODE = 14;
  localparam integer RANDOM_SUITE_ITERATIONS = 20;
  localparam integer BRANCH_RANDOM_SUITE_ITERATIONS = 12;
  localparam integer COV_MIN_PROGRAM_RUNS = 10;

  simple_cpu dut (
      .clk(clk),
      .rst_n(rst_n),
      .prog_we(prog_we),
      .prog_addr(prog_addr),
      .prog_data(prog_data),
      .dbg_mem_addr(dbg_mem_addr),
      .dbg_mem_data(dbg_mem_data),
      .dbg_acc(dbg_acc),
      .dbg_pc(dbg_pc),
      .dbg_zero(dbg_zero),
      .dbg_carry(dbg_carry),
      .dbg_neg(dbg_neg),
      .dbg_overflow(dbg_overflow),
      .dbg_halted(dbg_halted)
  );

  always #5 clk = ~clk;

  function automatic [7:0] ins;
    input [3:0] opcode;
    input [3:0] operand;
    begin
      ins = {opcode, operand};
    end
  endfunction

  function automatic [31:0] lcg_next;
    input [31:0] state;
    begin
      lcg_next = (state * 32'd1664525) + 32'd1013904223;
    end
  endfunction

  function automatic integer cov_zero_cross_reachable;
    input [3:0] opcode;
    input integer zero_state;
    begin
      if ((zero_state != 0) && (zero_state != 1)) begin
        cov_zero_cross_reachable = 0;
      end else begin
        case (opcode)
          OPC_NOP, OPC_LDI, OPC_ADD, OPC_SUB, OPC_STA, OPC_LDA, OPC_JMP, OPC_JZ, OPC_HLT,
                    OPC_AND, OPC_OR, OPC_XOR, OPC_SHL, OPC_SHR, OPC_CMP:
          cov_zero_cross_reachable = 1;
          default: cov_zero_cross_reachable = 0;
        endcase
      end
    end
  endfunction

  function automatic integer cov_carry_cross_reachable;
    input [3:0] opcode;
    input integer carry_state;
    begin
      if ((carry_state != 0) && (carry_state != 1)) begin
        cov_carry_cross_reachable = 0;
      end else begin
        case (opcode)
          OPC_LDI, OPC_LDA, OPC_AND, OPC_OR, OPC_XOR:
          cov_carry_cross_reachable = (carry_state == 0);
          OPC_NOP, OPC_ADD, OPC_SUB, OPC_STA, OPC_JMP, OPC_JZ, OPC_HLT, OPC_SHL, OPC_SHR, OPC_CMP:
          cov_carry_cross_reachable = 1;
          default: cov_carry_cross_reachable = 0;
        endcase
      end
    end
  endfunction

  function automatic integer cov_neg_cross_reachable;
    input [3:0] opcode;
    input integer neg_state;
    begin
      if ((neg_state != 0) && (neg_state != 1)) begin
        cov_neg_cross_reachable = 0;
      end else begin
        case (opcode)
          OPC_LDI, OPC_SHR: cov_neg_cross_reachable = (neg_state == 0);
          OPC_NOP, OPC_ADD, OPC_SUB, OPC_STA, OPC_LDA, OPC_JMP, OPC_JZ, OPC_HLT,
                    OPC_AND, OPC_OR, OPC_XOR, OPC_SHL, OPC_CMP:
          cov_neg_cross_reachable = 1;
          default: cov_neg_cross_reachable = 0;
        endcase
      end
    end
  endfunction

  function automatic integer cov_overflow_cross_reachable;
    input [3:0] opcode;
    input integer overflow_state;
    begin
      if ((overflow_state != 0) && (overflow_state != 1)) begin
        cov_overflow_cross_reachable = 0;
      end else begin
        case (opcode)
          OPC_LDI, OPC_LDA, OPC_AND, OPC_OR, OPC_XOR, OPC_SHR:
          cov_overflow_cross_reachable = (overflow_state == 0);
          OPC_NOP, OPC_ADD, OPC_SUB, OPC_STA, OPC_JMP, OPC_JZ, OPC_HLT, OPC_SHL, OPC_CMP:
          cov_overflow_cross_reachable = 1;
          default: cov_overflow_cross_reachable = 0;
        endcase
      end
    end
  endfunction

  task automatic cov_init;
    integer opcode;
    integer z;
    begin
      cov_opcode_hit = 15'b0;
      cov_illegal_opcode_hit = 1'b0;
      cov_jz_taken = 0;
      cov_jz_not_taken = 0;
      cov_zero_00 = 0;
      cov_zero_01 = 0;
      cov_zero_10 = 0;
      cov_zero_11 = 0;
      cov_carry_0 = 0;
      cov_carry_1 = 0;
      cov_neg_0 = 0;
      cov_neg_1 = 0;
      cov_overflow_0 = 0;
      cov_overflow_1 = 0;
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        cov_opcode_count[opcode] = 0;
        for (z = 0; z <= 1; z = z + 1) begin
          cov_opcode_zero_cross[opcode][z] = 0;
          cov_opcode_carry_cross[opcode][z] = 0;
          cov_opcode_neg_cross[opcode][z] = 0;
          cov_opcode_overflow_cross[opcode][z] = 0;
        end
      end
      cov_total_cycles = 0;
      cov_program_runs = 0;
    end
  endtask

  task automatic cov_sample_step;
    input [3:0] opcode;
    input [3:0] operand;
    input [3:0] pc_before;
    input [3:0] pc_after;
    input zero_before;
    input zero_after;
    input carry_after;
    input neg_after;
    input overflow_after;
    begin
      if (opcode <= OPC_CMP) begin
        cov_opcode_hit[opcode] = 1'b1;
        cov_opcode_count[opcode] = cov_opcode_count[opcode] + 1;
        cov_opcode_zero_cross[opcode][zero_after] = cov_opcode_zero_cross[opcode][zero_after] + 1;
        cov_opcode_carry_cross[opcode][carry_after] = cov_opcode_carry_cross[opcode][carry_after] + 1;
        cov_opcode_neg_cross[opcode][neg_after] = cov_opcode_neg_cross[opcode][neg_after] + 1;
        cov_opcode_overflow_cross[opcode][overflow_after] = cov_opcode_overflow_cross[opcode][overflow_after] + 1;
      end else begin
        cov_illegal_opcode_hit = 1'b1;
      end

      case ({
        zero_before, zero_after
      })
        2'b00: cov_zero_00 = cov_zero_00 + 1;
        2'b01: cov_zero_01 = cov_zero_01 + 1;
        2'b10: cov_zero_10 = cov_zero_10 + 1;
        2'b11: cov_zero_11 = cov_zero_11 + 1;
        default: begin
        end
      endcase

      if (carry_after) cov_carry_1 = cov_carry_1 + 1;
      else cov_carry_0 = cov_carry_0 + 1;
      if (neg_after) cov_neg_1 = cov_neg_1 + 1;
      else cov_neg_0 = cov_neg_0 + 1;
      if (overflow_after) cov_overflow_1 = cov_overflow_1 + 1;
      else cov_overflow_0 = cov_overflow_0 + 1;

      if (opcode == OPC_JZ) begin
        if (pc_after == operand) begin
          cov_jz_taken = cov_jz_taken + 1;
        end else if (pc_after == (pc_before + 4'd1)) begin
          cov_jz_not_taken = cov_jz_not_taken + 1;
        end
      end
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

  task automatic reset_dut;
    begin
      rst_n = 1'b0;
      prog_we = 1'b0;
      prog_addr = 4'h0;
      prog_data = 8'h00;
      dbg_mem_addr = 4'h0;
      repeat (3) @(posedge clk);
      rst_n = 1'b1;
    end
  endtask

  task automatic load_program;
    input integer length;
    integer idx;
    begin
      for (idx = 0; idx < length; idx = idx + 1) begin
        prog_we   = 1'b1;
        prog_addr = idx[3:0];
        prog_data = program_mem[idx];
        @(posedge clk);
      end
      prog_we   = 1'b0;
      prog_addr = 4'h0;
      prog_data = 8'h00;
    end
  endtask

  task automatic run_until_halt;
    input integer max_cycles;
    integer cycle;
    reg [3:0] pc_before;
    reg [3:0] pc_after;
    reg [3:0] opcode;
    reg [3:0] operand;
    reg zero_before;
    reg [7:0] instr;
    begin
      cycle = 0;
      while (!dbg_halted && cycle < max_cycles) begin
        pc_before = dbg_pc;
        zero_before = dbg_zero;
        instr = program_mem[pc_before];
        opcode = instr[7:4];
        operand = instr[3:0];

        @(posedge clk);

        pc_after = dbg_pc;
        cov_sample_step(opcode, operand, pc_before, pc_after, zero_before, dbg_zero, dbg_carry,
                        dbg_neg, dbg_overflow);

        cycle = cycle + 1;
        cov_total_cycles = cov_total_cycles + 1;
      end
      if (!dbg_halted) begin
        $fatal(1, "Timeout: DUT did not halt in %0d cycles", max_cycles);
      end
      cov_program_runs = cov_program_runs + 1;
    end
  endtask

  task automatic build_random_program;
    input [31:0] seed;
    reg [31:0] rng;
    reg [3:0] opcode;
    reg [3:0] operand;
    integer idx;
    begin
      clear_program();
      rng = seed;
      for (idx = 0; idx < 11; idx = idx + 1) begin
        rng = lcg_next(rng);
        case (rng[3:0])
          4'd0: opcode = OPC_NOP;
          4'd1: opcode = OPC_LDI;
          4'd2: opcode = OPC_STA;
          4'd3: opcode = OPC_LDA;
          4'd4: opcode = OPC_ADD;
          4'd5: opcode = OPC_SUB;
          4'd6: opcode = OPC_AND;
          4'd7: opcode = OPC_OR;
          4'd8: opcode = OPC_XOR;
          4'd9: opcode = OPC_SHL;
          4'd10: opcode = OPC_SHR;
          default: opcode = OPC_CMP;
        endcase
        rng = lcg_next(rng);
        operand = rng[3:0];
        program_mem[idx] = ins(opcode, operand);
      end
      program_mem[11] = ins(OPC_HLT, 4'h0);
    end
  endtask

  task automatic build_branch_random_program;
    input [31:0] seed;
    reg [31:0] rng;
    reg [ 3:0] loop_count;
    reg [ 3:0] data_value;
    reg [ 3:0] aux_value;
    reg [ 3:0] loop_opcode;
    reg [ 3:0] loop_operand;
    begin
      clear_program();
      rng = seed;

      rng = lcg_next(rng);
      loop_count = 4'd2 + {2'b00, rng[1:0]};
      rng = lcg_next(rng);
      data_value = rng[3:0];
      rng = lcg_next(rng);
      aux_value = rng[3:0];
      rng = lcg_next(rng);

      case (rng[3:0])
        4'd0: loop_opcode = OPC_ADD;
        4'd1: loop_opcode = OPC_SUB;
        4'd2: loop_opcode = OPC_AND;
        4'd3: loop_opcode = OPC_OR;
        4'd4: loop_opcode = OPC_XOR;
        4'd5: loop_opcode = OPC_CMP;
        4'd6: loop_opcode = OPC_SHL;
        4'd7: loop_opcode = OPC_SHR;
        default: loop_opcode = OPC_NOP;
      endcase

      if (rng[4]) begin
        loop_operand = 4'd0;
      end else begin
        loop_operand = 4'd3;
      end

      program_mem[0]  = ins(OPC_LDI, loop_count);
      program_mem[1]  = ins(OPC_STA, 4'd0);
      program_mem[2]  = ins(OPC_LDI, 4'd1);
      program_mem[3]  = ins(OPC_STA, 4'd1);
      program_mem[4]  = ins(OPC_LDI, data_value);
      program_mem[5]  = ins(OPC_STA, 4'd2);
      program_mem[6]  = ins(OPC_LDI, aux_value);
      program_mem[7]  = ins(OPC_STA, 4'd3);
      program_mem[8]  = ins(OPC_LDA, 4'd0);
      program_mem[9]  = ins(OPC_SUB, 4'd1);
      program_mem[10] = ins(OPC_STA, 4'd0);
      program_mem[11] = ins(OPC_JZ, 4'd15);
      program_mem[12] = ins(OPC_LDA, 4'd2);
      program_mem[13] = ins(loop_opcode, loop_operand);
      program_mem[14] = ins(OPC_JMP, 4'd8);
      program_mem[15] = ins(OPC_HLT, 4'd0);
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
            if (model_zero) next_pc = operand;
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

        if (opcode == OPC_STA) model_dmem[operand] = model_acc;

        model_acc = next_acc;
        model_pc = next_pc;
        model_zero = next_zero;
        model_carry = next_carry;
        model_neg = next_neg;
        model_overflow = next_overflow;
        model_halted = next_halted;
        cycle = cycle + 1;
      end

      if (!model_halted) $fatal(1, "Timeout: reference model did not halt");

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
    input [31:0] seed;
    integer idx;
    begin
      if (dbg_halted !== ref_halted) $fatal(1, "Randomized(seed=%0h): HALTED mismatch", seed);
      if (dbg_acc !== ref_acc) $fatal(1, "Randomized(seed=%0h): ACC mismatch", seed);
      if (dbg_pc !== ref_pc) $fatal(1, "Randomized(seed=%0h): PC mismatch", seed);
      if (dbg_zero !== ref_zero) $fatal(1, "Randomized(seed=%0h): ZERO mismatch", seed);
      if (dbg_carry !== ref_carry) $fatal(1, "Randomized(seed=%0h): CARRY mismatch", seed);
      if (dbg_neg !== ref_neg) $fatal(1, "Randomized(seed=%0h): NEG mismatch", seed);
      if (dbg_overflow !== ref_overflow) $fatal(1, "Randomized(seed=%0h): OVERFLOW mismatch", seed);

      for (idx = 0; idx < 16; idx = idx + 1) begin
        dbg_mem_addr = idx[3:0];
        #1;
        if (dbg_mem_data !== ref_dmem[idx]) begin
          $fatal(1, "Randomized(seed=%0h): dmem[%0d] mismatch", seed, idx);
        end
      end
    end
  endtask

  task automatic test_directed;
    begin
      clear_program();
      program_mem[0]  = ins(OPC_LDI, 4'd3);
      program_mem[1]  = ins(OPC_STA, 4'd0);
      program_mem[2]  = ins(OPC_LDI, 4'd4);
      program_mem[3]  = ins(OPC_ADD, 4'd0);
      program_mem[4]  = ins(OPC_STA, 4'd1);
      program_mem[5]  = ins(OPC_SUB, 4'd0);
      program_mem[6]  = ins(OPC_STA, 4'd2);
      program_mem[7]  = ins(OPC_LDI, 4'd0);
      program_mem[8]  = ins(OPC_JZ, 4'd10);
      program_mem[9]  = ins(OPC_LDI, 4'd15);
      program_mem[10] = ins(OPC_STA, 4'd3);
      program_mem[11] = ins(OPC_HLT, 4'd0);

      reset_dut();
      load_program(12);
      run_until_halt(64);

      if (dbg_halted !== 1'b1) $fatal(1, "Directed: HALTED expected 1");
      if (dbg_acc !== 8'd0) $fatal(1, "Directed: ACC expected 0");

      dbg_mem_addr = 4'd0;
      #1;
      if (dbg_mem_data !== 8'd3) $fatal(1, "Directed: dmem[0] expected 3");
      dbg_mem_addr = 4'd1;
      #1;
      if (dbg_mem_data !== 8'd7) $fatal(1, "Directed: dmem[1] expected 7");
      dbg_mem_addr = 4'd2;
      #1;
      if (dbg_mem_data !== 8'd4) $fatal(1, "Directed: dmem[2] expected 4");
      dbg_mem_addr = 4'd3;
      #1;
      if (dbg_mem_data !== 8'd0) $fatal(1, "Directed: dmem[3] expected 0");

      $display("[PASS] directed_arithmetic_and_branch");
    end
  endtask

  task automatic test_branch_not_taken;
    begin
      clear_program();
      program_mem[0] = ins(OPC_NOP, 4'd0);
      program_mem[1] = ins(OPC_LDI, 4'd1);
      program_mem[2] = ins(OPC_JZ, 4'd5);
      program_mem[3] = ins(OPC_LDI, 4'd9);
      program_mem[4] = ins(OPC_HLT, 4'd0);
      program_mem[5] = ins(OPC_LDI, 4'd0);

      reset_dut();
      load_program(6);
      run_until_halt(32);

      if (dbg_acc !== 8'd9) $fatal(1, "BranchNotTaken: ACC expected 9");
      $display("[PASS] branch_not_taken");
    end
  endtask

  task automatic test_jump_loop;
    begin
      clear_program();
      program_mem[0] = ins(OPC_LDI, 4'd3);
      program_mem[1] = ins(OPC_STA, 4'd0);
      program_mem[2] = ins(OPC_LDI, 4'd1);
      program_mem[3] = ins(OPC_STA, 4'd1);
      program_mem[4] = ins(OPC_LDA, 4'd0);
      program_mem[5] = ins(OPC_SUB, 4'd1);
      program_mem[6] = ins(OPC_STA, 4'd0);
      program_mem[7] = ins(OPC_JZ, 4'd9);
      program_mem[8] = ins(OPC_JMP, 4'd4);
      program_mem[9] = ins(OPC_HLT, 4'd0);

      reset_dut();
      load_program(10);
      run_until_halt(128);

      if (dbg_acc !== 8'd0) $fatal(1, "JumpLoop: ACC expected 0");
      $display("[PASS] jump_loop_and_jmp");
    end
  endtask

  task automatic test_wraparound_zero;
    begin
      clear_program();
      program_mem[0] = ins(OPC_LDI, 4'd1);
      program_mem[1] = ins(OPC_STA, 4'd0);
      program_mem[2] = ins(OPC_LDI, 4'd0);
      program_mem[3] = ins(OPC_SUB, 4'd0);
      program_mem[4] = ins(OPC_ADD, 4'd0);
      program_mem[5] = ins(OPC_HLT, 4'd0);

      reset_dut();
      load_program(6);
      run_until_halt(64);

      if (dbg_acc !== 8'd0) $fatal(1, "Wraparound: ACC expected 0");
      if (dbg_carry !== 1'b1) $fatal(1, "Wraparound: CARRY expected 1");
      $display("[PASS] wraparound_and_zero_flag");
    end
  endtask

  task automatic test_logic_and_cmp;
    begin
      clear_program();
      program_mem[0]  = ins(OPC_LDI, 4'd3);
      program_mem[1]  = ins(OPC_STA, 4'd0);
      program_mem[2]  = ins(OPC_LDI, 4'd12);
      program_mem[3]  = ins(OPC_STA, 4'd1);
      program_mem[4]  = ins(OPC_LDA, 4'd0);
      program_mem[5]  = ins(OPC_AND, 4'd1);
      program_mem[6]  = ins(OPC_OR, 4'd0);
      program_mem[7]  = ins(OPC_XOR, 4'd1);
      program_mem[8]  = ins(OPC_SHL, 4'd0);
      program_mem[9]  = ins(OPC_SHR, 4'd0);
      program_mem[10] = ins(OPC_CMP, 4'd0);
      program_mem[11] = ins(OPC_SUB, 4'd1);
      program_mem[12] = ins(OPC_HLT, 4'd0);

      reset_dut();
      load_program(13);
      run_until_halt(96);

      if (dbg_acc !== 8'd3) $fatal(1, "LogicCmp: ACC expected 3");
      if (dbg_carry !== 1'b1) $fatal(1, "LogicCmp: CARRY expected 1");
      $display("[PASS] logic_ops_and_cmp_flags");
    end
  endtask
  task automatic test_shift_carry_and_overflow;
    begin
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

      reset_dut();
      load_program(10);
      run_until_halt(96);

      if (dbg_acc !== 8'd0) $fatal(1, "ShiftCarry: ACC expected 0");
      if (dbg_carry !== 1'b1) $fatal(1, "ShiftCarry: CARRY expected 1");
      if (dbg_overflow !== 1'b1) $fatal(1, "ShiftCarry: OVERFLOW expected 1");
      $display("[PASS] shift_carry_overflow");
    end
  endtask

  task automatic test_cmp_negative;
    begin
      clear_program();
      program_mem[0] = ins(OPC_LDI, 4'd2);
      program_mem[1] = ins(OPC_STA, 4'd0);
      program_mem[2] = ins(OPC_LDI, 4'd1);
      program_mem[3] = ins(OPC_CMP, 4'd0);
      program_mem[4] = ins(OPC_HLT, 4'd0);

      reset_dut();
      load_program(5);
      run_until_halt(64);

      if (dbg_acc !== 8'd1) $fatal(1, "CmpNeg: ACC expected 1");
      if (dbg_carry !== 1'b0) $fatal(1, "CmpNeg: CARRY expected 0");
      if (dbg_neg !== 1'b1) $fatal(1, "CmpNeg: NEG expected 1");
      $display("[PASS] cmp_negative_flags");
    end
  endtask

  task automatic test_illegal_opcode;
    begin
      clear_program();
      program_mem[0] = 8'hF0;
      program_mem[1] = ins(OPC_LDI, 4'd9);

      reset_dut();
      load_program(2);
      run_until_halt(16);

      if (dbg_halted !== 1'b1) $fatal(1, "IllegalOpcode: HALTED expected 1");
      if (dbg_pc !== 4'd0) $fatal(1, "IllegalOpcode: PC expected 0");
      $display("[PASS] illegal_opcode_halts");
    end
  endtask

  task automatic test_randomized_suite;
    integer iteration;
    reg [31:0] seed;
    begin
      for (iteration = 0; iteration < RANDOM_SUITE_ITERATIONS; iteration = iteration + 1) begin
        seed = lcg_next(32'h20260221 + iteration);
        build_random_program(seed);
        run_reference_model(64);
        reset_dut();
        load_program(12);
        run_until_halt(64);
        check_against_reference(seed);
      end
      $display("[PASS] randomized_reference_regression (%0d seeds)", RANDOM_SUITE_ITERATIONS);
    end
  endtask

  task automatic test_branch_randomized_suite;
    integer iteration;
    reg [31:0] seed;
    begin
      for (
          iteration = 0; iteration < BRANCH_RANDOM_SUITE_ITERATIONS; iteration = iteration + 1
      ) begin
        seed = lcg_next(32'hBADC0DE0 + iteration);
        build_branch_random_program(seed);
        run_reference_model(128);
        reset_dut();
        load_program(16);
        run_until_halt(128);
        check_against_reference(seed);
      end
      $display("[PASS] branch_stress_reference_regression (%0d seeds)",
               BRANCH_RANDOM_SUITE_ITERATIONS);
    end
  endtask

  task automatic test_external_program;
    input [8*260-1:0] hex_path;
    begin
      clear_program();
      $readmemh(hex_path, program_mem);
      run_reference_model(256);
      reset_dut();
      load_program(16);
      run_until_halt(256);
      check_against_reference(32'hF00DCAFE);
      $display("[PASS] external_program_reference_compare (%0s)", hex_path);
    end
  endtask

  task automatic write_coverage_reports;
    input coverage_pass;
    integer fd_json;
    integer fd_csv;
    integer opcode;
    integer z;
    begin
      fd_json = $fopen("sim_build/coverage.json", "w");
      if (fd_json == 0) $fatal(1, "Could not open sim_build/coverage.json for write");

      $fwrite(fd_json, "{\n");
      $fwrite(fd_json, "  \"coverage_pass\": %0d,\n", coverage_pass);
      $fwrite(fd_json, "  \"opcode_hit_bitmap\": \"%b\",\n", cov_opcode_hit);
      $fwrite(fd_json, "  \"opcode_hits\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": %0d", opcode, cov_opcode_hit[opcode]);
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_counts\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": %0d", opcode, cov_opcode_count[opcode]);
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_zero_cross\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"zero0\": %0d, \"zero1\": %0d}", opcode,
                cov_opcode_zero_cross[opcode][0], cov_opcode_zero_cross[opcode][1]);
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_zero_cross_reachability\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"zero0\": %0d, \"zero1\": %0d}", opcode,
                cov_zero_cross_reachable(opcode[3:0], 0), cov_zero_cross_reachable(opcode[3:0], 1));
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_carry_cross\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"carry0\": %0d, \"carry1\": %0d}", opcode,
                cov_opcode_carry_cross[opcode][0], cov_opcode_carry_cross[opcode][1]);
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_carry_cross_reachability\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"carry0\": %0d, \"carry1\": %0d}", opcode,
                cov_carry_cross_reachable(opcode[3:0], 0), cov_carry_cross_reachable(opcode[3:0], 1
                ));
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_neg_cross\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"neg0\": %0d, \"neg1\": %0d}", opcode,
                cov_opcode_neg_cross[opcode][0], cov_opcode_neg_cross[opcode][1]);
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_neg_cross_reachability\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"neg0\": %0d, \"neg1\": %0d}", opcode,
                cov_neg_cross_reachable(opcode[3:0], 0), cov_neg_cross_reachable(opcode[3:0], 1));
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_overflow_cross\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"overflow0\": %0d, \"overflow1\": %0d}", opcode,
                cov_opcode_overflow_cross[opcode][0], cov_opcode_overflow_cross[opcode][1]);
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"opcode_overflow_cross_reachability\": {\n");
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_json, "    \"%0d\": {\"overflow0\": %0d, \"overflow1\": %0d}", opcode,
                cov_overflow_cross_reachable(opcode[3:0], 0), cov_overflow_cross_reachable(
                opcode[3:0], 1));
        if (opcode < MAX_VALID_OPCODE) begin
          $fwrite(fd_json, ",\n");
        end else begin
          $fwrite(fd_json, "\n");
        end
      end
      $fwrite(fd_json, "  },\n");
      $fwrite(fd_json, "  \"illegal_opcode_hit\": %0d,\n", cov_illegal_opcode_hit);
      $fwrite(fd_json, "  \"jz_taken\": %0d,\n", cov_jz_taken);
      $fwrite(fd_json, "  \"jz_not_taken\": %0d,\n", cov_jz_not_taken);
      $fwrite(fd_json, "  \"zero_transition_00\": %0d,\n", cov_zero_00);
      $fwrite(fd_json, "  \"zero_transition_01\": %0d,\n", cov_zero_01);
      $fwrite(fd_json, "  \"zero_transition_10\": %0d,\n", cov_zero_10);
      $fwrite(fd_json, "  \"zero_transition_11\": %0d,\n", cov_zero_11);
      $fwrite(fd_json, "  \"carry_0\": %0d,\n", cov_carry_0);
      $fwrite(fd_json, "  \"carry_1\": %0d,\n", cov_carry_1);
      $fwrite(fd_json, "  \"neg_0\": %0d,\n", cov_neg_0);
      $fwrite(fd_json, "  \"neg_1\": %0d,\n", cov_neg_1);
      $fwrite(fd_json, "  \"overflow_0\": %0d,\n", cov_overflow_0);
      $fwrite(fd_json, "  \"overflow_1\": %0d,\n", cov_overflow_1);
      $fwrite(fd_json, "  \"program_runs\": %0d,\n", cov_program_runs);
      $fwrite(fd_json, "  \"total_cycles\": %0d,\n", cov_total_cycles);
      $fwrite(fd_json, "  \"random_suite_iterations\": %0d,\n", RANDOM_SUITE_ITERATIONS);
      $fwrite(fd_json, "  \"branch_random_suite_iterations\": %0d,\n",
              BRANCH_RANDOM_SUITE_ITERATIONS);
      $fwrite(fd_json, "  \"coverage_goals\": {\n");
      $fwrite(fd_json, "    \"opcode_coverage\": 1,\n");
      $fwrite(fd_json, "    \"illegal_opcode_hit\": 1,\n");
      $fwrite(fd_json, "    \"jz_taken\": 1,\n");
      $fwrite(fd_json, "    \"jz_not_taken\": 1,\n");
      $fwrite(fd_json, "    \"zero_transition_01\": 1,\n");
      $fwrite(fd_json, "    \"zero_transition_10\": 1,\n");
      $fwrite(fd_json, "    \"carry_0\": 1,\n");
      $fwrite(fd_json, "    \"carry_1\": 1,\n");
      $fwrite(fd_json, "    \"neg_0\": 1,\n");
      $fwrite(fd_json, "    \"neg_1\": 1,\n");
      $fwrite(fd_json, "    \"overflow_0\": 1,\n");
      $fwrite(fd_json, "    \"overflow_1\": 1,\n");
      $fwrite(fd_json, "    \"jz_x_zero0\": 1,\n");
      $fwrite(fd_json, "    \"jz_x_zero1\": 1,\n");
      $fwrite(fd_json, "    \"add_x_carry0\": 1,\n");
      $fwrite(fd_json, "    \"add_x_carry1\": 1,\n");
      $fwrite(fd_json, "    \"sub_x_carry0\": 1,\n");
      $fwrite(fd_json, "    \"sub_x_carry1\": 1,\n");
      $fwrite(fd_json, "    \"sub_x_neg1\": 1,\n");
      $fwrite(fd_json, "    \"cmp_x_neg1\": 1,\n");
      $fwrite(fd_json, "    \"shl_x_overflow0\": 1,\n");
      $fwrite(fd_json, "    \"shl_x_overflow1\": 1,\n");
      $fwrite(fd_json, "    \"reachability_annotations\": 1,\n");
      $fwrite(fd_json, "    \"min_program_runs\": %0d\n", COV_MIN_PROGRAM_RUNS);
      $fwrite(fd_json, "  }\n");
      $fwrite(fd_json, "}\n");
      $fclose(fd_json);

      fd_csv = $fopen("sim_build/coverage.csv", "w");
      if (fd_csv == 0) $fatal(1, "Could not open sim_build/coverage.csv for write");

      $fwrite(fd_csv, "metric,value\n");
      $fwrite(fd_csv, "coverage_pass,%0d\n", coverage_pass);
      $fwrite(fd_csv, "opcode_hit_bitmap,%b\n", cov_opcode_hit);
      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        $fwrite(fd_csv, "opcode_%0d_hit,%0d\n", opcode, cov_opcode_hit[opcode]);
        $fwrite(fd_csv, "opcode_%0d_count,%0d\n", opcode, cov_opcode_count[opcode]);
        for (z = 0; z <= 1; z = z + 1) begin
          $fwrite(fd_csv, "opcode_%0d_x_zero%0d,%0d\n", opcode, z,
                  cov_opcode_zero_cross[opcode][z]);
          $fwrite(fd_csv, "opcode_%0d_x_zero%0d_reachable,%0d\n", opcode, z,
                  cov_zero_cross_reachable(opcode[3:0], z));
          $fwrite(fd_csv, "opcode_%0d_x_carry%0d,%0d\n", opcode, z,
                  cov_opcode_carry_cross[opcode][z]);
          $fwrite(fd_csv, "opcode_%0d_x_carry%0d_reachable,%0d\n", opcode, z,
                  cov_carry_cross_reachable(opcode[3:0], z));
          $fwrite(fd_csv, "opcode_%0d_x_neg%0d,%0d\n", opcode, z, cov_opcode_neg_cross[opcode][z]);
          $fwrite(fd_csv, "opcode_%0d_x_neg%0d_reachable,%0d\n", opcode, z,
                  cov_neg_cross_reachable(opcode[3:0], z));
          $fwrite(fd_csv, "opcode_%0d_x_overflow%0d,%0d\n", opcode, z,
                  cov_opcode_overflow_cross[opcode][z]);
          $fwrite(fd_csv, "opcode_%0d_x_overflow%0d_reachable,%0d\n", opcode, z,
                  cov_overflow_cross_reachable(opcode[3:0], z));
        end
      end
      $fwrite(fd_csv, "illegal_opcode_hit,%0d\n", cov_illegal_opcode_hit);
      $fwrite(fd_csv, "jz_taken,%0d\n", cov_jz_taken);
      $fwrite(fd_csv, "jz_not_taken,%0d\n", cov_jz_not_taken);
      $fwrite(fd_csv, "zero_transition_00,%0d\n", cov_zero_00);
      $fwrite(fd_csv, "zero_transition_01,%0d\n", cov_zero_01);
      $fwrite(fd_csv, "zero_transition_10,%0d\n", cov_zero_10);
      $fwrite(fd_csv, "zero_transition_11,%0d\n", cov_zero_11);
      $fwrite(fd_csv, "carry_0,%0d\n", cov_carry_0);
      $fwrite(fd_csv, "carry_1,%0d\n", cov_carry_1);
      $fwrite(fd_csv, "neg_0,%0d\n", cov_neg_0);
      $fwrite(fd_csv, "neg_1,%0d\n", cov_neg_1);
      $fwrite(fd_csv, "overflow_0,%0d\n", cov_overflow_0);
      $fwrite(fd_csv, "overflow_1,%0d\n", cov_overflow_1);
      $fwrite(fd_csv, "program_runs,%0d\n", cov_program_runs);
      $fwrite(fd_csv, "total_cycles,%0d\n", cov_total_cycles);
      $fwrite(fd_csv, "random_suite_iterations,%0d\n", RANDOM_SUITE_ITERATIONS);
      $fwrite(fd_csv, "branch_random_suite_iterations,%0d\n", BRANCH_RANDOM_SUITE_ITERATIONS);
      $fclose(fd_csv);
    end
  endtask

  task automatic report_and_check_coverage;
    integer opcode;
    integer z;
    reg coverage_pass;
    begin
      coverage_pass = 1'b1;

      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        if (!cov_opcode_hit[opcode]) begin
          coverage_pass = 1'b0;
          $display("[COVERAGE][MISS] opcode 0x%0h", opcode);
        end
      end

      for (z = 0; z <= 1; z = z + 1) begin
        if (cov_opcode_zero_cross[OPC_JZ][z] == 0) begin
          coverage_pass = 1'b0;
          $display("[COVERAGE][MISS] JZ x ZERO=%0d", z);
        end
      end

      for (z = 0; z <= 1; z = z + 1) begin
        if (cov_opcode_carry_cross[OPC_ADD][z] == 0) begin
          coverage_pass = 1'b0;
          $display("[COVERAGE][MISS] ADD x CARRY=%0d", z);
        end
        if (cov_opcode_carry_cross[OPC_SUB][z] == 0) begin
          coverage_pass = 1'b0;
          $display("[COVERAGE][MISS] SUB x CARRY=%0d", z);
        end
        if (cov_opcode_overflow_cross[OPC_SHL][z] == 0) begin
          coverage_pass = 1'b0;
          $display("[COVERAGE][MISS] SHL x OVERFLOW=%0d", z);
        end
      end

      if (cov_opcode_neg_cross[OPC_SUB][1] == 0) begin
        coverage_pass = 1'b0;
        $display("[COVERAGE][MISS] SUB x NEG=1");
      end
      if (cov_opcode_neg_cross[OPC_CMP][1] == 0) begin
        coverage_pass = 1'b0;
        $display("[COVERAGE][MISS] CMP x NEG=1");
      end

      for (opcode = 0; opcode <= MAX_VALID_OPCODE; opcode = opcode + 1) begin
        for (z = 0; z <= 1; z = z + 1) begin
          if (!cov_zero_cross_reachable(
                  opcode[3:0], z
              ) && (cov_opcode_zero_cross[opcode][z] != 0)) begin
            coverage_pass = 1'b0;
            $display(
                "[COVERAGE][MODEL] Impossible ZERO bin observed: opcode 0x%0h x ZERO=%0d count=%0d",
                opcode, z, cov_opcode_zero_cross[opcode][z]);
          end
          if (!cov_carry_cross_reachable(
                  opcode[3:0], z
              ) && (cov_opcode_carry_cross[opcode][z] != 0)) begin
            coverage_pass = 1'b0;
            $display(
                "[COVERAGE][MODEL] Impossible CARRY bin observed: opcode 0x%0h x CARRY=%0d count=%0d",
                opcode, z, cov_opcode_carry_cross[opcode][z]);
          end
          if (!cov_neg_cross_reachable(
                  opcode[3:0], z
              ) && (cov_opcode_neg_cross[opcode][z] != 0)) begin
            coverage_pass = 1'b0;
            $display(
                "[COVERAGE][MODEL] Impossible NEG bin observed: opcode 0x%0h x NEG=%0d count=%0d",
                opcode, z, cov_opcode_neg_cross[opcode][z]);
          end
          if (!cov_overflow_cross_reachable(
                  opcode[3:0], z
              ) && (cov_opcode_overflow_cross[opcode][z] != 0)) begin
            coverage_pass = 1'b0;
            $display(
                "[COVERAGE][MODEL] Impossible OVERFLOW bin observed: opcode 0x%0h x OVERFLOW=%0d count=%0d",
                opcode, z, cov_opcode_overflow_cross[opcode][z]);
          end
        end
      end

      if (!cov_illegal_opcode_hit) coverage_pass = 1'b0;
      if (cov_jz_taken == 0 || cov_jz_not_taken == 0) coverage_pass = 1'b0;
      if (cov_zero_01 == 0 || cov_zero_10 == 0) coverage_pass = 1'b0;
      if (cov_carry_0 == 0 || cov_carry_1 == 0) coverage_pass = 1'b0;
      if (cov_neg_0 == 0 || cov_neg_1 == 0) coverage_pass = 1'b0;
      if (cov_overflow_0 == 0 || cov_overflow_1 == 0) coverage_pass = 1'b0;
      if (cov_program_runs < COV_MIN_PROGRAM_RUNS) coverage_pass = 1'b0;

      write_coverage_reports(coverage_pass);
      $display("[COVERAGE] wrote sim_build/coverage.json and sim_build/coverage.csv");

      if (!coverage_pass) $fatal(1, "Coverage goals not met.");
    end
  endtask

  initial begin
`ifndef NO_WAVES
    $dumpfile("sim_build/simple_cpu_tb.vcd");
    $dumpvars(0, simple_cpu_tb);
`endif

    cov_init();
    test_directed();
    test_branch_not_taken();
    test_jump_loop();
    test_wraparound_zero();
    test_logic_and_cmp();
    test_shift_carry_and_overflow();
    test_cmp_negative();
    test_illegal_opcode();
    test_randomized_suite();
    test_branch_randomized_suite();

    if ($value$plusargs("PROGRAM_HEX=%s", external_program_hex)) begin
      $display("[INFO] Running external program from %0s", external_program_hex);
      test_external_program(external_program_hex);
    end

    report_and_check_coverage();

    $display("[PASS] all tests");
    $finish;
  end
endmodule
