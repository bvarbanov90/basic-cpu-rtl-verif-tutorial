from __future__ import annotations

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from tb.cpu_lib import ReferenceCPU, build_logic_ops_program, ins, OPC_HLT, OPC_LDI, OPC_STA
from tb.mmio_bus import ADDR_ACC, ADDR_CONTROL, ADDR_STATUS, SimpleCpuMmioBus


async def assert_matches_model(mmio: SimpleCpuMmioBus, model: ReferenceCPU, label: str) -> None:
    observed = await mmio.sample_state()
    assert observed.halted == model.halted, f"{label}: HALTED mismatch"
    assert observed.acc == model.acc, f"{label}: ACC mismatch"
    assert observed.pc == model.pc, f"{label}: PC mismatch"
    assert observed.zero == model.zero, f"{label}: ZERO mismatch"
    assert observed.carry == model.carry, f"{label}: CARRY mismatch"
    assert observed.neg == model.neg, f"{label}: NEG mismatch"
    assert observed.overflow == model.overflow, f"{label}: OVERFLOW mismatch"
    assert observed.dmem == model.dmem, f"{label}: DMEM mismatch"


@cocotb.test()
async def mmio_program_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    mmio = SimpleCpuMmioBus(dut)
    await mmio.reset()

    program = build_logic_ops_program()
    model = ReferenceCPU()
    model.load_program(program)
    model.run(max_cycles=128)

    await mmio.load_shadow_program(program)
    for addr, value in enumerate(program[:16]):
        assert await mmio.read(addr) == value, f"shadow[{addr}] readback mismatch"

    await mmio.start_program()
    await mmio.run_until_halt(max_cycles=256)
    await assert_matches_model(mmio, model, "mmio_logic_ops")


@cocotb.test()
async def mmio_shadow_fault_injection_requires_reload(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    mmio = SimpleCpuMmioBus(dut)
    await mmio.reset()

    base_program = [
        ins(OPC_LDI, 2),
        ins(OPC_STA, 0),
        ins(OPC_LDI, 5),
        ins(OPC_STA, 1),
        ins(OPC_HLT, 0),
    ]
    patched_program = list(base_program)
    patched_program[2] = ins(OPC_LDI, 9)

    model_initial = ReferenceCPU()
    model_initial.load_program(base_program)
    model_initial.run(max_cycles=64)

    model_reloaded = ReferenceCPU()
    model_reloaded.load_program(patched_program)
    model_reloaded.run(max_cycles=64)

    await mmio.load_shadow_program(base_program)
    await mmio.start_program()

    await RisingEdge(dut.clk)
    await mmio.write(2, patched_program[2])
    assert await mmio.read(2) == patched_program[2], "shadow image should update immediately"

    await mmio.run_until_halt(max_cycles=128)
    await assert_matches_model(mmio, model_initial, "mmio_shadow_current_run")

    await mmio.stop_program()
    await mmio.start_program()
    await mmio.run_until_halt(max_cycles=128)
    await assert_matches_model(mmio, model_reloaded, "mmio_shadow_after_reload")


@cocotb.test()
async def mmio_control_status_readback(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    mmio = SimpleCpuMmioBus(dut)
    await mmio.reset()

    assert await mmio.read(ADDR_CONTROL) == 0x00

    program = [
        ins(OPC_LDI, 1),
        ins(OPC_STA, 0),
        ins(OPC_HLT, 0),
    ]
    await mmio.load_shadow_program(program)
    await mmio.write(ADDR_CONTROL, 0x01)

    seen_load = False
    seen_run = False
    for _ in range(40):
        control = await mmio.read(ADDR_CONTROL)
        if (control & 0x2) != 0:
            seen_load = True
        if (control & 0x1) != 0:
            seen_run = True
            break
        await RisingEdge(dut.clk)

    assert seen_load, "wrapper should expose LOAD state before RUN"
    assert seen_run, "wrapper should expose RUN state after LOAD"

    await mmio.run_until_halt(max_cycles=64)
    status = await mmio.read(ADDR_STATUS)
    assert ((status >> 4) & 0x1) == 1, "HALTED bit should be set after program completion"
    assert await mmio.read(ADDR_ACC) == 1
    assert await mmio.read_dmem(0) == 1
