`timescale 1ns / 1ps
`include "tb/simple_cpu_wrapper_common_assertions.svh"

module simple_cpu_apb_assertions (
    input logic       pclk,
    input logic       presetn,
    input logic       psel,
    input logic       penable,
    input logic       pwrite,
    input logic [7:0] paddr,
    input logic       pready,
    input logic [7:0] prdata,
    input logic       mmio_valid,
    input logic       mmio_ready,
    input logic [7:0] mmio_rdata,
    input logic [1:0] state,
    input logic [3:0] load_index,
    input logic       core_rst_n,
    input logic       prog_we,
    input logic [3:0] prog_addr
);
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  simple_cpu_wrapper_common_assertions common_assertions (
      .clk(pclk),
      .rst_n(presetn),
      .state(state),
      .load_index(load_index),
      .core_rst_n(core_rst_n),
      .prog_we(prog_we),
      .prog_addr(prog_addr),
      .control_read_valid(psel && penable && !pwrite && (paddr == ADDR_CONTROL)),
      .control_read_data(prdata)
  );

  always @(posedge pclk) begin
    if (!presetn) begin
      if (pready !== 1'b0) begin
        $fatal(1, "APB assertion failed: reset must keep PREADY low");
      end
    end else begin
      if (mmio_valid !== (psel && penable)) begin
        $fatal(1, "APB assertion failed: mmio_valid must follow PSEL && PENABLE");
      end
      if (pready !== (mmio_valid && mmio_ready)) begin
        $fatal(1, "APB assertion failed: PREADY must follow inner MMIO ready");
      end
      if (prdata !== mmio_rdata) begin
        $fatal(1, "APB assertion failed: PRDATA must mirror inner MMIO read data");
      end
      if (psel && !penable && (pready !== 1'b0)) begin
        $fatal(1, "APB assertion failed: setup phase must keep PREADY low");
      end
      if (!psel && (pready !== 1'b0)) begin
        $fatal(1, "APB assertion failed: idle bus must keep PREADY low");
      end
    end
  end
endmodule
