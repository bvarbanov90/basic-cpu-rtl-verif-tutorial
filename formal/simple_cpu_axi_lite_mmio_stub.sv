module simple_cpu_mmio (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       bus_valid,
    input  logic       bus_write,
    input  logic [7:0] bus_addr,
    input  logic [7:0] bus_wdata,
    output logic       bus_ready,
    output logic [7:0] bus_rdata,
    output logic [1:0] formal_state,
    output logic [3:0] formal_load_index,
    output logic       formal_core_rst_n,
    output logic       formal_prog_we,
    output logic [3:0] formal_prog_addr,
    output logic [7:0] formal_prog_data,
    output logic [127:0] formal_shadow_flat,
    output logic [7:0] formal_dbg_mem_data,
    output logic [7:0] formal_dbg_acc,
    output logic [3:0] formal_dbg_pc,
    output logic       formal_dbg_zero,
    output logic       formal_dbg_carry,
    output logic       formal_dbg_neg,
    output logic       formal_dbg_overflow,
    output logic       formal_dbg_halted
);
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_STATUS = 8'h10;
  localparam logic [7:0] ADDR_ACC = 8'h11;
  localparam logic [7:0] ADDR_PC = 8'h12;
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  (* anyconst *) logic [1:0] any_state_seed;
  (* anyconst *) logic [3:0] any_load_index;
  (* anyconst *) logic [127:0] any_shadow_flat;
  (* anyconst *) logic [7:0] any_dbg_mem_data;
  (* anyconst *) logic [7:0] any_dbg_acc;
  (* anyconst *) logic [3:0] any_dbg_pc;
  (* anyconst *) logic any_dbg_zero;
  (* anyconst *) logic any_dbg_carry;
  (* anyconst *) logic any_dbg_neg;
  (* anyconst *) logic any_dbg_overflow;
  (* anyconst *) logic any_dbg_halted;

  always_comb begin
    formal_state = (any_state_seed == 2'd3) ? STATE_HOLD : any_state_seed;
    formal_load_index = any_load_index;
    formal_shadow_flat = any_shadow_flat;
    formal_dbg_mem_data = any_dbg_mem_data ^ {4'h0, bus_addr[3:0]};
    formal_dbg_acc = any_dbg_acc;
    formal_dbg_pc = any_dbg_pc;
    formal_dbg_zero = any_dbg_zero;
    formal_dbg_carry = any_dbg_carry;
    formal_dbg_neg = any_dbg_neg;
    formal_dbg_overflow = any_dbg_overflow;
    formal_dbg_halted = any_dbg_halted;

    formal_core_rst_n = rst_n && (formal_state != STATE_HOLD);
    formal_prog_we = (formal_state == STATE_LOAD);
    formal_prog_addr = formal_load_index;
    formal_prog_data = formal_shadow_flat[{formal_load_index, 3'b000} +: 8];

    bus_ready = 1'b1;
    if (bus_addr[7:4] == 4'h0) begin
      bus_rdata = formal_shadow_flat[{bus_addr[3:0], 3'b000} +: 8];
    end else if (bus_addr[7:4] == 4'h2) begin
      bus_rdata = formal_dbg_mem_data;
    end else begin
      case (bus_addr)
        ADDR_STATUS: begin
          bus_rdata = {3'b000, formal_dbg_halted, formal_dbg_overflow, formal_dbg_neg, formal_dbg_carry, formal_dbg_zero};
        end
        ADDR_ACC: begin
          bus_rdata = formal_dbg_acc;
        end
        ADDR_PC: begin
          bus_rdata = {4'h0, formal_dbg_pc};
        end
        ADDR_CONTROL: begin
          bus_rdata = {6'b000000, (formal_state == STATE_LOAD), (formal_state == STATE_RUN)};
        end
        default: begin
          bus_rdata = 8'h00;
        end
      endcase
    end
  end
endmodule

