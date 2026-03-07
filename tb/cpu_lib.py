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


def ins(opcode: int, operand: int = 0) -> int:
    return ((opcode & 0xF) << 4) | (operand & 0xF)


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

    def load_program(self, program) -> None:
        for idx, value in enumerate(program[:MEM_SIZE]):
            self.imem[idx] = value & 0xFF

    def step(self) -> None:
        if self.halted:
            return

        instr = self.imem[self.pc]
        opcode = (instr >> 4) & 0xF
        operand = instr & 0xF
        op_b = self.dmem[operand]
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

    def run(self, max_cycles: int = 128) -> int:
        for cycle in range(max_cycles):
            if self.halted:
                return cycle
            self.step()
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
