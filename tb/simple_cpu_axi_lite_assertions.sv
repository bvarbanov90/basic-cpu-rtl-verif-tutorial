`timescale 1ns / 1ps
`include "tb/simple_cpu_wrapper_common_assertions.svh"

module simple_cpu_axi_lite_assertions (
    input logic       aclk,
    input logic       aresetn,
    input logic       axi_awvalid,
    input logic       axi_awready,
    input logic [7:0] axi_awaddr,
    input logic       axi_wvalid,
    input logic       axi_wready,
    input logic       axi_bvalid,
    input logic       axi_bready,
    input logic [1:0] axi_bresp,
    input logic       axi_arvalid,
    input logic       axi_arready,
    input logic [7:0] axi_araddr,
    input logic       axi_rvalid,
    input logic       axi_rready,
    input logic [7:0] axi_rdata,
    input logic [1:0] axi_rresp,
    input logic       mmio_valid,
    input logic       mmio_ready,
    input logic [7:0] mmio_rdata,
    input logic       mmio_write,
    input logic [7:0] mmio_addr,
    input logic [7:0] read_addr_q,
    input logic [1:0] state,
    input logic [3:0] load_index,
    input logic       core_rst_n,
    input logic       prog_we,
    input logic [3:0] prog_addr
);
  localparam logic [7:0] ADDR_CONTROL = 8'h30;

  simple_cpu_wrapper_common_assertions common_assertions (
      .clk(aclk),
      .rst_n(aresetn),
      .state(state),
      .load_index(load_index),
      .core_rst_n(core_rst_n),
      .prog_we(prog_we),
      .prog_addr(prog_addr),
      .control_read_valid(axi_rvalid && axi_rready && (read_addr_q == ADDR_CONTROL)),
      .control_read_data(axi_rdata)
  );

  always @(posedge aclk) begin
    if (!aresetn) begin
      if (axi_bvalid !== 1'b0) begin
        $fatal(1, "AXI-Lite assertion failed: reset must clear BVALID");
      end
      if (axi_rvalid !== 1'b0) begin
        $fatal(1, "AXI-Lite assertion failed: reset must clear RVALID");
      end
    end else begin
      if ((axi_awvalid ^ axi_wvalid) && (axi_awready || axi_wready)) begin
        $fatal(1, "AXI-Lite assertion failed: AW and W channels must be accepted together");
      end
      if (axi_awready !== axi_wready) begin
        $fatal(1, "AXI-Lite assertion failed: AWREADY and WREADY must stay coupled");
      end
      if (axi_bvalid && !axi_bready && (axi_awready || axi_wready)) begin
        $fatal(1, "AXI-Lite assertion failed: pending B response must block new writes");
      end
      if (axi_rvalid && !axi_rready && axi_arready) begin
        $fatal(1, "AXI-Lite assertion failed: pending R response must block new reads");
      end
      if (axi_bresp !== 2'b00) begin
        $fatal(1, "AXI-Lite assertion failed: this subset only emits OKAY write responses");
      end
      if (axi_rresp !== 2'b00) begin
        $fatal(1, "AXI-Lite assertion failed: this subset only emits OKAY read responses");
      end
      if (mmio_valid && (mmio_write !== (axi_awvalid && axi_wvalid && axi_awready && axi_wready))) begin
        $fatal(1, "AXI-Lite assertion failed: MMIO write intent disagrees with write handshake");
      end
      if (mmio_valid && mmio_write && (mmio_addr !== axi_awaddr)) begin
        $fatal(1, "AXI-Lite assertion failed: write address must drive the inner MMIO address");
      end
      if (mmio_valid && !mmio_write && (mmio_addr !== axi_araddr)) begin
        $fatal(1, "AXI-Lite assertion failed: read address must drive the inner MMIO address");
      end
      if (axi_rvalid && (axi_rdata !== mmio_rdata) && (read_addr_q == axi_araddr) && axi_arready) begin
        $fatal(1, "AXI-Lite assertion failed: read data should match the accepted MMIO readback");
      end
      if (mmio_valid && !mmio_ready) begin
        $fatal(1, "AXI-Lite assertion failed: current MMIO shell is expected to be always ready");
      end
    end
  end
endmodule
