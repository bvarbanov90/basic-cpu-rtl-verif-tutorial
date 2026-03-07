from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import List

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from pyuvm import ConfigDB, test, uvm_analysis_port, uvm_component, uvm_driver
from pyuvm import uvm_object, uvm_sequence, uvm_sequence_item, uvm_sequencer
from pyuvm import uvm_test, uvm_tlm_analysis_fifo

from tb.cpu_lib import (
    ReferenceCPU,
    build_add_carry_program,
    build_branch_not_taken_program,
    build_branch_stress_program,
    build_cmp_negative_program,
    build_illegal_opcode_program,
    build_jump_loop_program,
    build_logic_ops_program,
    build_random_dataflow_program,
    build_shift_overflow_program,
    build_smoke_program,
    build_sub_carry_program,
)
from tb.coverage_utils import CoverageModel, StepObservation


def get_config(component, key: str, default):
    try:
        return ConfigDB().get(component, "", key)
    except Exception:
        return default


@dataclass
class CpuSnapshot:
    halted: int
    acc: int
    pc: int
    zero: int
    carry: int
    neg: int
    overflow: int
    dmem: List[int]


@dataclass
class RunTrace:
    item_name: str
    program: List[int]
    max_cycles: int
    steps: List[StepObservation]
    snapshot: CpuSnapshot


class ProgramItem(uvm_sequence_item):
    def __init__(self, name="program_item", program=None, max_cycles=128):
        super().__init__(name)
        self.program = list(program or [])
        self.max_cycles = int(max_cycles)

    def __str__(self):
        return f"{self.get_name()}(len={len(self.program)}, max_cycles={self.max_cycles})"


class SmokeProgramSequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("smoke_item", program=build_smoke_program(), max_cycles=80)
        await self.start_item(item)
        await self.finish_item(item)


class BranchNotTakenSequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("branch_not_taken_item", program=build_branch_not_taken_program(), max_cycles=64)
        await self.start_item(item)
        await self.finish_item(item)


class JumpLoopSequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("jump_loop_item", program=build_jump_loop_program(), max_cycles=128)
        await self.start_item(item)
        await self.finish_item(item)


class LogicOpsSequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("logic_ops_item", program=build_logic_ops_program(), max_cycles=96)
        await self.start_item(item)
        await self.finish_item(item)


class IllegalOpcodeSequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("illegal_opcode_item", program=build_illegal_opcode_program(), max_cycles=16)
        await self.start_item(item)
        await self.finish_item(item)


class AddCarrySequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("add_carry_item", program=build_add_carry_program(), max_cycles=64)
        await self.start_item(item)
        await self.finish_item(item)


class SubCarrySequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("sub_carry_item", program=build_sub_carry_program(), max_cycles=64)
        await self.start_item(item)
        await self.finish_item(item)


class ShiftOverflowSequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("shift_overflow_item", program=build_shift_overflow_program(), max_cycles=64)
        await self.start_item(item)
        await self.finish_item(item)


class CmpNegativeSequence(uvm_sequence):
    async def body(self):
        item = ProgramItem("cmp_negative_item", program=build_cmp_negative_program(), max_cycles=32)
        await self.start_item(item)
        await self.finish_item(item)


class RandomProgramSequence(uvm_sequence):
    def __init__(self, name="random_program_sequence", seed=20260221):
        super().__init__(name)
        self.seed = int(seed)

    async def body(self):
        program = build_random_dataflow_program(seed=self.seed, length=12)
        item = ProgramItem("random_item", program=program, max_cycles=96)
        await self.start_item(item)
        await self.finish_item(item)


class BranchStressSequence(uvm_sequence):
    def __init__(self, name="branch_stress_sequence", seed=0xBADC0DE0):
        super().__init__(name)
        self.seed = int(seed)

    async def body(self):
        program = build_branch_stress_program(seed=self.seed)
        item = ProgramItem("branch_item", program=program, max_cycles=128)
        await self.start_item(item)
        await self.finish_item(item)


class SimpleCpuBfm(uvm_object):
    def __init__(self, name="simple_cpu_bfm", dut=None):
        super().__init__(name)
        self.dut = dut
        self._clock_started = False

    async def ensure_clock(self):
        if self._clock_started:
            return
        cocotb.start_soon(Clock(self.dut.clk, 10, unit="ns").start())
        self._clock_started = True
        await Timer(1, unit="ns")

    async def reset(self):
        await self.ensure_clock()
        self.dut.rst_n.value = 0
        self.dut.prog_we.value = 0
        self.dut.prog_addr.value = 0
        self.dut.prog_data.value = 0
        self.dut.dbg_mem_addr.value = 0
        for _ in range(3):
            await RisingEdge(self.dut.clk)
        self.dut.rst_n.value = 1

    async def load_program(self, program):
        for addr, value in enumerate(program[:16]):
            self.dut.prog_addr.value = addr
            self.dut.prog_data.value = value
            self.dut.prog_we.value = 1
            await RisingEdge(self.dut.clk)
        self.dut.prog_we.value = 0
        self.dut.prog_addr.value = 0
        self.dut.prog_data.value = 0

    async def read_mem(self, addr):
        self.dut.dbg_mem_addr.value = addr
        await Timer(1, unit="ns")
        return int(self.dut.dbg_mem_data.value)

    async def sample_snapshot(self):
        dmem = []
        for addr in range(16):
            dmem.append(await self.read_mem(addr))
        return CpuSnapshot(
            halted=int(self.dut.dbg_halted.value),
            acc=int(self.dut.dbg_acc.value),
            pc=int(self.dut.dbg_pc.value),
            zero=int(self.dut.dbg_zero.value),
            carry=int(self.dut.dbg_carry.value),
            neg=int(self.dut.dbg_neg.value),
            overflow=int(self.dut.dbg_overflow.value),
            dmem=dmem,
        )

    async def run_program(self, program, max_cycles=128):
        steps: List[StepObservation] = []
        for _ in range(max_cycles):
            if int(self.dut.dbg_halted.value):
                return steps, await self.sample_snapshot()

            pc_before = int(self.dut.dbg_pc.value)
            zero_before = int(self.dut.dbg_zero.value)
            instr = program[pc_before] if 0 <= pc_before < len(program) else 0
            opcode = (instr >> 4) & 0xF
            operand = instr & 0xF

            await RisingEdge(self.dut.clk)

            steps.append(
                StepObservation(
                    opcode=opcode,
                    operand=operand,
                    pc_before=pc_before,
                    pc_after=int(self.dut.dbg_pc.value),
                    zero_before=zero_before,
                    zero_after=int(self.dut.dbg_zero.value),
                    carry_after=int(self.dut.dbg_carry.value),
                    neg_after=int(self.dut.dbg_neg.value),
                    overflow_after=int(self.dut.dbg_overflow.value),
                )
            )

        raise AssertionError(f"DUT did not halt in {max_cycles} cycles")


class SimpleCpuDriver(uvm_driver):
    def build_phase(self):
        self.bfm = ConfigDB().get(self, "", "CPU_BFM")
        self.trace_ap = uvm_analysis_port("trace_ap", self)

    async def run_phase(self):
        while True:
            item = await self.seq_item_port.get_next_item()
            await self.bfm.reset()
            await self.bfm.load_program(item.program)
            steps, snapshot = await self.bfm.run_program(item.program, item.max_cycles)
            self.trace_ap.write(
                RunTrace(
                    item_name=item.get_name(),
                    program=list(item.program),
                    max_cycles=item.max_cycles,
                    steps=steps,
                    snapshot=snapshot,
                )
            )
            self.seq_item_port.item_done()


class SimpleCpuScoreboard(uvm_component):
    def build_phase(self):
        self.trace_fifo = uvm_tlm_analysis_fifo("trace_fifo", self)
        self.expected_runs = int(get_config(self, "EXPECTED_RUNS", 1))
        self.checked_runs = 0

    @staticmethod
    def assert_equal(trace: RunTrace, field: str, observed, expected):
        assert observed == expected, f"{trace.item_name}: {field} got {observed}, expected {expected}"

    async def run_phase(self):
        while self.checked_runs < self.expected_runs:
            trace = await self.trace_fifo.get()

            model = ReferenceCPU()
            model.load_program(trace.program)
            model.run(max_cycles=trace.max_cycles)

            self.assert_equal(trace, "HALTED", trace.snapshot.halted, model.halted)
            self.assert_equal(trace, "ACC", trace.snapshot.acc, model.acc)
            self.assert_equal(trace, "PC", trace.snapshot.pc, model.pc)
            self.assert_equal(trace, "ZERO", trace.snapshot.zero, model.zero)
            self.assert_equal(trace, "CARRY", trace.snapshot.carry, model.carry)
            self.assert_equal(trace, "NEG", trace.snapshot.neg, model.neg)
            self.assert_equal(trace, "OVERFLOW", trace.snapshot.overflow, model.overflow)
            self.assert_equal(trace, "DMEM", trace.snapshot.dmem, model.dmem)

            self.checked_runs += 1


class SimpleCpuCoverageSubscriber(uvm_component):
    def build_phase(self):
        self.trace_fifo = uvm_tlm_analysis_fifo("trace_fifo", self)
        self.expected_runs = int(get_config(self, "EXPECTED_RUNS", 1))
        self.report_path = str(get_config(self, "PYUVM_COVERAGE_REPORT", ""))
        self.coverage = CoverageModel()
        self.runs_seen = 0
        self.completed = False

    async def run_phase(self):
        while self.runs_seen < self.expected_runs:
            trace = await self.trace_fifo.get()
            self.coverage.sample_run(trace.steps)
            self.runs_seen += 1

        if self.report_path:
            self.coverage.write_report(self.report_path)
        self.completed = True


class SimpleCpuAgent(uvm_component):
    def build_phase(self):
        self.sequencer = uvm_sequencer("sequencer", self)
        self.driver = SimpleCpuDriver("driver", self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.sequencer.seq_item_export)


class SimpleCpuEnv(uvm_component):
    def build_phase(self):
        self.expected_runs = int(get_config(self, "EXPECTED_RUNS", 1))
        self.agent = SimpleCpuAgent("agent", self)
        self.scoreboard = SimpleCpuScoreboard("scoreboard", self)
        self.coverage = SimpleCpuCoverageSubscriber("coverage", self)

    def connect_phase(self):
        self.agent.driver.trace_ap.connect(self.scoreboard.trace_fifo.analysis_export)
        self.agent.driver.trace_ap.connect(self.coverage.trace_fifo.analysis_export)

    async def wait_for_completion(self, timeout_cycles=1024):
        for _ in range(timeout_cycles):
            if self.scoreboard.checked_runs >= self.expected_runs and self.coverage.completed:
                return
            await RisingEdge(cocotb.top.clk)
        raise AssertionError("pyuvm environment did not complete in time")


class SimpleCpuUvmBaseTest(uvm_test):
    expected_runs = 1
    coverage_report = ""

    def build_phase(self):
        bfm = SimpleCpuBfm(dut=cocotb.top)
        ConfigDB().set(None, "*", "CPU_BFM", bfm)
        ConfigDB().set(None, "*", "EXPECTED_RUNS", self.expected_runs)
        ConfigDB().set(None, "*", "PYUVM_COVERAGE_REPORT", self.coverage_report)
        self.env = SimpleCpuEnv("env", self)


@test()
class SimpleCpuUvmSmokeTest(SimpleCpuUvmBaseTest):
    async def run_phase(self):
        self.raise_objection()
        await SmokeProgramSequence("smoke_seq").start(self.env.agent.sequencer)
        await self.env.wait_for_completion()
        self.drop_objection()


@test()
class SimpleCpuUvmRandomizedTest(SimpleCpuUvmBaseTest):
    async def run_phase(self):
        self.raise_objection()
        await RandomProgramSequence("random_seq", seed=20260221).start(self.env.agent.sequencer)
        await self.env.wait_for_completion()
        self.drop_objection()


@test()
class SimpleCpuUvmBranchStressTest(SimpleCpuUvmBaseTest):
    async def run_phase(self):
        self.raise_objection()
        await BranchStressSequence("branch_seq", seed=0xBADC0DE0).start(self.env.agent.sequencer)
        await self.env.wait_for_completion()
        self.drop_objection()


@test()
class SimpleCpuUvmCoverageRegressionTest(SimpleCpuUvmBaseTest):
    expected_runs = 11
    coverage_report = "sim_build/pyuvm_coverage.json"

    async def run_phase(self):
        self.raise_objection()
        report_path = Path(self.coverage_report)
        if report_path.exists():
            report_path.unlink()

        sequences = [
            SmokeProgramSequence("smoke_seq"),
            BranchNotTakenSequence("branch_not_taken_seq"),
            JumpLoopSequence("jump_loop_seq"),
            LogicOpsSequence("logic_ops_seq"),
            IllegalOpcodeSequence("illegal_seq"),
            AddCarrySequence("add_carry_seq"),
            SubCarrySequence("sub_carry_seq"),
            ShiftOverflowSequence("shift_overflow_seq"),
            CmpNegativeSequence("cmp_negative_seq"),
            RandomProgramSequence("random_seq_0", seed=20260221),
            BranchStressSequence("branch_seq_0", seed=0xBADC0DE0),
        ]

        for seq in sequences:
            await seq.start(self.env.agent.sequencer)

        await self.env.wait_for_completion(timeout_cycles=4096)

        report = self.env.coverage.coverage.to_report()
        assert report["coverage_pass"] == 1
        assert report["coverage_failures"] == []
        assert report["illegal_opcode_hit"] == 1
        assert report["jz_taken"] > 0
        assert report["jz_not_taken"] > 0
        assert report["opcode_hits"]["0"] == 1
        assert report["opcode_hits"]["14"] == 1
        assert report["opcode_carry_cross"]["2"]["carry0"] > 0
        assert report["opcode_carry_cross"]["2"]["carry1"] > 0
        assert report["opcode_carry_cross"]["3"]["carry0"] > 0
        assert report["opcode_carry_cross"]["3"]["carry1"] > 0
        assert report["opcode_neg_cross"]["3"]["neg1"] > 0
        assert report["opcode_neg_cross"]["14"]["neg1"] > 0
        assert report["opcode_overflow_cross"]["12"]["overflow0"] > 0
        assert report["opcode_overflow_cross"]["12"]["overflow1"] > 0
        assert report["program_runs"] == self.expected_runs
        assert report_path.exists()

        written_report = json.loads(report_path.read_text(encoding="utf-8"))
        assert written_report["coverage_pass"] == report["coverage_pass"]
        assert written_report["program_runs"] == report["program_runs"]

        self.drop_objection()
