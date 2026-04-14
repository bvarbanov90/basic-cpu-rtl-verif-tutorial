`timescale 1ns / 1ps
`include "tb/simple_cpu_wrapper_common_assertions.svh"

module simple_cpu_mmio_assertions (
    input logic       clk,
    input logic       rst_n,
    input logic       bus_valid,
    input logic       bus_write,
    input logic [7:0] bus_addr,
    input logic       bus_ready,
    input logic [7:0] bus_rdata,
    input logic [1:0] state,
    input logic [3:0] load_index,
    input logic       core_rst_n,
    input logic       prog_we,
    input logic [3:0] prog_addr
);
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  simple_cpu_wrapper_common_assertions common_assertions (
      .clk(clk),
      .rst_n(rst_n),
      .state(state),
      .load_index(load_index),
      .core_rst_n(core_rst_n),
      .prog_we(prog_we),
      .prog_addr(prog_addr),
      .control_read_valid(bus_valid && !bus_write && (bus_addr == ADDR_CONTROL)),
      .control_read_data(bus_rdata)
  );

  always @(posedge clk) begin
    if (rst_n) begin
      if (bus_valid && (bus_ready !== 1'b1)) begin
        $fatal(1, "MMIO assertion failed: bus_ready must stay asserted");
      end
    end
  end
endmodule
