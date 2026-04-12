`timescale 1ns / 1ps

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
  localparam logic [1:0] STATE_HOLD = 2'd0;
  localparam logic [1:0] STATE_LOAD = 2'd1;
  localparam logic [1:0] STATE_RUN = 2'd2;

  localparam logic [7:0] ADDR_CONTROL = 8'h30;
  logic seen_reset_clock;

  initial begin
    seen_reset_clock = 1'b0;
  end

  always @(posedge pclk) begin
    if (!presetn) begin
      seen_reset_clock <= 1'b1;
      if (seen_reset_clock && (state !== STATE_HOLD)) begin
        $fatal(1, "APB assertion failed: reset must force HOLD state");
      end
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

      case (state)
        STATE_HOLD: begin
          if (core_rst_n !== 1'b0) begin
            $fatal(1, "APB assertion failed: HOLD must keep the core in reset");
          end
          if (prog_we !== 1'b0) begin
            $fatal(1, "APB assertion failed: HOLD must not program instruction memory");
          end
        end
        STATE_LOAD: begin
          if (core_rst_n !== 1'b1) begin
            $fatal(1, "APB assertion failed: LOAD must release core reset");
          end
          if (prog_we !== 1'b1) begin
            $fatal(1, "APB assertion failed: LOAD must assert prog_we");
          end
          if (prog_addr !== load_index) begin
            $fatal(1, "APB assertion failed: prog_addr must track load_index");
          end
        end
        STATE_RUN: begin
          if (core_rst_n !== 1'b1) begin
            $fatal(1, "APB assertion failed: RUN must release core reset");
          end
          if (prog_we !== 1'b0) begin
            $fatal(1, "APB assertion failed: RUN must not assert prog_we");
          end
        end
        default: begin
          $fatal(1, "APB assertion failed: illegal wrapper state %0d", state);
        end
      endcase

      if (psel && penable && !pwrite && (paddr == ADDR_CONTROL)) begin
        case (state)
          STATE_HOLD: begin
            if (prdata !== 8'h00) begin
              $fatal(1, "APB assertion failed: HOLD control readback must be 0");
            end
          end
          STATE_LOAD: begin
            if (prdata !== 8'h02) begin
              $fatal(1, "APB assertion failed: LOAD control readback must be 2");
            end
          end
          STATE_RUN: begin
            if (prdata !== 8'h01) begin
              $fatal(1, "APB assertion failed: RUN control readback must be 1");
            end
          end
          default: begin
          end
        endcase
      end
    end
  end
endmodule
