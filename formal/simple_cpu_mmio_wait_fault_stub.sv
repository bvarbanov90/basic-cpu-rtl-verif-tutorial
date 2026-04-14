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
  always_comb begin
    bus_ready = 1'b1;
    bus_rdata = {4'hA, bus_addr[3:0]};
    formal_state = 2'd0;
    formal_load_index = 4'h0;
    formal_core_rst_n = rst_n;
    formal_prog_we = 1'b0;
    formal_prog_addr = 4'h0;
    formal_prog_data = 8'h00;
    formal_shadow_flat = 128'h0;
    formal_dbg_mem_data = 8'h00;
    formal_dbg_acc = 8'h00;
    formal_dbg_pc = 4'h0;
    formal_dbg_zero = 1'b0;
    formal_dbg_carry = 1'b0;
    formal_dbg_neg = 1'b0;
    formal_dbg_overflow = 1'b0;
    formal_dbg_halted = 1'b0;
  end
endmodule
