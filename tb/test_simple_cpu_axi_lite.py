from __future__ import annotations

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from tb.axi_lite_bus import SimpleCpuAxiLiteBus
from tb.cpu_lib import ReferenceCPU, build_logic_ops_program, ins, OPC_HLT, OPC_LDI, OPC_STA
from tb.protocol_conformance import assert_snapshot_matches_model, run_protocol_conformance_suite


@cocotb.test()
async def axi_lite_program_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    axi_lite = SimpleCpuAxiLiteBus(dut)
    await axi_lite.reset()

    program = build_logic_ops_program()
    model = ReferenceCPU()
    model.load_program(program)
    model.run(max_cycles=128)

    await axi_lite.load_shadow_program(program)
    await axi_lite.verify_loaded_program(program)
    await axi_lite.begin_execution()
    await axi_lite.run_until_halt(max_cycles=256)
    assert_snapshot_matches_model(await axi_lite.sample_state(), model, "axi_lite_logic_ops")


@cocotb.test()
async def axi_lite_protocol_conformance_suite(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    axi_lite = SimpleCpuAxiLiteBus(dut)
    await run_protocol_conformance_suite(axi_lite, str(dut._name))


@cocotb.test()
async def axi_lite_partial_write_channels_are_ignored(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    axi_lite = SimpleCpuAxiLiteBus(dut)
    await axi_lite.reset()

    await axi_lite.write(0, ins(OPC_LDI, 1))
    assert await axi_lite.read(0) == ins(OPC_LDI, 1)

    await axi_lite.attempt_partial_write(awvalid=1, wvalid=0, addr=0, value=ins(OPC_LDI, 9))
    assert await axi_lite.read(0) == ins(OPC_LDI, 1), "AW-only attempt must not update shadow[0]"

    await axi_lite.attempt_partial_write(awvalid=0, wvalid=1, addr=0, value=ins(OPC_LDI, 7))
    assert await axi_lite.read(0) == ins(OPC_LDI, 1), "W-only attempt must not update shadow[0]"


@cocotb.test()
async def axi_lite_shadow_fault_injection_requires_reload(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    axi_lite = SimpleCpuAxiLiteBus(dut)
    await axi_lite.reset()

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

    await axi_lite.load_shadow_program(base_program)
    await axi_lite.start_program()

    await RisingEdge(dut.aclk)
    await axi_lite.write(2, patched_program[2])
    assert await axi_lite.read(2) == patched_program[2], "shadow image should update immediately"

    await axi_lite.run_until_halt(max_cycles=128)
    assert_snapshot_matches_model(await axi_lite.sample_state(), model_initial, "axi_lite_shadow_current_run")

    await axi_lite.stop_program()
    await axi_lite.start_program()
    await axi_lite.run_until_halt(max_cycles=128)
    assert_snapshot_matches_model(await axi_lite.sample_state(), model_reloaded, "axi_lite_shadow_after_reload")


@cocotb.test()
async def axi_lite_control_status_readback(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    axi_lite = SimpleCpuAxiLiteBus(dut)
    await axi_lite.reset()

    program = [
        ins(OPC_LDI, 1),
        ins(OPC_STA, 0),
        ins(OPC_HLT, 0),
    ]
    await axi_lite.load_shadow_program(program)
    await axi_lite.write(0x30, 0x01)

    seen_load = False
    seen_run = False
    for _ in range(40):
        control = await axi_lite.read(0x30)
        if (control & 0x2) != 0:
            seen_load = True
        if (control & 0x1) != 0:
            seen_run = True
            break
        await RisingEdge(dut.aclk)

    assert seen_load, "wrapper should expose LOAD state before RUN"
    assert seen_run, "wrapper should expose RUN state after LOAD"

    await axi_lite.run_until_halt(max_cycles=64)
    status = await axi_lite.read(0x10)
    assert ((status >> 4) & 0x1) == 1, "HALTED bit should be set after program completion"
    assert await axi_lite.read(0x11) == 1
    assert await axi_lite.read_dmem(0) == 1


@cocotb.test()
async def axi_lite_response_holds_until_ready(dut):
    cocotb.start_soon(Clock(dut.aclk, 10, unit="ns").start())
    axi_lite = SimpleCpuAxiLiteBus(dut)
    await axi_lite.reset()

    dut.axi_awvalid.value = 1
    dut.axi_awaddr.value = 0
    dut.axi_wvalid.value = 1
    dut.axi_wdata.value = ins(OPC_LDI, 3)
    dut.axi_bready.value = 0
    await axi_lite.wait_write_accept()
    await RisingEdge(dut.aclk)
    dut.axi_awvalid.value = 0
    dut.axi_wvalid.value = 0
    await Timer(1, unit="ns")

    assert int(dut.axi_bvalid.value) == 1, "BVALID should assert after accepted write"
    await RisingEdge(dut.aclk)
    await Timer(1, unit="ns")
    assert int(dut.axi_bvalid.value) == 1, "BVALID should hold while BREADY is low"
    dut.axi_bready.value = 1
    await RisingEdge(dut.aclk)
    dut.axi_bready.value = 0
    await Timer(1, unit="ns")
    assert int(dut.axi_bvalid.value) == 0, "BVALID should clear after BREADY"
