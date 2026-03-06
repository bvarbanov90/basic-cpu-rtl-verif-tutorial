from __future__ import annotations

from dataclasses import dataclass
from typing import List

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from pyuvm import ConfigDB, test, uvm_analysis_port, uvm_component, uvm_driver
from pyuvm import uvm_object, uvm_sequence, uvm_sequence_item, uvm_sequencer
from pyuvm import uvm_test, uvm_tlm_analysis_fifo

from tb.test_simple_cpu import (
    OPC_ADD,
    OPC_HLT,
    OPC_JZ,
    OPC_LDI,
    OPC_STA,
    ReferenceCPU,
    build_branch_stress_program,
    build_random_dataflow_program,
    ins,
)


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


class ProgramItem(uvm_sequence_item):
    def __init__(self, name="program_item", program=None, max_cycles=128):
        super().__init__(name)
        self.program = list(program or [])
        self.max_cycles = int(max_cycles)

    def __str__(self):
        return f"{self.get_name()}(len={len(self.program)}, max_cycles={self.max_cycles})"


class SmokeProgramSequence(uvm_sequence):
    async def body(self):
        program = [
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
        item = ProgramItem("smoke_item", program=program, max_cycles=80)
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

    async def run_until_halt(self, max_cycles=128):
        for cycle in range(max_cycles):
            if int(self.dut.dbg_halted.value):
                return cycle
            await RisingEdge(self.dut.clk)
        raise AssertionError(f"DUT did not halt in {max_cycles} cycles")

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


class SimpleCpuDriver(uvm_driver):
    def build_phase(self):
        self.bfm = ConfigDB().get(self, "", "CPU_BFM")
        self.program_ap = uvm_analysis_port("program_ap", self)

    async def run_phase(self):
        while True:
            item = await self.seq_item_port.get_next_item()
            await self.bfm.reset()
            await self.bfm.load_program(item.program)
            self.program_ap.write(item)
            self.seq_item_port.item_done()


class SimpleCpuMonitor(uvm_component):
    def build_phase(self):
        self.bfm = ConfigDB().get(self, "", "CPU_BFM")
        self.program_fifo = uvm_tlm_analysis_fifo("program_fifo", self)
        self.snapshot_ap = uvm_analysis_port("snapshot_ap", self)

    async def run_phase(self):
        while True:
            item = await self.program_fifo.get()
            await self.bfm.run_until_halt(item.max_cycles)
            snapshot = await self.bfm.sample_snapshot()
            self.snapshot_ap.write(snapshot)


class SimpleCpuScoreboard(uvm_component):
    def build_phase(self):
        self.program_fifo = uvm_tlm_analysis_fifo("program_fifo", self)
        self.snapshot_fifo = uvm_tlm_analysis_fifo("snapshot_fifo", self)
        self.checked = False

    async def run_phase(self):
        item = await self.program_fifo.get()
        snapshot = await self.snapshot_fifo.get()

        model = ReferenceCPU()
        model.load_program(item.program)
        model.run(max_cycles=item.max_cycles)

        assert snapshot.halted == model.halted
        assert snapshot.acc == model.acc
        assert snapshot.pc == model.pc
        assert snapshot.zero == model.zero
        assert snapshot.carry == model.carry
        assert snapshot.neg == model.neg
        assert snapshot.overflow == model.overflow
        assert snapshot.dmem == model.dmem

        self.checked = True


class SimpleCpuAgent(uvm_component):
    def build_phase(self):
        self.sequencer = uvm_sequencer("sequencer", self)
        self.driver = SimpleCpuDriver("driver", self)
        self.monitor = SimpleCpuMonitor("monitor", self)

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.sequencer.seq_item_export)
        self.driver.program_ap.connect(self.monitor.program_fifo.analysis_export)


class SimpleCpuEnv(uvm_component):
    def build_phase(self):
        self.agent = SimpleCpuAgent("agent", self)
        self.scoreboard = SimpleCpuScoreboard("scoreboard", self)

    def connect_phase(self):
        self.agent.driver.program_ap.connect(self.scoreboard.program_fifo.analysis_export)
        self.agent.monitor.snapshot_ap.connect(self.scoreboard.snapshot_fifo.analysis_export)

    async def wait_for_scoreboard(self, timeout_cycles=256):
        for _ in range(timeout_cycles):
            if self.scoreboard.checked:
                return
            await RisingEdge(cocotb.top.clk)
        raise AssertionError("Scoreboard did not complete in time")


@test()
class SimpleCpuUvmSmokeTest(uvm_test):
    def build_phase(self):
        bfm = SimpleCpuBfm(dut=cocotb.top)
        ConfigDB().set(None, "*", "CPU_BFM", bfm)
        self.env = SimpleCpuEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        seq = SmokeProgramSequence("smoke_seq")
        await seq.start(self.env.agent.sequencer)
        await self.env.wait_for_scoreboard()
        self.drop_objection()


@test()
class SimpleCpuUvmRandomizedTest(uvm_test):
    def build_phase(self):
        bfm = SimpleCpuBfm(dut=cocotb.top)
        ConfigDB().set(None, "*", "CPU_BFM", bfm)
        self.env = SimpleCpuEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        seq = RandomProgramSequence("random_seq", seed=20260221)
        await seq.start(self.env.agent.sequencer)
        await self.env.wait_for_scoreboard()
        self.drop_objection()


@test()
class SimpleCpuUvmBranchStressTest(uvm_test):
    def build_phase(self):
        bfm = SimpleCpuBfm(dut=cocotb.top)
        ConfigDB().set(None, "*", "CPU_BFM", bfm)
        self.env = SimpleCpuEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        seq = BranchStressSequence("branch_seq", seed=0xBADC0DE0)
        await seq.start(self.env.agent.sequencer)
        await self.env.wait_for_scoreboard()
        self.drop_objection()
