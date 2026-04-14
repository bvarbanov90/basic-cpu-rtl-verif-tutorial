from __future__ import annotations

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

from tb.wishbone_bus import SimpleCpuWishboneBus
from tb.cpu_lib import ReferenceCPU, build_logic_ops_program, ins, OPC_HLT, OPC_LDI, OPC_STA
from tb.protocol_conformance import assert_snapshot_matches_model, run_protocol_conformance_suite


@cocotb.test()
async def wishbone_program_matches_reference_model(dut):
    cocotb.start_soon(Clock(dut.wb_clk_i, 10, unit="ns").start())
    wishbone = SimpleCpuWishboneBus(dut)
    await wishbone.reset()

    program = build_logic_ops_program()
    model = ReferenceCPU()
    model.load_program(program)
    model.run(max_cycles=128)

    await wishbone.load_shadow_program(program)
    await wishbone.verify_loaded_program(program)
    await wishbone.begin_execution()
    await wishbone.run_until_halt(max_cycles=256)
    assert_snapshot_matches_model(await wishbone.sample_state(), model, "wishbone_logic_ops")


@cocotb.test()
async def wishbone_protocol_conformance_suite(dut):
    cocotb.start_soon(Clock(dut.wb_clk_i, 10, unit="ns").start())
    wishbone = SimpleCpuWishboneBus(dut)
    await run_protocol_conformance_suite(wishbone, str(dut._name))


@cocotb.test()
async def wishbone_shadow_fault_injection_requires_reload(dut):
    cocotb.start_soon(Clock(dut.wb_clk_i, 10, unit="ns").start())
    wishbone = SimpleCpuWishboneBus(dut)
    await wishbone.reset()

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

    await wishbone.load_shadow_program(base_program)
    await wishbone.start_program()

    await RisingEdge(dut.wb_clk_i)
    await wishbone.write(2, patched_program[2])
    assert await wishbone.read(2) == patched_program[2], "shadow image should update immediately"

    await wishbone.run_until_halt(max_cycles=128)
    assert_snapshot_matches_model(await wishbone.sample_state(), model_initial, "wishbone_shadow_current_run")

    await wishbone.stop_program()
    await wishbone.start_program()
    await wishbone.run_until_halt(max_cycles=128)
    assert_snapshot_matches_model(await wishbone.sample_state(), model_reloaded, "wishbone_shadow_after_reload")


@cocotb.test()
async def wishbone_control_status_readback(dut):
    cocotb.start_soon(Clock(dut.wb_clk_i, 10, unit="ns").start())
    wishbone = SimpleCpuWishboneBus(dut)
    await wishbone.reset()

    program = [
        ins(OPC_LDI, 1),
        ins(OPC_STA, 0),
        ins(OPC_HLT, 0),
    ]
    await wishbone.load_shadow_program(program)
    await wishbone.write(0x30, 0x01)

    seen_load = False
    seen_run = False
    for _ in range(40):
        control = await wishbone.read(0x30)
        if (control & 0x2) != 0:
            seen_load = True
        if (control & 0x1) != 0:
            seen_run = True
            break
        await RisingEdge(dut.wb_clk_i)

    assert seen_load, "wrapper should expose LOAD state before RUN"
    assert seen_run, "wrapper should expose RUN state after LOAD"

    await wishbone.run_until_halt(max_cycles=64)
    status = await wishbone.read(0x10)
    assert ((status >> 4) & 0x1) == 1, "HALTED bit should be set after program completion"
    assert await wishbone.read(0x11) == 1
    assert await wishbone.read_dmem(0) == 1


@cocotb.test()
async def wishbone_cycle_without_strobe_keeps_ack_low(dut):
    cocotb.start_soon(Clock(dut.wb_clk_i, 10, unit="ns").start())
    wishbone = SimpleCpuWishboneBus(dut)
    await wishbone.reset()

    dut.wb_cyc_i.value = 1
    dut.wb_stb_i.value = 0
    dut.wb_we_i.value = 0
    dut.wb_adr_i.value = 0x10
    dut.wb_dat_i.value = 0
    await Timer(1, unit="ns")
    assert int(dut.wb_ack_o.value) == 0, "Wishbone slave must not assert wb_ack_o without stb"

    await RisingEdge(dut.wb_clk_i)
    dut.wb_stb_i.value = 1
    await wishbone.wait_ready()
    _ = int(dut.wb_dat_o.value)
    await RisingEdge(dut.wb_clk_i)
    dut.wb_cyc_i.value = 0
    dut.wb_stb_i.value = 0
    dut.wb_adr_i.value = 0
    await Timer(1, unit="ns")

