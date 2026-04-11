module simple_cpu_mmio_wait (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       bus_valid,
    input  logic       bus_write,
    input  logic [7:0] bus_addr,
    input  logic [7:0] bus_wdata,
    output logic       bus_ready,
    output logic [7:0] bus_rdata
);
    localparam logic [1:0] WAIT_CYCLES = 2'd1;

    logic       pending;
    logic [1:0] wait_count;
    logic       req_write;
    logic [7:0] req_addr;
    logic [7:0] req_wdata;

    logic       inner_bus_valid;
    logic       inner_bus_ready;
    logic [7:0] inner_bus_rdata;

    assign inner_bus_valid = pending && (wait_count == 2'd0);
    assign bus_ready = inner_bus_valid && inner_bus_ready;
    assign bus_rdata = inner_bus_rdata;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 1'b0;
            wait_count <= WAIT_CYCLES;
            req_write <= 1'b0;
            req_addr <= 8'h00;
            req_wdata <= 8'h00;
        end else begin
            if (!pending) begin
                if (bus_valid) begin
                    pending <= 1'b1;
                    wait_count <= WAIT_CYCLES;
                    req_write <= bus_write;
                    req_addr <= bus_addr;
                    req_wdata <= bus_wdata;
                end
            end else if (wait_count != 2'd0) begin
                wait_count <= wait_count - 2'd1;
            end else begin
                pending <= 1'b0;
            end
        end
    end

    simple_cpu_mmio inner (
        .clk(clk),
        .rst_n(rst_n),
        .bus_valid(inner_bus_valid),
        .bus_write(req_write),
        .bus_addr(req_addr),
        .bus_wdata(req_wdata),
        .bus_ready(inner_bus_ready),
        .bus_rdata(inner_bus_rdata)
    );
endmodule
