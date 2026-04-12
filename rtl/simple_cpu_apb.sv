module simple_cpu_apb (
    input  logic       pclk,
    input  logic       presetn,
    input  logic       psel,
    input  logic       penable,
    input  logic       pwrite,
    input  logic [7:0] paddr,
    input  logic [7:0] pwdata,
    output logic       pready,
    output logic [7:0] prdata
`ifdef FORMAL
    ,
    output logic         formal_mmio_valid,
    output logic         formal_mmio_ready,
    output logic [7:0]   formal_mmio_rdata,
    output logic [1:0]   formal_state,
    output logic [3:0]   formal_load_index,
    output logic         formal_core_rst_n,
    output logic         formal_prog_we,
    output logic [3:0]   formal_prog_addr,
    output logic [7:0]   formal_prog_data,
    output logic [127:0] formal_shadow_flat,
    output logic [7:0]   formal_dbg_mem_data,
    output logic [7:0]   formal_dbg_acc,
    output logic [3:0]   formal_dbg_pc,
    output logic         formal_dbg_zero,
    output logic         formal_dbg_carry,
    output logic         formal_dbg_neg,
    output logic         formal_dbg_overflow,
    output logic         formal_dbg_halted
`endif
);
    logic       mmio_valid;
    logic       mmio_ready;
    logic [7:0] mmio_rdata;

    assign mmio_valid = psel && penable;
    assign pready = mmio_valid && mmio_ready;
    assign prdata = mmio_rdata;
`ifdef FORMAL
    assign formal_mmio_valid = mmio_valid;
    assign formal_mmio_ready = mmio_ready;
    assign formal_mmio_rdata = mmio_rdata;
`endif

    simple_cpu_mmio inner (
        .clk(pclk),
        .rst_n(presetn),
        .bus_valid(mmio_valid),
        .bus_write(pwrite),
        .bus_addr(paddr),
        .bus_wdata(pwdata),
        .bus_ready(mmio_ready),
        .bus_rdata(mmio_rdata)
`ifdef FORMAL
        ,
        .formal_state(formal_state),
        .formal_load_index(formal_load_index),
        .formal_core_rst_n(formal_core_rst_n),
        .formal_prog_we(formal_prog_we),
        .formal_prog_addr(formal_prog_addr),
        .formal_prog_data(formal_prog_data),
        .formal_shadow_flat(formal_shadow_flat),
        .formal_dbg_mem_data(formal_dbg_mem_data),
        .formal_dbg_acc(formal_dbg_acc),
        .formal_dbg_pc(formal_dbg_pc),
        .formal_dbg_zero(formal_dbg_zero),
        .formal_dbg_carry(formal_dbg_carry),
        .formal_dbg_neg(formal_dbg_neg),
        .formal_dbg_overflow(formal_dbg_overflow),
        .formal_dbg_halted(formal_dbg_halted)
`endif
    );
endmodule
