module simple_cpu_mmio (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       bus_valid,
    input  logic       bus_write,
    input  logic [7:0] bus_addr,
    input  logic [7:0] bus_wdata,
    output logic       bus_ready,
    output logic [7:0] bus_rdata
`ifdef FORMAL
    ,
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
    localparam logic [1:0] STATE_HOLD = 2'd0;
    localparam logic [1:0] STATE_LOAD = 2'd1;
    localparam logic [1:0] STATE_RUN  = 2'd2;

    localparam logic [7:0] ADDR_STATUS  = 8'h10;
    localparam logic [7:0] ADDR_ACC     = 8'h11;
    localparam logic [7:0] ADDR_PC      = 8'h12;
    localparam logic [7:0] ADDR_CONTROL = 8'h30;

    logic [7:0] shadow_imem [0:15];
    logic [1:0] state;
    logic [3:0] load_index;
    logic       core_rst_n;
    logic       prog_we;
    logic [3:0] prog_addr;
    logic [7:0] prog_data;
    logic [3:0] dbg_mem_addr;
    logic [7:0] dbg_mem_data;
    logic [7:0] dbg_acc;
    logic [3:0] dbg_pc;
    logic       dbg_zero;
    logic       dbg_carry;
    logic       dbg_neg;
    logic       dbg_overflow;
    logic       dbg_halted;
    integer     idx;
`ifdef FORMAL
    genvar      formal_idx;
`endif

    assign bus_ready = 1'b1;
    assign core_rst_n = rst_n && (state != STATE_HOLD);
    assign prog_we = (state == STATE_LOAD);
    assign prog_addr = load_index;
    assign prog_data = shadow_imem[load_index];
    assign dbg_mem_addr = bus_addr[3:0];
`ifdef FORMAL
    assign formal_state = state;
    assign formal_load_index = load_index;
    assign formal_core_rst_n = core_rst_n;
    assign formal_prog_we = prog_we;
    assign formal_prog_addr = prog_addr;
    assign formal_prog_data = prog_data;
    assign formal_dbg_mem_data = dbg_mem_data;
    assign formal_dbg_acc = dbg_acc;
    assign formal_dbg_pc = dbg_pc;
    assign formal_dbg_zero = dbg_zero;
    assign formal_dbg_carry = dbg_carry;
    assign formal_dbg_neg = dbg_neg;
    assign formal_dbg_overflow = dbg_overflow;
    assign formal_dbg_halted = dbg_halted;

    generate
        for (formal_idx = 0; formal_idx < 16; formal_idx = formal_idx + 1) begin : gen_formal_shadow
            assign formal_shadow_flat[(formal_idx * 8) +: 8] = shadow_imem[formal_idx];
        end
    endgenerate
`endif

    always_comb begin
        bus_rdata = 8'h00;

        if (bus_addr[7:4] == 4'h0) begin
            bus_rdata = shadow_imem[bus_addr[3:0]];
        end else if (bus_addr[7:4] == 4'h2) begin
            bus_rdata = dbg_mem_data;
        end else begin
            case (bus_addr)
                ADDR_STATUS: begin
                    bus_rdata = {3'b000, dbg_halted, dbg_overflow, dbg_neg, dbg_carry, dbg_zero};
                end
                ADDR_ACC: begin
                    bus_rdata = dbg_acc;
                end
                ADDR_PC: begin
                    bus_rdata = {4'h0, dbg_pc};
                end
                ADDR_CONTROL: begin
                    bus_rdata = {6'b000000, (state == STATE_LOAD), (state == STATE_RUN)};
                end
                default: begin
                    bus_rdata = 8'h00;
                end
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_HOLD;
            load_index <= 4'h0;
            for (idx = 0; idx < 16; idx = idx + 1) begin
                shadow_imem[idx] <= 8'h00;
            end
        end else begin
            case (state)
                STATE_HOLD: begin
                    load_index <= 4'h0;
                    if (bus_valid && bus_write) begin
                        if (bus_addr[7:4] == 4'h0) begin
                            shadow_imem[bus_addr[3:0]] <= bus_wdata;
                        end else if ((bus_addr == ADDR_CONTROL) && bus_wdata[0]) begin
                            state <= STATE_LOAD;
                        end
                    end
                end
                STATE_LOAD: begin
                    load_index <= load_index + 4'd1;
                    if (load_index == 4'd15) begin
                        state <= STATE_RUN;
                    end
                end
                default: begin
                    if (bus_valid && bus_write) begin
                        if (bus_addr[7:4] == 4'h0) begin
                            shadow_imem[bus_addr[3:0]] <= bus_wdata;
                        end else if ((bus_addr == ADDR_CONTROL) && !bus_wdata[0]) begin
                            state <= STATE_HOLD;
                            load_index <= 4'h0;
                        end
                    end
                end
            endcase
        end
    end

    simple_cpu core (
        .clk(clk),
        .rst_n(core_rst_n),
        .prog_we(prog_we),
        .prog_addr(prog_addr),
        .prog_data(prog_data),
        .dbg_mem_addr(dbg_mem_addr),
        .dbg_mem_data(dbg_mem_data),
        .dbg_acc(dbg_acc),
        .dbg_pc(dbg_pc),
        .dbg_zero(dbg_zero),
        .dbg_carry(dbg_carry),
        .dbg_neg(dbg_neg),
        .dbg_overflow(dbg_overflow),
        .dbg_halted(dbg_halted)
    );
endmodule
