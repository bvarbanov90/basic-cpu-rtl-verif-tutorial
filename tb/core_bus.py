from __future__ import annotations

from cocotb.triggers import ClockCycles, RisingEdge, Timer

from tb.mmio_bus import MmioSnapshot


class SimpleCpuCoreBus:
    def __init__(self, dut) -> None:
        self.dut = dut

    async def reset(self) -> None:
        self.dut.rst_n.value = 0
        self.dut.prog_we.value = 0
        self.dut.prog_addr.value = 0
        self.dut.prog_data.value = 0
        self.dut.dbg_mem_addr.value = 0
        await ClockCycles(self.dut.clk, 3)
        self.dut.rst_n.value = 1
        await Timer(1, unit="ns")

    async def load_program(self, program) -> None:
        for addr, value in enumerate(program[:16]):
            self.dut.prog_addr.value = addr
            self.dut.prog_data.value = value & 0xFF
            self.dut.prog_we.value = 1
            await RisingEdge(self.dut.clk)
            await Timer(1, unit="ns")

        self.dut.prog_we.value = 0
        self.dut.prog_addr.value = 0
        self.dut.prog_data.value = 0

    async def begin_execution(self) -> None:
        await Timer(1, unit="ns")

    async def run_until_halt(self, max_cycles: int = 128) -> int:
        for cycle in range(max_cycles):
            if int(self.dut.dbg_halted.value):
                return cycle
            await RisingEdge(self.dut.clk)
        raise AssertionError("Direct CPU DUT did not halt in time")

    async def read_dmem(self, addr: int) -> int:
        self.dut.dbg_mem_addr.value = addr & 0xF
        await Timer(1, unit="ns")
        return int(self.dut.dbg_mem_data.value)

    async def sample_state(self) -> MmioSnapshot:
        dmem = []
        for addr in range(16):
            dmem.append(await self.read_dmem(addr))
        return MmioSnapshot(
            halted=int(self.dut.dbg_halted.value),
            overflow=int(self.dut.dbg_overflow.value),
            neg=int(self.dut.dbg_neg.value),
            carry=int(self.dut.dbg_carry.value),
            zero=int(self.dut.dbg_zero.value),
            acc=int(self.dut.dbg_acc.value),
            pc=int(self.dut.dbg_pc.value),
            dmem=dmem,
        )

    async def program_word(self, addr: int, value: int) -> None:
        self.dut.prog_addr.value = addr & 0xF
        self.dut.prog_data.value = value & 0xFF
        self.dut.prog_we.value = 1
        await RisingEdge(self.dut.clk)
        await Timer(1, unit="ns")
        self.dut.prog_we.value = 0
        self.dut.prog_addr.value = 0
        self.dut.prog_data.value = 0

    def start_program_word(self, addr: int, value: int) -> None:
        self.dut.prog_addr.value = addr & 0xF
        self.dut.prog_data.value = value & 0xFF
        self.dut.prog_we.value = 1

    async def stop_program_word(self) -> None:
        await Timer(1, unit="ns")
        self.dut.prog_we.value = 0
        self.dut.prog_addr.value = 0
        self.dut.prog_data.value = 0
