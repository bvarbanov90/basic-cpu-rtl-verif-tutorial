from __future__ import annotations

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from tb.apb_bus import SimpleCpuApbBus
from tb.cpu_lib import ReferenceCPU, build_logic_ops_program, ins, OPC_HLT, OPC_LDI, OPC_STA
from tb.protocol_conformance import assert_snapshot_matches_model, run_protocol_conformance_suite


@cocotb.test()
async def apb_program_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.pclk, 10, unit="ns").start())
    apb = SimpleCpuApbBus(dut)
    await apb.reset()

    program = build_logic_ops_program()
    model = ReferenceCPU()
    model.load_program(program)
    model.run(max_cycles=128)

    await apb.load_shadow_program(program)
    await apb.verify_loaded_program(program)
    await apb.begin_execution()
    await apb.run_until_halt(max_cycles=256)
    assert_snapshot_matches_model(await apb.sample_state(), model, "apb_logic_ops")


@cocotb.test()
async def apb_protocol_conformance_suite(dut):
    cocotb.start_soon(Clock(dut.pclk, 10, unit="ns").start())
    apb = SimpleCpuApbBus(dut)
    await run_protocol_conformance_suite(apb, str(dut._name))


@cocotb.test()
async def apb_shadow_fault_injection_requires_reload(dut):
    cocotb.start_soon(Clock(dut.pclk, 10, unit="ns").start())
    apb = SimpleCpuApbBus(dut)
    await apb.reset()

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

    await apb.load_shadow_program(base_program)
    await apb.start_program()

    await RisingEdge(dut.pclk)
    await apb.write(2, patched_program[2])
    assert await apb.read(2) == patched_program[2], "shadow image should update immediately"

    await apb.run_until_halt(max_cycles=128)
    assert_snapshot_matches_model(await apb.sample_state(), model_initial, "apb_shadow_current_run")

    await apb.stop_program()
    await apb.start_program()
    await apb.run_until_halt(max_cycles=128)
    assert_snapshot_matches_model(await apb.sample_state(), model_reloaded, "apb_shadow_after_reload")


@cocotb.test()
async def apb_control_status_readback(dut):
    cocotb.start_soon(Clock(dut.pclk, 10, unit="ns").start())
    apb = SimpleCpuApbBus(dut)
    await apb.reset()

    program = [
        ins(OPC_LDI, 1),
        ins(OPC_STA, 0),
        ins(OPC_HLT, 0),
    ]
    await apb.load_shadow_program(program)
    await apb.write(0x30, 0x01)

    seen_load = False
    seen_run = False
    for _ in range(40):
        control = await apb.read(0x30)
        if (control & 0x2) != 0:
            seen_load = True
        if (control & 0x1) != 0:
            seen_run = True
            break
        await RisingEdge(dut.pclk)

    assert seen_load, "wrapper should expose LOAD state before RUN"
    assert seen_run, "wrapper should expose RUN state after LOAD"

    await apb.run_until_halt(max_cycles=64)
    status = await apb.read(0x10)
    assert ((status >> 4) & 0x1) == 1, "HALTED bit should be set after program completion"
    assert await apb.read(0x11) == 1
    assert await apb.read_dmem(0) == 1


@cocotb.test()
async def apb_setup_phase_requires_penable(dut):
    cocotb.start_soon(Clock(dut.pclk, 10, unit="ns").start())
    apb = SimpleCpuApbBus(dut)
    await apb.reset()

    dut.psel.value = 1
    dut.penable.value = 0
    dut.pwrite.value = 0
    dut.paddr.value = 0x10
    dut.pwdata.value = 0
    await Timer(1, unit="ns")
    assert int(dut.pready.value) == 0, "APB slave must not assert PREADY during setup phase"

    await RisingEdge(dut.pclk)
    dut.penable.value = 1
    await apb.wait_ready()
    _ = int(dut.prdata.value)
    await RisingEdge(dut.pclk)
    dut.psel.value = 0
    dut.penable.value = 0
    dut.paddr.value = 0
    await Timer(1, unit="ns")
