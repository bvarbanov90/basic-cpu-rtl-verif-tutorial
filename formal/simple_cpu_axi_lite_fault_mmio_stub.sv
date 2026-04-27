module simple_cpu_mmio (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         bus_valid,
    input  logic         bus_write,
    input  logic [  7:0] bus_addr,
    input  logic [  7:0] bus_wdata,
    output logic         bus_ready,
    output logic [  7:0] bus_rdata,
    output logic [  1:0] formal_state,
    output logic [  3:0] formal_load_index,
    output logic         formal_core_rst_n,
    output logic         formal_prog_we,
    output logic [  3:0] formal_prog_addr,
    output logic [  7:0] formal_prog_data,
    output logic [127:0] formal_shadow_flat,
    output logic [  7:0] formal_dbg_mem_data,
    output logic [  7:0] formal_dbg_acc,
    output logic [  3:0] formal_dbg_pc,
    output logic         formal_dbg_zero,
    output logic         formal_dbg_carry,
    output logic         formal_dbg_neg,
    output logic         formal_dbg_overflow,
    output logic         formal_dbg_halted
);
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_STATUS = 8'h10;
  localparam logic [7:0] ADDR_ACC = 8'h11;
  localparam logic [7:0] ADDR_PC = 8'h12;
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  (* anyconst *) logic [7:0] any_dbg_mem_seed;
  (* anyconst *) logic [7:0] any_dbg_acc;
  (* anyconst *) logic [3:0] any_dbg_pc;
  (* anyconst *) logic any_dbg_zero;
  (* anyconst *) logic any_dbg_carry;
  (* anyconst *) logic any_dbg_neg;
  (* anyconst *) logic any_dbg_overflow;
  (* anyconst *) logic any_dbg_halted;

  logic [7:0] shadow_imem[0:15];
  logic [1:0] state;
  logic [3:0] load_index;
  integer idx;
  genvar formal_idx;

  assign bus_ready = 1'b1;
  assign formal_state = state;
  assign formal_load_index = load_index;
  assign formal_core_rst_n = rst_n && (state != STATE_HOLD);
  assign formal_prog_we = (state == STATE_LOAD);
  assign formal_prog_addr = load_index;
  assign formal_prog_data = shadow_imem[load_index];
  assign formal_dbg_mem_data = any_dbg_mem_seed ^ {4'h0, bus_addr[3:0]};
  assign formal_dbg_acc = any_dbg_acc;
  assign formal_dbg_pc = any_dbg_pc;
  assign formal_dbg_zero = any_dbg_zero;
  assign formal_dbg_carry = any_dbg_carry;
  assign formal_dbg_neg = any_dbg_neg;
  assign formal_dbg_overflow = any_dbg_overflow;
  assign formal_dbg_halted = any_dbg_halted;

  generate
    for (formal_idx = 0; formal_idx < 16; formal_idx = formal_idx + 1) begin : gen_formal_shadow
      assign formal_shadow_flat[(formal_idx * 8) +: 8] = shadow_imem[formal_idx];
    end
  endgenerate

  always_comb begin
    bus_rdata = 8'h00;

    if (bus_addr[7:4] == 4'h0) begin
      bus_rdata = shadow_imem[bus_addr[3:0]];
    end else if (bus_addr[7:4] == 4'h2) begin
      bus_rdata = formal_dbg_mem_data;
    end else begin
      case (bus_addr)
        ADDR_STATUS:
        bus_rdata = {
          3'b000,
          formal_dbg_halted,
          formal_dbg_overflow,
          formal_dbg_neg,
          formal_dbg_carry,
          formal_dbg_zero
        };
        ADDR_ACC: bus_rdata = formal_dbg_acc;
        ADDR_PC: bus_rdata = {4'h0, formal_dbg_pc};
        ADDR_CONTROL: bus_rdata = {6'b000000, (state == STATE_LOAD), (state == STATE_RUN)};
        default: bus_rdata = 8'h00;
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= STATE_HOLD;
      load_index <= 4'h0;
      for (idx = 0; idx < 16; idx = idx + 1) begin
        shadow_imem[idx] <= 8'h00;
      end
    end else begin
      case (state)
        STATE_HOLD: begin
          load_index <= 4'h0;
          if (bus_valid && bus_write) begin
            if (bus_addr[7:4] == 4'h0) begin
              shadow_imem[bus_addr[3:0]] <= bus_wdata;
            end else if ((bus_addr == ADDR_CONTROL) && bus_wdata[0]) begin
              state <= STATE_LOAD;
            end
          end
        end
        STATE_LOAD: begin
          load_index <= load_index + 4'd1;
          if (load_index == 4'd15) begin
            state <= STATE_RUN;
          end
        end
        default: begin
          if (bus_valid && bus_write) begin
            if (bus_addr[7:4] == 4'h0) begin
              shadow_imem[bus_addr[3:0]] <= bus_wdata;
            end else if ((bus_addr == ADDR_CONTROL) && !bus_wdata[0]) begin
              state <= STATE_HOLD;
              load_index <= 4'h0;
            end
          end
        end
      endcase
    end
  end
endmodule
