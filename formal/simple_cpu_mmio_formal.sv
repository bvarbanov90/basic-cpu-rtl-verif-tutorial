module simple_cpu_mmio_formal;
    localparam [1:0] STATE_HOLD = 2'd0;
    localparam [1:0] STATE_LOAD = 2'd1;
    localparam [1:0] STATE_RUN  = 2'd2;

    localparam [7:0] ADDR_STATUS  = 8'h10;
    localparam [7:0] ADDR_ACC     = 8'h11;
    localparam [7:0] ADDR_PC      = 8'h12;
    localparam [7:0] ADDR_CONTROL = 8'h30;

    reg rst_n = 1'b0;
    reg bus_valid = 1'b0;
    reg bus_write = 1'b0;
    reg [7:0] bus_addr = 8'h00;
    reg [7:0] bus_wdata = 8'h00;

    wire bus_ready;
    wire [7:0] bus_rdata;
    wire [1:0] formal_state;
    wire [3:0] formal_load_index;
    wire formal_core_rst_n;
    wire formal_prog_we;
    wire [3:0] formal_prog_addr;
    wire [7:0] formal_prog_data;
    wire [127:0] formal_shadow_flat;
    wire [7:0] formal_dbg_mem_data;
    wire [7:0] formal_dbg_acc;
    wire [3:0] formal_dbg_pc;
    wire formal_dbg_zero;
    wire formal_dbg_carry;
    wire formal_dbg_neg;
    wire formal_dbg_overflow;
    wire formal_dbg_halted;

    reg [1:0] reset_counter = 2'd0;
    reg past_valid = 1'b0;
    reg saw_start = 1'b0;
    reg saw_stop = 1'b0;

    simple_cpu_mmio dut (
        .clk($global_clock),
        .rst_n(rst_n),
        .bus_valid(bus_valid),
        .bus_write(bus_write),
        .bus_addr(bus_addr),
        .bus_wdata(bus_wdata),
        .bus_ready(bus_ready),
        .bus_rdata(bus_rdata),
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
    );

    always @(posedge $global_clock) begin
        past_valid <= 1'b1;

        if (reset_counter < 2'd2) begin
            reset_counter <= reset_counter + 2'd1;
            rst_n <= 1'b0;
            bus_valid <= 1'b0;
            bus_write <= 1'b0;
            bus_addr <= 8'h00;
            bus_wdata <= 8'h00;
            saw_start <= 1'b0;
            saw_stop <= 1'b0;
        end else begin
            rst_n <= 1'b1;
            bus_valid <= $anyseq;
            bus_write <= $anyseq;
            bus_addr <= $anyseq;
            bus_wdata <= $anyseq;
            saw_start <= saw_start || (bus_valid && bus_write && (bus_addr == ADDR_CONTROL) && bus_wdata[0]);
            saw_stop <= saw_stop || (bus_valid && bus_write && (bus_addr == ADDR_CONTROL) && !bus_wdata[0]);
        end
    end

    always @(*) begin
        assert(bus_ready == 1'b1);

        if (bus_addr == 8'h00) begin
            assert(bus_rdata == formal_shadow_flat[7:0]);
        end else if (bus_addr == 8'h0F) begin
            assert(bus_rdata == formal_shadow_flat[127:120]);
        end else if (bus_addr[7:4] == 4'h0) begin
        end else if (bus_addr[7:4] == 4'h2) begin
            assert(bus_rdata == formal_dbg_mem_data);
        end else begin
            case (bus_addr)
                ADDR_STATUS: begin
                    assert(bus_rdata == {3'b000, formal_dbg_halted, formal_dbg_overflow, formal_dbg_neg, formal_dbg_carry, formal_dbg_zero});
                end
                ADDR_ACC: begin
                    assert(bus_rdata == formal_dbg_acc);
                end
                ADDR_PC: begin
                    assert(bus_rdata == {4'h0, formal_dbg_pc});
                end
                ADDR_CONTROL: begin
                    assert(bus_rdata == {6'b000000, (formal_state == STATE_LOAD), (formal_state == STATE_RUN)});
                end
                default: begin
                    assert(bus_rdata == 8'h00);
                end
            endcase
        end
    end

    always @(posedge $global_clock) begin
        if (past_valid && $past(!rst_n)) begin
            assert(formal_state == STATE_HOLD);
            assert(formal_load_index == 4'h0);
            assert(formal_core_rst_n == 1'b0);
        end

        if (past_valid && rst_n) begin
            assert(formal_core_rst_n == (formal_state != STATE_HOLD));
            assert(formal_prog_we == (formal_state == STATE_LOAD));
            assert(formal_prog_addr == formal_load_index);
            if (formal_state == STATE_HOLD) begin
                assert(formal_load_index == 4'h0);
            end
        end

        if (past_valid && $past(rst_n)) begin
            if ($past(formal_state) == STATE_HOLD) begin
                if ($past(bus_valid && bus_write && (bus_addr == ADDR_CONTROL) && bus_wdata[0])) begin
                    assert(formal_state == STATE_LOAD);
                end else begin
                    assert(formal_state == STATE_HOLD);
                end
                assert(formal_load_index == 4'h0);
            end

            if ($past(formal_state) == STATE_LOAD) begin
                assert(formal_load_index == ($past(formal_load_index) + 4'd1));
                if ($past(formal_load_index) == 4'd15) begin
                    assert(formal_state == STATE_RUN);
                end else begin
                    assert(formal_state == STATE_LOAD);
                end
            end

            if ($past(formal_state) == STATE_RUN) begin
                if ($past(bus_valid && bus_write && (bus_addr == ADDR_CONTROL) && !bus_wdata[0])) begin
                    assert(formal_state == STATE_HOLD);
                    assert(formal_load_index == 4'h0);
                end else begin
                    assert(formal_state == STATE_RUN);
                end
            end
        end
    end

    always @(posedge $global_clock) begin
        if (past_valid && $past(rst_n)) begin
            if ($past(formal_state) == STATE_HOLD) begin
                if ($past(bus_valid && bus_write && (bus_addr == 8'h00))) begin
                    assert(formal_shadow_flat[7:0] == $past(bus_wdata));
                end else begin
                    assert(formal_shadow_flat[7:0] == $past(formal_shadow_flat[7:0]));
                end

                if ($past(bus_valid && bus_write && (bus_addr == 8'h0F))) begin
                    assert(formal_shadow_flat[127:120] == $past(bus_wdata));
                end else begin
                    assert(formal_shadow_flat[127:120] == $past(formal_shadow_flat[127:120]));
                end
            end

            if ($past(formal_state) == STATE_LOAD) begin
                assert(formal_shadow_flat[7:0] == $past(formal_shadow_flat[7:0]));
                assert(formal_shadow_flat[127:120] == $past(formal_shadow_flat[127:120]));
            end

            if ($past(formal_state) == STATE_RUN) begin
                if ($past(bus_valid && bus_write && (bus_addr == 8'h00))) begin
                    assert(formal_shadow_flat[7:0] == $past(bus_wdata));
                end else begin
                    assert(formal_shadow_flat[7:0] == $past(formal_shadow_flat[7:0]));
                end

                if ($past(bus_valid && bus_write && (bus_addr == 8'h0F))) begin
                    assert(formal_shadow_flat[127:120] == $past(bus_wdata));
                end else begin
                    assert(formal_shadow_flat[127:120] == $past(formal_shadow_flat[127:120]));
                end
            end
        end
    end

    always @(posedge $global_clock) begin
        cover(past_valid && (formal_state == STATE_LOAD));
        cover(past_valid && (formal_state == STATE_RUN));
        cover(past_valid && $past(formal_state == STATE_RUN) && (formal_state == STATE_HOLD));
        cover(past_valid && (formal_state == STATE_HOLD) && (formal_shadow_flat[7:0] != 8'h00));
        cover(past_valid && saw_start && (formal_state == STATE_RUN) && formal_dbg_halted);
        cover(past_valid && saw_start && saw_stop && (formal_state == STATE_HOLD));
    end
endmodule
