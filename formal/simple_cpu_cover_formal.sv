module simple_cpu_cover_formal;
    reg rst_n = 1'b0;
    reg prog_we = 1'b0;
    reg [3:0] prog_addr = 4'h0;
    reg [7:0] prog_data = 8'h00;
    reg [3:0] dbg_mem_addr = 4'h0;

    wire [7:0] dbg_mem_data;
    wire [7:0] dbg_acc;
    wire [3:0] dbg_pc;
    wire dbg_zero;
    wire dbg_carry;
    wire dbg_neg;
    wire dbg_overflow;
    wire dbg_halted;

    reg [1:0] reset_counter = 2'd0;
    reg past_valid = 1'b0;
    reg saw_prog_write = 1'b0;
    reg saw_execute = 1'b0;

    simple_cpu dut (
        .clk($global_clock),
        .rst_n(rst_n),
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

    always @(posedge $global_clock) begin
        past_valid <= 1'b1;

        if (reset_counter < 2'd2) begin
            reset_counter <= reset_counter + 2'd1;
            rst_n <= 1'b0;
            prog_we <= 1'b0;
            prog_addr <= 4'h0;
            prog_data <= 8'h00;
            dbg_mem_addr <= 4'h0;
            saw_prog_write <= 1'b0;
            saw_execute <= 1'b0;
        end else begin
            rst_n <= 1'b1;
            prog_we <= $anyseq;
            prog_addr <= $anyseq;
            prog_data <= $anyseq;
            dbg_mem_addr <= $anyseq;
            saw_prog_write <= saw_prog_write || prog_we;
            saw_execute <= saw_execute || (!dbg_halted && !prog_we);
        end
    end

    always @(posedge $global_clock) begin
        cover(past_valid && saw_prog_write && saw_execute && dbg_halted);
    end
endmodule
