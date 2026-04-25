module simple_cpu_axi_lite (
    input  logic       aclk,
    input  logic       aresetn,
    input  logic       axi_awvalid,
    output logic       axi_awready,
    input  logic [7:0] axi_awaddr,
    input  logic       axi_wvalid,
    output logic       axi_wready,
    input  logic [7:0] axi_wdata,
    output logic       axi_bvalid,
    input  logic       axi_bready,
    output logic [1:0] axi_bresp,
    input  logic       axi_arvalid,
    output logic       axi_arready,
    input  logic [7:0] axi_araddr,
    output logic       axi_rvalid,
    input  logic       axi_rready,
    output logic [7:0] axi_rdata,
    output logic [1:0] axi_rresp
`ifdef FORMAL
    ,
    output logic         formal_mmio_valid,
    output logic         formal_mmio_ready,
    output logic [7:0]   formal_mmio_rdata,
    output logic         formal_mmio_write,
    output logic [7:0]   formal_mmio_addr,
    output logic [7:0]   formal_read_addr_q,
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
  logic       write_resp_valid;
  logic       read_resp_valid;
  logic [7:0] read_data_q;
  /* verilator lint_off UNUSEDSIGNAL */
  logic [7:0] read_addr_q;
  /* verilator lint_on UNUSEDSIGNAL */

  logic       write_accept;
  logic       read_accept;
  logic       mmio_valid;
  logic       mmio_write;
  logic [7:0] mmio_addr;
  logic [7:0] mmio_wdata;
  logic       mmio_ready;
  logic [7:0] mmio_rdata;

  assign write_accept = mmio_ready && !write_resp_valid && axi_awvalid && axi_wvalid;
  assign read_accept  = mmio_ready && !read_resp_valid && !write_accept && axi_arvalid;

  assign axi_awready = write_accept;
  assign axi_wready  = write_accept;
  assign axi_arready = read_accept;

  assign axi_bvalid = write_resp_valid;
  assign axi_bresp  = 2'b00;
  assign axi_rvalid = read_resp_valid;
  assign axi_rdata  = read_data_q;
  assign axi_rresp  = 2'b00;

  assign mmio_valid = write_accept || read_accept;
  assign mmio_write = write_accept;
  assign mmio_addr  = write_accept ? axi_awaddr : axi_araddr;
  assign mmio_wdata = axi_wdata;

`ifdef FORMAL
  assign formal_mmio_valid = mmio_valid;
  assign formal_mmio_ready = mmio_ready;
  assign formal_mmio_rdata = mmio_rdata;
  assign formal_mmio_write = mmio_write;
  assign formal_mmio_addr  = mmio_addr;
  assign formal_read_addr_q = read_addr_q;
`endif

  initial begin
    write_resp_valid = 1'b0;
    read_resp_valid  = 1'b0;
    read_data_q      = 8'h00;
    read_addr_q      = 8'h00;
  end

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      write_resp_valid <= 1'b0;
      read_resp_valid  <= 1'b0;
      read_data_q      <= 8'h00;
      read_addr_q      <= 8'h00;
    end else begin
      if (write_resp_valid && axi_bready) begin
        write_resp_valid <= 1'b0;
      end
      if (write_accept) begin
        write_resp_valid <= 1'b1;
      end

      if (read_resp_valid && axi_rready) begin
        read_resp_valid <= 1'b0;
      end
      if (read_accept) begin
        read_resp_valid <= 1'b1;
        read_data_q     <= mmio_rdata;
        read_addr_q     <= axi_araddr;
      end
    end
  end

  simple_cpu_mmio inner (
      .clk(aclk),
      .rst_n(aresetn),
      .bus_valid(mmio_valid),
      .bus_write(mmio_write),
      .bus_addr(mmio_addr),
      .bus_wdata(mmio_wdata),
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
