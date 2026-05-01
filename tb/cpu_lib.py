from __future__ import annotations

import random
from dataclasses import dataclass

OPC_NOP = 0x0
OPC_LDI = 0x1
OPC_ADD = 0x2
OPC_SUB = 0x3
OPC_STA = 0x4
OPC_LDA = 0x5
OPC_JMP = 0x6
OPC_JZ = 0x7
OPC_HLT = 0x8
OPC_AND = 0x9
OPC_OR = 0xA
OPC_XOR = 0xB
OPC_SHL = 0xC
OPC_SHR = 0xD
OPC_CMP = 0xE

MEM_SIZE = 16

OPCODE_NAMES = {
    OPC_NOP: "NOP",
    OPC_LDI: "LDI",
    OPC_ADD: "ADD",
    OPC_SUB: "SUB",
    OPC_STA: "STA",
    OPC_LDA: "LDA",
    OPC_JMP: "JMP",
    OPC_JZ: "JZ",
    OPC_HLT: "HLT",
    OPC_AND: "AND",
    OPC_OR: "OR",
    OPC_XOR: "XOR",
    OPC_SHL: "SHL",
    OPC_SHR: "SHR",
    OPC_CMP: "CMP",
}

OPCODES_WITH_OPERANDS = {
    OPC_LDI,
    OPC_ADD,
    OPC_SUB,
    OPC_STA,
    OPC_LDA,
    OPC_JMP,
    OPC_JZ,
    OPC_AND,
    OPC_OR,
    OPC_XOR,
    OPC_CMP,
}

OPCODES_WITH_DMEM_READ = {
    OPC_ADD,
    OPC_SUB,
    OPC_LDA,
    OPC_AND,
    OPC_OR,
    OPC_XOR,
    OPC_CMP,
}

OPCODES_WITH_DMEM_WRITE = {OPC_STA}


def ins(opcode: int, operand: int = 0) -> int:
    return ((opcode & 0xF) << 4) | (operand & 0xF)


def decode_instruction(word: int) -> tuple[int, int]:
    return (word >> 4) & 0xF, word & 0xF


def opcode_name(opcode: int) -> str:
    return OPCODE_NAMES.get(opcode & 0xF, f"OP{opcode & 0xF:X}")


def disassemble_instruction(word: int, address: int | None = None) -> str:
    opcode, operand = decode_instruction(word)
    prefix = "" if address is None else f"{address & 0xF:01X}: "

    if opcode not in OPCODE_NAMES:
        return f"{prefix}.BYTE 0x{word & 0xFF:02X} ; illegal opcode 0x{opcode:X}"
    if opcode in OPCODES_WITH_OPERANDS:
        return f"{prefix}{opcode_name(opcode)} 0x{operand:X}"
    return f"{prefix}{opcode_name(opcode)}"


def disassemble_program(program) -> list[str]:
    return [disassemble_instruction(value, address=addr) for addr, value in enumerate(program[:MEM_SIZE])]


@dataclass
class CpuFinalState:
    acc: int
    pc: int
    zero: int
    carry: int
    neg: int
    overflow: int
    halted: int
    dmem: list[int]


@dataclass
class CpuTraceStep:
    cycle: int
    pc_before: int
    instr: int
    opcode: int
    operand: int
    mnemonic: str
    acc_before: int
    acc_after: int
    pc_after: int
    zero_before: int
    zero_after: int
    carry_before: int
    carry_after: int
    neg_before: int
    neg_after: int
    overflow_before: int
    overflow_after: int
    halted_before: int
    halted_after: int
    dmem_addr: int | None
    dmem_before: int | None
    dmem_after: int | None

    def format_row(self) -> str:
        mem_part = "-"
        if self.dmem_addr is not None:
            before = "-" if self.dmem_before is None else f"{self.dmem_before:02X}"
            after = "-" if self.dmem_after is None else f"{self.dmem_after:02X}"
            mem_part = f"[{self.dmem_addr:X}] {before}->{after}"

        flags_before = f"Z{self.zero_before} C{self.carry_before} N{self.neg_before} V{self.overflow_before}"
        flags_after = f"Z{self.zero_after} C{self.carry_after} N{self.neg_after} V{self.overflow_after}"
        return (
            f"{self.cycle:02d} PC {self.pc_before:X}->{self.pc_after:X} "
            f"{self.instr:02X} {self.mnemonic:<3} {self.operand:X} "
            f"ACC {self.acc_before:02X}->{self.acc_after:02X} "
            f"{flags_before}->{flags_after} H{self.halted_before}->{self.halted_after} MEM {mem_part}"
        )


class ReferenceCPU:
    def __init__(self) -> None:
        self.imem = [0] * MEM_SIZE
        self.dmem = [0] * MEM_SIZE
        self.acc = 0
        self.pc = 0
        self.zero = 1
        self.carry = 0
        self.neg = 0
        self.overflow = 0
        self.halted = 0
        self.cycles = 0

    def load_program(self, program) -> None:
        for idx, value in enumerate(program[:MEM_SIZE]):
            self.imem[idx] = value & 0xFF

    def step(self) -> CpuTraceStep | None:
        if self.halted:
            return

        cycle = self.cycles
        pc_before = self.pc
        instr = self.imem[pc_before]
        opcode, operand = decode_instruction(instr)
        acc_before = self.acc
        zero_before = self.zero
        carry_before = self.carry
        neg_before = self.neg
        overflow_before = self.overflow
        halted_before = self.halted
        dmem_addr: int | None = None
        dmem_before: int | None = None

        op_b = self.dmem[operand]
        if opcode in OPCODES_WITH_DMEM_READ or opcode in OPCODES_WITH_DMEM_WRITE:
            dmem_addr = operand
            dmem_before = op_b
        next_pc = (self.pc + 1) & 0xF

        if opcode == OPC_NOP:
            pass
        elif opcode == OPC_LDI:
            self.acc = operand
            self.zero = int(self.acc == 0)
            self.neg = 0
            self.carry = 0
            self.overflow = 0
        elif opcode == OPC_ADD:
            old_acc = self.acc
            add_result = old_acc + op_b
            self.acc = add_result & 0xFF
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = int(add_result > 0xFF)
            self.overflow = int((~(old_acc ^ op_b) & (old_acc ^ self.acc) & 0x80) != 0)
        elif opcode == OPC_SUB:
            old_acc = self.acc
            sub_result = old_acc - op_b
            self.acc = sub_result & 0xFF
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = int(old_acc >= op_b)
            self.overflow = int((((old_acc ^ op_b) & (old_acc ^ self.acc)) & 0x80) != 0)
        elif opcode == OPC_STA:
            self.dmem[operand] = self.acc
        elif opcode == OPC_LDA:
            self.acc = op_b
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = 0
            self.overflow = 0
        elif opcode == OPC_JMP:
            next_pc = operand
        elif opcode == OPC_JZ:
            if self.zero:
                next_pc = operand
        elif opcode == OPC_HLT:
            self.halted = 1
            next_pc = self.pc
        elif opcode == OPC_AND:
            self.acc = self.acc & op_b
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = 0
            self.overflow = 0
        elif opcode == OPC_OR:
            self.acc = self.acc | op_b
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = 0
            self.overflow = 0
        elif opcode == OPC_XOR:
            self.acc = self.acc ^ op_b
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = 0
            self.overflow = 0
        elif opcode == OPC_SHL:
            old_acc = self.acc
            self.acc = (old_acc << 1) & 0xFF
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = (old_acc >> 7) & 0x1
            self.overflow = int(((old_acc ^ self.acc) & 0x80) != 0)
        elif opcode == OPC_SHR:
            old_acc = self.acc
            self.acc = (old_acc >> 1) & 0xFF
            self.zero = int(self.acc == 0)
            self.neg = (self.acc >> 7) & 0x1
            self.carry = old_acc & 0x1
            self.overflow = 0
        elif opcode == OPC_CMP:
            old_acc = self.acc
            cmp_result = (old_acc - op_b) & 0xFF
            self.zero = int(cmp_result == 0)
            self.neg = (cmp_result >> 7) & 0x1
            self.carry = int(old_acc >= op_b)
            self.overflow = int((((old_acc ^ op_b) & (old_acc ^ cmp_result)) & 0x80) != 0)
        else:
            self.halted = 1
            next_pc = self.pc

        self.pc = next_pc
        self.cycles += 1

        dmem_after = self.dmem[dmem_addr] if dmem_addr is not None else None
        return CpuTraceStep(
            cycle=cycle,
            pc_before=pc_before,
            instr=instr,
            opcode=opcode,
            operand=operand,
            mnemonic=opcode_name(opcode),
            acc_before=acc_before,
            acc_after=self.acc,
            pc_after=self.pc,
            zero_before=zero_before,
            zero_after=self.zero,
            carry_before=carry_before,
            carry_after=self.carry,
            neg_before=neg_before,
            neg_after=self.neg,
            overflow_before=overflow_before,
            overflow_after=self.overflow,
            halted_before=halted_before,
            halted_after=self.halted,
            dmem_addr=dmem_addr,
            dmem_before=dmem_before,
            dmem_after=dmem_after,
        )

    def run(self, max_cycles: int = 128) -> int:
        for cycle in range(max_cycles):
            if self.halted:
                return cycle
            self.step()
        raise AssertionError("Reference model did not halt in time")

    def trace_run(self, max_cycles: int = 128) -> list[CpuTraceStep]:
        trace: list[CpuTraceStep] = []
        for _ in range(max_cycles):
            if self.halted:
                return trace
            step = self.step()
            if step is not None:
                trace.append(step)
        raise AssertionError("Reference model did not halt in time")

    def final_state(self) -> CpuFinalState:
        return CpuFinalState(
            acc=self.acc,
            pc=self.pc,
            zero=self.zero,
            carry=self.carry,
            neg=self.neg,
            overflow=self.overflow,
            halted=self.halted,
            dmem=list(self.dmem),
        )


def build_random_dataflow_program(seed: int, length: int = 12):
    rng = random.Random(seed)
    ops = [OPC_NOP, OPC_LDI, OPC_STA, OPC_LDA, OPC_ADD, OPC_SUB, OPC_AND, OPC_OR, OPC_XOR, OPC_SHL, OPC_SHR, OPC_CMP]

    program = []
    for _ in range(length - 1):
        opcode = rng.choice(ops)
        operand = rng.randrange(MEM_SIZE)
        program.append(ins(opcode, operand))
    program.append(ins(OPC_HLT, 0))
    return program[:MEM_SIZE]


def build_branch_stress_program(seed: int):
    rng = random.Random(seed)
    loop_count = 2 + rng.randrange(4)
    data_value = rng.randrange(MEM_SIZE)
    aux_value = rng.randrange(MEM_SIZE)
    loop_opcode = rng.choice([OPC_ADD, OPC_SUB, OPC_AND, OPC_OR, OPC_XOR, OPC_CMP, OPC_SHL, OPC_SHR, OPC_NOP])
    loop_operand = rng.choice([0, 3])

    return [
        ins(OPC_LDI, loop_count),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 1),
        ins(OPC_STA, 1),
        ins(OPC_LDI, data_value),
        ins(OPC_STA, 2),
        ins(OPC_LDI, aux_value),
        ins(OPC_STA, 3),
        ins(OPC_LDA, 0),
        ins(OPC_SUB, 1),
        ins(OPC_STA, 0),
        ins(OPC_JZ, 15),
        ins(OPC_LDA, 2),
        ins(loop_opcode, loop_operand),
        ins(OPC_JMP, 8),
        ins(OPC_HLT, 0),
    ]


def build_smoke_program():
    return [
        ins(OPC_LDI, 3),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 4),
        ins(OPC_ADD, 0),
        ins(OPC_STA, 1),
        ins(OPC_LDI, 0),
        ins(OPC_JZ, 8),
        ins(OPC_LDI, 15),
        ins(OPC_HLT, 0),
    ]


def build_branch_not_taken_program():
    return [
        ins(OPC_NOP, 0),
        ins(OPC_LDI, 1),
        ins(OPC_JZ, 5),
        ins(OPC_LDI, 9),
        ins(OPC_HLT, 0),
        ins(OPC_LDI, 0),
    ]


def build_jump_loop_program():
    return [
        ins(OPC_LDI, 3),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 1),
        ins(OPC_STA, 1),
        ins(OPC_LDA, 0),
        ins(OPC_SUB, 1),
        ins(OPC_STA, 0),
        ins(OPC_JZ, 9),
        ins(OPC_JMP, 4),
        ins(OPC_HLT, 0),
    ]


def build_logic_ops_program():
    return [
        ins(OPC_LDI, 3),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 12),
        ins(OPC_STA, 1),
        ins(OPC_LDA, 0),
        ins(OPC_AND, 1),
        ins(OPC_OR, 0),
        ins(OPC_XOR, 1),
        ins(OPC_SHL, 0),
        ins(OPC_SHR, 0),
        ins(OPC_CMP, 0),
        ins(OPC_SUB, 1),
        ins(OPC_HLT, 0),
    ]


def build_add_carry_program():
    return [
        ins(OPC_LDI, 15),
        ins(OPC_SHL, 0),
        ins(OPC_SHL, 0),
        ins(OPC_SHL, 0),
        ins(OPC_SHL, 0),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 15),
        ins(OPC_ADD, 0),
        ins(OPC_ADD, 0),
        ins(OPC_HLT, 0),
    ]


def build_sub_carry_program():
    return [
        ins(OPC_LDI, 2),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 1),
        ins(OPC_SUB, 0),
        ins(OPC_LDI, 3),
        ins(OPC_SUB, 0),
        ins(OPC_HLT, 0),
    ]


def build_shift_overflow_program():
    return [
        ins(OPC_LDI, 8),
        ins(OPC_SHL, 0),
        ins(OPC_SHL, 0),
        ins(OPC_SHL, 0),
        ins(OPC_SHL, 0),
        ins(OPC_HLT, 0),
    ]


def build_cmp_negative_program():
    return [
        ins(OPC_LDI, 2),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 1),
        ins(OPC_CMP, 0),
        ins(OPC_HLT, 0),
    ]


def build_illegal_opcode_program():
    return [
        0xF0,
        ins(OPC_LDI, 9),
    ]
