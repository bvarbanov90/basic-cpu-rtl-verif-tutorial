import json
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, Timer

from scripts.asm import assemble, parse_source
from tb.core_bus import SimpleCpuCoreBus
from tb.cpu_lib import (
    OPC_ADD,
    OPC_AND,
    OPC_CMP,
    OPC_HLT,
    OPC_JMP,
    OPC_JZ,
    OPC_LDA,
    OPC_LDI,
    OPC_NOP,
    OPC_OR,
    OPC_SHL,
    OPC_SHR,
    OPC_STA,
    OPC_SUB,
    OPC_XOR,
    ReferenceCPU,
    build_branch_stress_program,
    build_random_dataflow_program,
    ins,
)
from tb.protocol_conformance import run_protocol_conformance_suite


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
        await Timer(1, unit="ns")

    dut.prog_we.value = 0
    dut.prog_addr.value = 0
    dut.prog_data.value = 0


async def program_word(dut, addr: int, value: int) -> None:
    dut.prog_addr.value = addr & 0xF
    dut.prog_data.value = value & 0xFF
    dut.prog_we.value = 1
    await RisingEdge(dut.clk)
    await Timer(1, unit="ns")
    dut.prog_we.value = 0
    dut.prog_addr.value = 0
    dut.prog_data.value = 0


def start_program_word(dut, addr: int, value: int) -> None:
    dut.prog_addr.value = addr & 0xF
    dut.prog_data.value = value & 0xFF
    dut.prog_we.value = 1


async def stop_program_word(dut) -> None:
    await Timer(1, unit="ns")
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


async def sample_snapshot(dut) -> dict:
    dmem = []
    for addr in range(16):
        dmem.append(await read_mem(dut, addr))
    return {
        "halted": int(dut.dbg_halted.value),
        "acc": int(dut.dbg_acc.value),
        "pc": int(dut.dbg_pc.value),
        "zero": int(dut.dbg_zero.value),
        "carry": int(dut.dbg_carry.value),
        "neg": int(dut.dbg_neg.value),
        "overflow": int(dut.dbg_overflow.value),
        "dmem": dmem,
    }


async def assert_matches_model(dut, model: ReferenceCPU, label: str) -> None:
    assert int(dut.dbg_halted.value) == model.halted, f"{label}: HALTED mismatch"
    assert int(dut.dbg_acc.value) == model.acc, f"{label}: ACC mismatch"
    assert int(dut.dbg_pc.value) == model.pc, f"{label}: PC mismatch"
    assert int(dut.dbg_zero.value) == model.zero, f"{label}: ZERO mismatch"
    assert int(dut.dbg_carry.value) == model.carry, f"{label}: CARRY mismatch"
    assert int(dut.dbg_neg.value) == model.neg, f"{label}: NEG mismatch"
    assert int(dut.dbg_overflow.value) == model.overflow, f"{label}: OVERFLOW mismatch"

    for addr in range(16):
        observed = await read_mem(dut, addr)
        expected = model.dmem[addr]
        assert observed == expected, f"{label}: dmem[{addr}] got {observed}, expected {expected}"


async def run_program_against_model(dut, program, max_cycles: int, label: str) -> None:
    model = ReferenceCPU()
    model.load_program(program)
    model.run(max_cycles=max_cycles)

    await reset_dut(dut)
    await load_program(dut, program)
    await run_until_halt(dut, max_cycles=max_cycles)
    await assert_matches_model(dut, model, label)


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
    program = build_random_dataflow_program(seed=20260221, length=12)
    await run_program_against_model(dut, program, max_cycles=64, label="randomized_program")


@cocotb.test()
async def protocol_conformance_matches_reference_suite(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    core = SimpleCpuCoreBus(dut)
    await run_protocol_conformance_suite(core, str(dut._name))


@cocotb.test()
async def branch_stress_program_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    program = build_branch_stress_program(seed=0xBADC0DE0)
    await run_program_against_model(dut, program, max_cycles=128, label="branch_stress_program")


@cocotb.test()
async def assembler_corpus_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    project_root = Path(__file__).resolve().parents[1]
    manifest = json.loads((project_root / "docs" / "assembler-regressions.json").read_text(encoding="utf-8"))

    for entry in manifest["programs"]:
        source_path = project_root / entry["source"]
        stmts, labels = parse_source(source_path.read_text(encoding="utf-8"))
        program = assemble(stmts, labels)
        await run_program_against_model(dut, program, max_cycles=256, label=entry["name"])


@cocotb.test()
async def program_write_stalls_and_retargets_execution(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    base_program = [
        ins(OPC_LDI, 1),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 2),
        ins(OPC_STA, 1),
        ins(OPC_LDI, 3),
        ins(OPC_STA, 2),
        ins(OPC_LDI, 4),
        ins(OPC_STA, 3),
        ins(OPC_HLT, 0),
    ]
    patched_program = list(base_program)
    patched_program[6] = ins(OPC_LDI, 9)

    model = ReferenceCPU()
    model.load_program(patched_program)
    model.run(max_cycles=64)

    await reset_dut(dut)
    await load_program(dut, base_program)

    await RisingEdge(dut.clk)
    start_program_word(dut, 6, patched_program[6])
    await RisingEdge(dut.clk)
    snapshot_prog_cycle_0 = await sample_snapshot(dut)
    await RisingEdge(dut.clk)
    snapshot_prog_cycle_1 = await sample_snapshot(dut)
    assert snapshot_prog_cycle_1 == snapshot_prog_cycle_0, (
        "architectural state should stop advancing while prog_we remains asserted: "
        f"cycle0={snapshot_prog_cycle_0} cycle1={snapshot_prog_cycle_1}"
    )
    await stop_program_word(dut)

    await run_until_halt(dut, max_cycles=64)
    await assert_matches_model(dut, model, label="program_port_patch")
