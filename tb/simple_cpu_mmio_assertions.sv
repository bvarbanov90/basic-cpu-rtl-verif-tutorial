`timescale 1ns / 1ps

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
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_CONTROL = 8'h30;
  logic seen_reset_clock;

  initial begin
    seen_reset_clock = 1'b0;
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      seen_reset_clock <= 1'b1;
      if (seen_reset_clock && (state !== STATE_HOLD)) begin
        $fatal(1, "MMIO assertion failed: reset must force HOLD state");
      end
    end else begin
      if (bus_valid && (bus_ready !== 1'b1)) begin
        $fatal(1, "MMIO assertion failed: bus_ready must stay asserted");
      end

      case (state)
        STATE_HOLD: begin
          if (core_rst_n !== 1'b0) begin
            $fatal(1, "MMIO assertion failed: HOLD must keep the core in reset");
          end
          if (prog_we !== 1'b0) begin
            $fatal(1, "MMIO assertion failed: HOLD must not program instruction memory");
          end
        end
        STATE_LOAD: begin
          if (core_rst_n !== 1'b1) begin
            $fatal(1, "MMIO assertion failed: LOAD must release core reset");
          end
          if (prog_we !== 1'b1) begin
            $fatal(1, "MMIO assertion failed: LOAD must assert prog_we");
          end
          if (prog_addr !== load_index) begin
            $fatal(1, "MMIO assertion failed: prog_addr must track load_index");
          end
        end
        STATE_RUN: begin
          if (core_rst_n !== 1'b1) begin
            $fatal(1, "MMIO assertion failed: RUN must release core reset");
          end
          if (prog_we !== 1'b0) begin
            $fatal(1, "MMIO assertion failed: RUN must not assert prog_we");
          end
        end
        default: begin
          $fatal(1, "MMIO assertion failed: illegal wrapper state %0d", state);
        end
      endcase

      if (bus_valid && !bus_write && (bus_addr == ADDR_CONTROL)) begin
        case (state)
          STATE_HOLD: begin
            if (bus_rdata !== 8'h00) begin
              $fatal(1, "MMIO assertion failed: HOLD control readback must be 0");
            end
          end
          STATE_LOAD: begin
            if (bus_rdata !== 8'h02) begin
              $fatal(1, "MMIO assertion failed: LOAD control readback must be 2");
            end
          end
          STATE_RUN: begin
            if (bus_rdata !== 8'h01) begin
              $fatal(1, "MMIO assertion failed: RUN control readback must be 1");
            end
          end
          default: begin
          end
        endcase
      end
    end
  end
endmodule
