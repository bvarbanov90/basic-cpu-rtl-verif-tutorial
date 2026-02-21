module simple_cpu (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       prog_we,
    input  logic [3:0] prog_addr,
    input  logic [7:0] prog_data,
    input  logic [3:0] dbg_mem_addr,
    output logic [7:0] dbg_mem_data,
    output logic [7:0] dbg_acc,
    output logic [3:0] dbg_pc,
    output logic       dbg_zero,
    output logic       dbg_carry,
    output logic       dbg_neg,
    output logic       dbg_overflow,
    output logic       dbg_halted
);
    localparam logic [3:0] OPC_NOP = 4'h0;
    localparam logic [3:0] OPC_LDI = 4'h1;
    localparam logic [3:0] OPC_ADD = 4'h2;
    localparam logic [3:0] OPC_SUB = 4'h3;
    localparam logic [3:0] OPC_STA = 4'h4;
    localparam logic [3:0] OPC_LDA = 4'h5;
    localparam logic [3:0] OPC_JMP = 4'h6;
    localparam logic [3:0] OPC_JZ  = 4'h7;
    localparam logic [3:0] OPC_HLT = 4'h8;
    localparam logic [3:0] OPC_AND = 4'h9;
    localparam logic [3:0] OPC_OR  = 4'hA;
    localparam logic [3:0] OPC_XOR = 4'hB;
    localparam logic [3:0] OPC_SHL = 4'hC;
    localparam logic [3:0] OPC_SHR = 4'hD;
    localparam logic [3:0] OPC_CMP = 4'hE;

    logic [7:0] imem [0:15];
    logic [7:0] dmem [0:15];

    logic [7:0] acc;
    logic [3:0] pc;
    logic       zero;
    logic       carry;
    logic       neg;
    logic       overflow;
    logic       halted;

    logic [7:0] instr;
    logic [3:0] opcode;
    logic [3:0] operand;
    logic [7:0] op_b;
    logic [7:0] next_acc;
    logic [3:0] next_pc;
    logic       next_zero;
    logic       next_carry;
    logic       next_neg;
    logic       next_overflow;
    logic       next_halted;
    logic [8:0] add_result;
    logic [8:0] sub_result;
    logic [7:0] shift_left_result;
    logic [7:0] shift_right_result;
    logic       add_overflow;
    logic       sub_overflow;
    integer i;

    assign dbg_acc = acc;
    assign dbg_pc = pc;
    assign dbg_zero = zero;
    assign dbg_carry = carry;
    assign dbg_neg = neg;
    assign dbg_overflow = overflow;
    assign dbg_halted = halted;
    assign dbg_mem_data = dmem[dbg_mem_addr];

    always_comb begin
        instr = imem[pc];
        opcode = instr[7:4];
        operand = instr[3:0];
        op_b = dmem[operand];

        add_result = {1'b0, acc} + {1'b0, op_b};
        sub_result = {1'b0, acc} - {1'b0, op_b};
        shift_left_result = {acc[6:0], 1'b0};
        shift_right_result = {1'b0, acc[7:1]};

        add_overflow = (~(acc[7] ^ op_b[7])) & (acc[7] ^ add_result[7]);
        sub_overflow = (acc[7] ^ op_b[7]) & (acc[7] ^ sub_result[7]);

        next_acc = acc;
        next_pc = pc + 4'd1;
        next_zero = zero;
        next_carry = carry;
        next_neg = neg;
        next_overflow = overflow;
        next_halted = halted;

        case (opcode)
            OPC_NOP: begin
            end
            OPC_LDI: begin
                next_acc = {4'h0, operand};
                next_zero = ({4'h0, operand} == 8'h00);
                next_neg = 1'b0;
                next_carry = 1'b0;
                next_overflow = 1'b0;
            end
            OPC_ADD: begin
                next_acc = add_result[7:0];
                next_zero = (add_result[7:0] == 8'h00);
                next_neg = add_result[7];
                next_carry = add_result[8];
                next_overflow = add_overflow;
            end
            OPC_SUB: begin
                next_acc = sub_result[7:0];
                next_zero = (sub_result[7:0] == 8'h00);
                next_neg = sub_result[7];
                next_carry = ~sub_result[8];
                next_overflow = sub_overflow;
            end
            OPC_STA: begin
            end
            OPC_LDA: begin
                next_acc = op_b;
                next_zero = (op_b == 8'h00);
                next_neg = op_b[7];
                next_carry = 1'b0;
                next_overflow = 1'b0;
            end
            OPC_JMP: begin
                next_pc = operand;
            end
            OPC_JZ: begin
                if (zero) begin
                    next_pc = operand;
                end
            end
            OPC_HLT: begin
                next_pc = pc;
                next_halted = 1'b1;
            end
            OPC_AND: begin
                next_acc = acc & op_b;
                next_zero = ((acc & op_b) == 8'h00);
                next_neg = (((acc & op_b) & 8'h80) != 8'h00);
                next_carry = 1'b0;
                next_overflow = 1'b0;
            end
            OPC_OR: begin
                next_acc = acc | op_b;
                next_zero = ((acc | op_b) == 8'h00);
                next_neg = (((acc | op_b) & 8'h80) != 8'h00);
                next_carry = 1'b0;
                next_overflow = 1'b0;
            end
            OPC_XOR: begin
                next_acc = acc ^ op_b;
                next_zero = ((acc ^ op_b) == 8'h00);
                next_neg = (((acc ^ op_b) & 8'h80) != 8'h00);
                next_carry = 1'b0;
                next_overflow = 1'b0;
            end
            OPC_SHL: begin
                next_acc = shift_left_result;
                next_zero = (shift_left_result == 8'h00);
                next_neg = shift_left_result[7];
                next_carry = acc[7];
                next_overflow = acc[7] ^ shift_left_result[7];
            end
            OPC_SHR: begin
                next_acc = shift_right_result;
                next_zero = (shift_right_result == 8'h00);
                next_neg = shift_right_result[7];
                next_carry = acc[0];
                next_overflow = 1'b0;
            end
            OPC_CMP: begin
                next_zero = (sub_result[7:0] == 8'h00);
                next_neg = sub_result[7];
                next_carry = ~sub_result[8];
                next_overflow = sub_overflow;
            end
            default: begin
                next_pc = pc;
                next_halted = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc <= 8'h00;
            pc <= 4'h0;
            zero <= 1'b1;
            carry <= 1'b0;
            neg <= 1'b0;
            overflow <= 1'b0;
            halted <= 1'b0;
            for (i = 0; i < 16; i = i + 1) begin
                imem[i] <= 8'h00;
                dmem[i] <= 8'h00;
            end
        end else begin
            if (prog_we) begin
                imem[prog_addr] <= prog_data;
            end

            if (!halted && !prog_we) begin
                acc <= next_acc;
                pc <= next_pc;
                zero <= next_zero;
                carry <= next_carry;
                neg <= next_neg;
                overflow <= next_overflow;
                halted <= next_halted;
                if (opcode == OPC_STA) begin
                    dmem[operand] <= acc;
                end
            end
        end
    end
endmodule
