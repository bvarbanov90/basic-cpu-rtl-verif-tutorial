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
);
    logic       mmio_valid;
    logic       mmio_ready;
    logic [7:0] mmio_rdata;

    assign mmio_valid = psel && penable;
    assign pready = mmio_valid && mmio_ready;
    assign prdata = mmio_rdata;

    simple_cpu_mmio inner (
        .clk(pclk),
        .rst_n(presetn),
        .bus_valid(mmio_valid),
        .bus_write(pwrite),
        .bus_addr(paddr),
        .bus_wdata(pwdata),
        .bus_ready(mmio_ready),
        .bus_rdata(mmio_rdata)
    );
endmodule
