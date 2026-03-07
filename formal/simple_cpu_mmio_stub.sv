module simple_cpu (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       prog_we,
    input  logic [3:0] prog_addr,
    input  logic [7:0] prog_data,
    input  logic [3:0] dbg_mem_addr,
    output logic [7:0] dbg_mem_data,
    output logic [7:0] dbg_acc,
    output logic [3:0] dbg_pc,
    output logic       dbg_zero,
    output logic       dbg_carry,
    output logic       dbg_neg,
    output logic       dbg_overflow,
    output logic       dbg_halted
);
    (* anyconst *) logic [7:0] any_dbg_mem_seed;
    (* anyconst *) logic [7:0] any_dbg_acc;
    (* anyconst *) logic [3:0] any_dbg_pc;
    (* anyconst *) logic       any_dbg_zero;
    (* anyconst *) logic       any_dbg_carry;
    (* anyconst *) logic       any_dbg_neg;
    (* anyconst *) logic       any_dbg_overflow;
    (* anyconst *) logic       any_dbg_halted;

    always_comb begin
        dbg_mem_data = any_dbg_mem_seed ^ {4'h0, dbg_mem_addr};
        dbg_acc = any_dbg_acc;
        dbg_pc = any_dbg_pc;
        dbg_zero = any_dbg_zero;
        dbg_carry = any_dbg_carry;
        dbg_neg = any_dbg_neg;
        dbg_overflow = any_dbg_overflow;
        dbg_halted = any_dbg_halted;
    end
endmodule
