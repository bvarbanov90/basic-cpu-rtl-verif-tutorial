import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

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


def ins(opcode: int, operand: int = 0) -> int:
    return ((opcode & 0xF) << 4) | (operand & 0xF)


class ReferenceCPU:
    def __init__(self) -> None:
        self.imem = [0] * 16
        self.dmem = [0] * 16
        self.acc = 0
        self.pc = 0
        self.zero = 1
        self.carry = 0
        self.neg = 0
        self.overflow = 0
        self.halted = 0

    def load_program(self, program) -> None:
        for idx, value in enumerate(program[:16]):
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


async def reset_dut(dut) -> None:
    dut.rst_n.value = 0
    dut.prog_we.value = 0
    dut.prog_addr.value = 0
    dut.prog_data.value = 0
    dut.dbg_mem_addr.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1


async def load_program(dut, program) -> None:
    for addr, value in enumerate(program[:16]):
        dut.prog_addr.value = addr
        dut.prog_data.value = value
        dut.prog_we.value = 1
        await RisingEdge(dut.clk)

    dut.prog_we.value = 0
    dut.prog_addr.value = 0
    dut.prog_data.value = 0


async def run_until_halt(dut, max_cycles: int = 128) -> int:
    for cycle in range(max_cycles):
        if int(dut.dbg_halted.value):
            return cycle
        await RisingEdge(dut.clk)
    raise AssertionError("DUT did not halt in time")


async def read_mem(dut, addr: int) -> int:
    dut.dbg_mem_addr.value = addr
    await Timer(1, unit="ns")
    return int(dut.dbg_mem_data.value)


def build_random_dataflow_program(seed: int, length: int = 12):
    rng = random.Random(seed)
    ops = [OPC_NOP, OPC_LDI, OPC_STA, OPC_LDA, OPC_ADD, OPC_SUB, OPC_AND, OPC_OR, OPC_XOR, OPC_SHL, OPC_SHR, OPC_CMP]

    program = []
    for _ in range(length - 1):
        opcode = rng.choice(ops)
        operand = rng.randrange(16)
        program.append(ins(opcode, operand))
    program.append(ins(OPC_HLT, 0))
    return program[:16]


def build_branch_stress_program(seed: int):
    rng = random.Random(seed)
    loop_count = 2 + rng.randrange(4)
    data_value = rng.randrange(16)
    aux_value = rng.randrange(16)
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


@cocotb.test()
async def directed_arithmetic_and_branch(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    program = [
        ins(OPC_LDI, 3),   # ACC = 3
        ins(OPC_STA, 0),   # dmem[0] = 3
        ins(OPC_LDI, 4),   # ACC = 4
        ins(OPC_ADD, 0),   # ACC = 7
        ins(OPC_STA, 1),   # dmem[1] = 7
        ins(OPC_SUB, 0),   # ACC = 4
        ins(OPC_STA, 2),   # dmem[2] = 4
        ins(OPC_LDI, 0),   # ACC = 0, zero=1
        ins(OPC_JZ, 10),   # jump because zero == 1
        ins(OPC_LDI, 15),  # skipped
        ins(OPC_STA, 3),   # dmem[3] = 0
        ins(OPC_HLT, 0),   # halt
    ]

    await load_program(dut, program)
    await run_until_halt(dut, max_cycles=64)

    assert int(dut.dbg_halted.value) == 1
    assert int(dut.dbg_acc.value) == 0
    assert await read_mem(dut, 0) == 3
    assert await read_mem(dut, 1) == 7
    assert await read_mem(dut, 2) == 4
    assert await read_mem(dut, 3) == 0


@cocotb.test()
async def randomized_program_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    program = build_random_dataflow_program(seed=20260221, length=12)
    model = ReferenceCPU()
    model.load_program(program)
    model.run(max_cycles=64)

    await load_program(dut, program)
    await run_until_halt(dut, max_cycles=64)

    assert int(dut.dbg_halted.value) == model.halted
    assert int(dut.dbg_acc.value) == model.acc
    assert int(dut.dbg_pc.value) == model.pc
    assert int(dut.dbg_zero.value) == model.zero
    assert int(dut.dbg_carry.value) == model.carry
    assert int(dut.dbg_neg.value) == model.neg
    assert int(dut.dbg_overflow.value) == model.overflow

    for addr in range(16):
        observed = await read_mem(dut, addr)
        expected = model.dmem[addr]
        assert observed == expected, f"Mismatch at dmem[{addr}]: got {observed}, expected {expected}"


@cocotb.test()
async def branch_stress_program_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    program = build_branch_stress_program(seed=0xBADC0DE0)
    model = ReferenceCPU()
    model.load_program(program)
    model.run(max_cycles=128)

    await load_program(dut, program)
    await run_until_halt(dut, max_cycles=128)

    assert int(dut.dbg_halted.value) == model.halted
    assert int(dut.dbg_acc.value) == model.acc
    assert int(dut.dbg_pc.value) == model.pc
    assert int(dut.dbg_zero.value) == model.zero
    assert int(dut.dbg_carry.value) == model.carry
    assert int(dut.dbg_neg.value) == model.neg
    assert int(dut.dbg_overflow.value) == model.overflow

    for addr in range(16):
        observed = await read_mem(dut, addr)
        expected = model.dmem[addr]
        assert observed == expected, f"Mismatch at dmem[{addr}]: got {observed}, expected {expected}"
