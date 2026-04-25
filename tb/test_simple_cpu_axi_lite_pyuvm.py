from __future__ import annotations

from dataclasses import dataclass
from typing import List

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from pyuvm import ConfigDB, test, uvm_analysis_port, uvm_component, uvm_driver
from pyuvm import uvm_object, uvm_sequence, uvm_sequence_item, uvm_sequencer
from pyuvm import uvm_test, uvm_tlm_analysis_fifo

from tb.axi_lite_bus import SimpleCpuAxiLiteBus
from tb.cpu_lib import (
    OPC_HLT,
    OPC_LDI,
    OPC_STA,
    ReferenceCPU,
    build_logic_ops_program,
    build_random_dataflow_program,
    ins,
)
from tb.mmio_bus import MmioSnapshot
from tb.protocol_conformance import assert_snapshot_matches_model as assert_protocol_snapshot_matches_model


def get_config(component, key: str, default):
    try:
        return ConfigDB().get(component, "", key)
    except Exception:
        return default


@dataclass
class AxiLiteRunTrace:
    item_name: str
    program: List[int]
    reference_program: List[int]
    max_cycles: int
    snapshot: MmioSnapshot
    seen_load: int
    seen_run: int


class AxiLiteProgramItem(uvm_sequence_item):
    def __init__(
        self,
        name="axi_lite_program_item",
        program=None,
        reference_program=None,
        max_cycles=256,
        verify_shadow_readback=True,
        observe_control_states=False,
    ):
        super().__init__(name)
        self.program = list(program or [])
        self.reference_program = list(reference_program) if reference_program is not None else list(self.program)
        self.max_cycles = int(max_cycles)
        self.verify_shadow_readback = bool(verify_shadow_readback)
        self.observe_control_states = bool(observe_control_states)


class AxiLiteLogicOpsSequence(uvm_sequence):
    async def body(self):
        item = AxiLiteProgramItem(
            "axi_lite_logic_ops_item",
            program=build_logic_ops_program(),
            max_cycles=256,
            verify_shadow_readback=True,
            observe_control_states=False,
        )
        await self.start_item(item)
        await self.finish_item(item)


class AxiLiteControlStatusSequence(uvm_sequence):
    async def body(self):
        program = [
            ins(OPC_LDI, 1),
            ins(OPC_STA, 0),
            ins(OPC_HLT, 0),
        ]
        item = AxiLiteProgramItem(
            "axi_lite_control_status_item",
            program=program,
            max_cycles=128,
            verify_shadow_readback=True,
            observe_control_states=True,
        )
        await self.start_item(item)
        await self.finish_item(item)


class AxiLiteRandomProgramSequence(uvm_sequence):
    def __init__(self, name="axi_lite_random_program_sequence", seed=20260411):
        super().__init__(name)
        self.seed = int(seed)

    async def body(self):
        item = AxiLiteProgramItem(
            "axi_lite_random_item",
            program=build_random_dataflow_program(seed=self.seed, length=12),
            max_cycles=192,
            verify_shadow_readback=False,
            observe_control_states=False,
        )
        await self.start_item(item)
        await self.finish_item(item)


class SimpleCpuAxiLiteBfm(uvm_object):
    def __init__(self, name="simple_cpu_axi_lite_bfm", dut=None):
        super().__init__(name)
        self.dut = dut
        self._clock_started = False
        self.axi_lite = SimpleCpuAxiLiteBus(dut)

    async def ensure_clock(self):
        if self._clock_started:
            return
        cocotb.start_soon(Clock(self.dut.aclk, 10, unit="ns").start())
        self._clock_started = True
        await Timer(1, unit="ns")

    async def reset(self):
        await self.ensure_clock()
        await self.axi_lite.reset()

    async def start_with_optional_state_observation(self, observe_control_states: bool, max_cycles: int) -> tuple[int, int]:
        if not observe_control_states:
            await self.axi_lite.start_program()
            return 0, 1

        await self.axi_lite.write(0x30, 0x01)
        seen_load = 0
        seen_run = 0
        for _ in range(max_cycles):
            control = await self.axi_lite.read(0x30)
            if (control & 0x2) != 0:
                seen_load = 1
            if (control & 0x1) != 0:
                seen_run = 1
                break
            await RisingEdge(self.dut.aclk)
        return seen_load, seen_run

    async def run_item(self, item: AxiLiteProgramItem) -> AxiLiteRunTrace:
        await self.reset()
        await self.axi_lite.load_shadow_program(item.program)

        if item.verify_shadow_readback:
            for addr, value in enumerate(item.program[:16]):
                observed = await self.axi_lite.read(addr)
                assert observed == value, f"{item.get_name()}: shadow[{addr}] got {observed}, expected {value}"

        seen_load, seen_run = await self.start_with_optional_state_observation(
            item.observe_control_states, item.max_cycles
        )
        await self.axi_lite.run_until_halt(max_cycles=item.max_cycles)
        snapshot = await self.axi_lite.sample_state()
        return AxiLiteRunTrace(
            item_name=item.get_name(),
            program=list(item.program),
            reference_program=list(item.reference_program),
            max_cycles=item.max_cycles,
            snapshot=snapshot,
            seen_load=seen_load,
            seen_run=seen_run,
        )


class SimpleCpuAxiLiteDriver(uvm_driver):
    def build_phase(self):
        self.bfm = ConfigDB().get(self, "", "AXI_LITE_CPU_BFM")
        self.trace_ap = uvm_analysis_port("trace_ap", self)

    async def run_phase(self):
        while True:
            item = await self.seq_item_port.get_next_item()
            trace = await self.bfm.run_item(item)
            self.trace_ap.write(trace)
            self.seq_item_port.item_done()


class SimpleCpuAxiLiteScoreboard(uvm_component):
    def build_phase(self):
        self.trace_fifo = uvm_tlm_analysis_fifo("trace_fifo", self)
        self.expected_runs = int(get_config(self, "EXPECTED_RUNS", 1))
        self.checked_runs = 0

    @staticmethod
    def assert_equal(trace: AxiLiteRunTrace, field: str, observed, expected):
        assert observed == expected, f"{trace.item_name}: {field} got {observed}, expected {expected}"

    async def run_phase(self):
        while self.checked_runs < self.expected_runs:
            trace = await self.trace_fifo.get()

            model = ReferenceCPU()
            model.load_program(trace.reference_program)
            model.run(max_cycles=trace.max_cycles)

            self.assert_equal(trace, "HALTED", trace.snapshot.halted, model.halted)
            self.assert_equal(trace, "ACC", trace.snapshot.acc, model.acc)
            self.assert_equal(trace, "PC", trace.snapshot.pc, model.pc)
            self.assert_equal(trace, "ZERO", trace.snapshot.zero, model.zero)
            self.assert_equal(trace, "CARRY", trace.snapshot.carry, model.carry)
            self.assert_equal(trace, "NEG", trace.snapshot.neg, model.neg)
            self.assert_equal(trace, "OVERFLOW", trace.snapshot.overflow, model.overflow)
            self.assert_equal(trace, "DMEM", trace.snapshot.dmem, model.dmem)

            if trace.item_name == "axi_lite_control_status_item":
                self.assert_equal(trace, "LOAD_STATE", trace.seen_load, 1)
                self.assert_equal(trace, "RUN_STATE", trace.seen_run, 1)

            self.checked_runs += 1


class SimpleCpuAxiLiteAgent(uvm_component):
    def build_phase(self):
        self.sequencer = uvm_sequencer("sequencer", self)
        self.driver = SimpleCpuAxiLiteDriver("driver", self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.sequencer.seq_item_export)


class SimpleCpuAxiLiteEnv(uvm_component):
    def build_phase(self):
        self.expected_runs = int(get_config(self, "EXPECTED_RUNS", 1))
        self.agent = SimpleCpuAxiLiteAgent("agent", self)
        self.scoreboard = SimpleCpuAxiLiteScoreboard("scoreboard", self)

    def connect_phase(self):
        self.agent.driver.trace_ap.connect(self.scoreboard.trace_fifo.analysis_export)

    async def wait_for_completion(self, timeout_cycles=1024):
        for _ in range(timeout_cycles):
            if self.scoreboard.checked_runs >= self.expected_runs:
                return
            await RisingEdge(cocotb.top.aclk)
        raise AssertionError("AXI-Lite pyuvm environment did not complete in time")


class SimpleCpuAxiLiteBaseTest(uvm_test):
    expected_runs = 1

    def build_phase(self):
        bfm = SimpleCpuAxiLiteBfm(dut=cocotb.top)
        ConfigDB().set(None, "*", "AXI_LITE_CPU_BFM", bfm)
        ConfigDB().set(None, "*", "EXPECTED_RUNS", self.expected_runs)
        self.bfm = bfm
        self.env = SimpleCpuAxiLiteEnv("env", self)


def assert_snapshot_matches_model(label: str, snapshot: MmioSnapshot, model: ReferenceCPU) -> None:
    assert_protocol_snapshot_matches_model(snapshot, model, label)


@test()
class SimpleCpuAxiLiteUvmSmokeTest(SimpleCpuAxiLiteBaseTest):
    async def run_phase(self):
        self.raise_objection()
        await AxiLiteLogicOpsSequence("axi_lite_logic_ops_seq").start(self.env.agent.sequencer)
        await self.env.wait_for_completion()
        self.drop_objection()


@test()
class SimpleCpuAxiLiteUvmRandomizedTest(SimpleCpuAxiLiteBaseTest):
    async def run_phase(self):
        self.raise_objection()
        await AxiLiteRandomProgramSequence("axi_lite_random_seq", seed=20260411).start(self.env.agent.sequencer)
        await self.env.wait_for_completion(timeout_cycles=4096)
        self.drop_objection()


@test()
class SimpleCpuAxiLiteUvmControlStatusTest(SimpleCpuAxiLiteBaseTest):
    async def run_phase(self):
        self.raise_objection()
        await AxiLiteControlStatusSequence("axi_lite_control_status_seq").start(self.env.agent.sequencer)
        await self.env.wait_for_completion()
        self.drop_objection()


@test()
class SimpleCpuAxiLiteUvmShadowFaultInjectionTest(SimpleCpuAxiLiteBaseTest):
    expected_runs = 0

    async def run_phase(self):
        self.raise_objection()

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

        await self.bfm.reset()
        await self.bfm.axi_lite.load_shadow_program(base_program)
        await self.bfm.axi_lite.start_program()

        await RisingEdge(cocotb.top.aclk)
        await self.bfm.axi_lite.write(2, patched_program[2])
        observed_shadow = await self.bfm.axi_lite.read(2)
        assert observed_shadow == patched_program[2], (
            f"axi_lite_shadow_pyuvm_current_run: shadow[2] got {observed_shadow}, expected {patched_program[2]}"
        )

        await self.bfm.axi_lite.run_until_halt(max_cycles=128)
        first_snapshot = await self.bfm.axi_lite.sample_state()
        assert_snapshot_matches_model("axi_lite_shadow_pyuvm_current_run", first_snapshot, model_initial)

        await self.bfm.axi_lite.stop_program()
        await self.bfm.axi_lite.start_program()
        await self.bfm.axi_lite.run_until_halt(max_cycles=128)
        second_snapshot = await self.bfm.axi_lite.sample_state()
        assert_snapshot_matches_model("axi_lite_shadow_pyuvm_after_reload", second_snapshot, model_reloaded)

        self.drop_objection()


@test()
class SimpleCpuAxiLiteUvmPartialWriteTest(SimpleCpuAxiLiteBaseTest):
    expected_runs = 0

    async def run_phase(self):
        self.raise_objection()

        await self.bfm.reset()
        original = ins(OPC_LDI, 1)
        await self.bfm.axi_lite.write(0, original)
        assert await self.bfm.axi_lite.read(0) == original

        await self.bfm.axi_lite.attempt_partial_write(awvalid=1, wvalid=0, addr=0, value=ins(OPC_LDI, 9))
        assert await self.bfm.axi_lite.read(0) == original, "AW-only write attempt must not change shadow[0]"

        await self.bfm.axi_lite.attempt_partial_write(awvalid=0, wvalid=1, addr=0, value=ins(OPC_LDI, 7))
        assert await self.bfm.axi_lite.read(0) == original, "W-only write attempt must not change shadow[0]"

        self.drop_objection()


