`timescale 1ns / 1ps
`include "tb/simple_cpu_wrapper_common_assertions.svh"

module simple_cpu_wishbone_assertions (
    input logic       wb_clk_i,
    input logic       wb_rst_i,
    input logic       wb_cyc_i,
    input logic       wb_stb_i,
    input logic       wb_we_i,
    input logic [7:0] wb_adr_i,
    input logic       wb_ack_o,
    input logic [7:0] wb_dat_o,
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
      .clk(wb_clk_i),
      .rst_n(!wb_rst_i),
      .state(state),
      .load_index(load_index),
      .core_rst_n(core_rst_n),
      .prog_we(prog_we),
      .prog_addr(prog_addr),
      .control_read_valid(wb_cyc_i && wb_stb_i && !wb_we_i && (wb_adr_i == ADDR_CONTROL)),
      .control_read_data(wb_dat_o)
  );

  always @(posedge wb_clk_i) begin
    if (wb_rst_i) begin
      if (wb_ack_o !== 1'b0) begin
        $fatal(1, "Wishbone assertion failed: reset must keep wb_ack_o low");
      end
    end else begin
      if (mmio_valid !== (wb_cyc_i && wb_stb_i)) begin
        $fatal(1, "Wishbone assertion failed: mmio_valid must follow wb_cyc_i && wb_stb_i");
      end
      if (wb_ack_o !== (mmio_valid && mmio_ready)) begin
        $fatal(1, "Wishbone assertion failed: wb_ack_o must follow inner MMIO ready");
      end
      if (wb_dat_o !== mmio_rdata) begin
        $fatal(1, "Wishbone assertion failed: wb_dat_o must mirror inner MMIO read data");
      end
      if (wb_cyc_i && !wb_stb_i && (wb_ack_o !== 1'b0)) begin
        $fatal(1, "Wishbone assertion failed: setup phase must keep wb_ack_o low");
      end
      if (!wb_cyc_i && (wb_ack_o !== 1'b0)) begin
        $fatal(1, "Wishbone assertion failed: idle bus must keep wb_ack_o low");
      end
    end
  end
endmodule

