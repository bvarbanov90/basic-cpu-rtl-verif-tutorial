`timescale 1ns / 1ps
`include "tb/simple_cpu_wrapper_common_assertions.svh"

module simple_cpu_mmio_wait_assertions (
    input logic       clk,
    input logic       rst_n,
    input logic       bus_valid,
    input logic       bus_write,
    input logic [7:0] bus_addr,
    input logic [7:0] bus_wdata,
    input logic       bus_ready,
    input logic [7:0] bus_rdata,
    input logic       pending,
    input logic [1:0] wait_count,
    input logic       req_write,
    input logic [7:0] req_addr,
    input logic [7:0] req_wdata,
    input logic       inner_bus_valid,
    input logic       inner_bus_ready,
    input logic [1:0] state,
    input logic [3:0] load_index,
    input logic       core_rst_n,
    input logic       prog_we,
    input logic [3:0] prog_addr
);
  localparam logic [1:0] WAIT_CYCLES = 2'd1;

  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  logic seen_reset_clock;
  logic prev_pending;
  logic prev_req_write;
  logic [7:0] prev_req_addr;
  logic [7:0] prev_req_wdata;

  simple_cpu_wrapper_common_assertions common_assertions (
      .clk(clk),
      .rst_n(rst_n),
      .state(state),
      .load_index(load_index),
      .core_rst_n(core_rst_n),
      .prog_we(prog_we),
      .prog_addr(prog_addr),
      .control_read_valid(pending && (wait_count == 2'd0) && !req_write && (req_addr == ADDR_CONTROL)),
      .control_read_data(bus_rdata)
  );

  initial begin
    seen_reset_clock = 1'b0;
    prev_pending = 1'b0;
    prev_req_write = 1'b0;
    prev_req_addr = 8'h00;
    prev_req_wdata = 8'h00;
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      seen_reset_clock <= 1'b1;
      prev_pending <= 1'b0;
      prev_req_write <= 1'b0;
      prev_req_addr <= 8'h00;
      prev_req_wdata <= 8'h00;

      if (seen_reset_clock && (pending !== 1'b0)) begin
        $fatal(1, "MMIO-wait assertion failed: reset must clear pending");
      end
      if (seen_reset_clock && (inner_bus_valid !== 1'b0)) begin
        $fatal(1, "MMIO-wait assertion failed: reset must deassert inner_bus_valid");
      end
      if (seen_reset_clock && (bus_ready !== 1'b0)) begin
        $fatal(1, "MMIO-wait assertion failed: reset must keep bus_ready low");
      end
      if (seen_reset_clock && (wait_count !== WAIT_CYCLES)) begin
        $fatal(1, "MMIO-wait assertion failed: reset wait_count must reload WAIT_CYCLES");
      end
    end else begin
      if (!pending) begin
        if (inner_bus_valid !== 1'b0) begin
          $fatal(1, "MMIO-wait assertion failed: idle wrapper must deassert inner_bus_valid");
        end
        if (bus_ready !== 1'b0) begin
          $fatal(1, "MMIO-wait assertion failed: idle wrapper must keep bus_ready low");
        end
      end

      if (pending && (wait_count != 2'd0)) begin
        if (inner_bus_valid !== 1'b0) begin
          $fatal(1,
                 "MMIO-wait assertion failed: pending wait cycle must not drive inner_bus_valid");
        end
        if (bus_ready !== 1'b0) begin
          $fatal(1, "MMIO-wait assertion failed: pending wait cycle must keep bus_ready low");
        end
      end

      if (pending && (wait_count == 2'd0)) begin
        if (inner_bus_valid !== 1'b1) begin
          $fatal(1, "MMIO-wait assertion failed: service cycle must assert inner_bus_valid");
        end
        if (bus_ready !== inner_bus_ready) begin
          $fatal(
              1,
              "MMIO-wait assertion failed: bus_ready must mirror inner_bus_ready when servicing");
        end
      end

      if (prev_pending && pending) begin
        if (req_write !== prev_req_write) begin
          $fatal(1, "MMIO-wait assertion failed: req_write changed while pending");
        end
        if (req_addr !== prev_req_addr) begin
          $fatal(1, "MMIO-wait assertion failed: req_addr changed while pending");
        end
        if (req_wdata !== prev_req_wdata) begin
          $fatal(1, "MMIO-wait assertion failed: req_wdata changed while pending");
        end
      end

      if (!prev_pending && pending) begin
        if (wait_count !== WAIT_CYCLES) begin
          $fatal(1, "MMIO-wait assertion failed: captured request must reload wait_count");
        end
        if (req_write !== bus_write) begin
          $fatal(1, "MMIO-wait assertion failed: captured req_write mismatch");
        end
        if (req_addr !== bus_addr) begin
          $fatal(1, "MMIO-wait assertion failed: captured req_addr mismatch");
        end
        if (req_wdata !== bus_wdata) begin
          $fatal(1, "MMIO-wait assertion failed: captured req_wdata mismatch");
        end
      end

      prev_pending   <= pending;
      prev_req_write <= req_write;
      prev_req_addr  <= req_addr;
      prev_req_wdata <= req_wdata;
    end
  end
endmodule
