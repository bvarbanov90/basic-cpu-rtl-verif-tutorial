from __future__ import annotations

from cocotb.triggers import RisingEdge, Timer

from tb.mmio_bus import ADDR_ACC, ADDR_CONTROL, ADDR_PC, ADDR_STATUS, MmioSnapshot


class SimpleCpuApbBus:
    def __init__(self, dut, *, max_wait_cycles: int = 32) -> None:
        self.dut = dut
        self.max_wait_cycles = int(max_wait_cycles)

    async def reset(self) -> None:
        self.dut.presetn.value = 0
        self.dut.psel.value = 0
        self.dut.penable.value = 0
        self.dut.pwrite.value = 0
        self.dut.paddr.value = 0
        self.dut.pwdata.value = 0
        await RisingEdge(self.dut.pclk)
        await RisingEdge(self.dut.pclk)
        await RisingEdge(self.dut.pclk)
        self.dut.presetn.value = 1
        await Timer(1, unit="ns")

    async def wait_ready(self, *, max_cycles: int | None = None) -> None:
        wait_budget = self.max_wait_cycles if max_cycles is None else int(max_cycles)
        for _ in range(wait_budget):
            await Timer(1, unit="ns")
            if int(self.dut.pready.value) == 1:
                return
            await RisingEdge(self.dut.pclk)
        raise AssertionError(f"pready did not assert within {wait_budget} cycles")

    async def write(self, addr: int, value: int) -> None:
        self.dut.psel.value = 1
        self.dut.penable.value = 0
        self.dut.pwrite.value = 1
        self.dut.paddr.value = addr & 0xFF
        self.dut.pwdata.value = value & 0xFF
        await Timer(1, unit="ns")
        await RisingEdge(self.dut.pclk)
        self.dut.penable.value = 1
        await self.wait_ready()
        await RisingEdge(self.dut.pclk)
        self.dut.psel.value = 0
        self.dut.penable.value = 0
        self.dut.pwrite.value = 0
        self.dut.paddr.value = 0
        self.dut.pwdata.value = 0
        await Timer(1, unit="ns")

    async def read(self, addr: int) -> int:
        self.dut.psel.value = 1
        self.dut.penable.value = 0
        self.dut.pwrite.value = 0
        self.dut.paddr.value = addr & 0xFF
        self.dut.pwdata.value = 0
        await Timer(1, unit="ns")
        await RisingEdge(self.dut.pclk)
        self.dut.penable.value = 1
        await self.wait_ready()
        value = int(self.dut.prdata.value)
        await RisingEdge(self.dut.pclk)
        self.dut.psel.value = 0
        self.dut.penable.value = 0
        self.dut.paddr.value = 0
        await Timer(1, unit="ns")
        return value

    async def load_shadow_program(self, program: list[int]) -> None:
        for addr, value in enumerate(program[:16]):
            await self.write(addr, value)

    async def wait_for_control_state(self, *, run: int, load: int, max_cycles: int = 64) -> None:
        expected = ((load & 1) << 1) | (run & 1)
        for _ in range(max_cycles):
            control = await self.read(ADDR_CONTROL)
            if (control & 0x3) == expected:
                return
            await RisingEdge(self.dut.pclk)
        raise AssertionError(f"APB control register never reached load={load} run={run}")

    async def start_program(self) -> None:
        await self.write(ADDR_CONTROL, 0x01)
        await self.wait_for_control_state(run=1, load=0)

    async def stop_program(self) -> None:
        await self.write(ADDR_CONTROL, 0x00)
        await self.wait_for_control_state(run=0, load=0)

    async def run_until_halt(self, max_cycles: int = 256) -> int:
        for cycle in range(max_cycles):
            status = await self.read(ADDR_STATUS)
            if (status >> 4) & 0x1:
                return cycle
            await RisingEdge(self.dut.pclk)
        raise AssertionError("APB DUT did not halt in time")

    async def read_dmem(self, addr: int) -> int:
        return await self.read(0x20 | (addr & 0xF))

    async def sample_state(self) -> MmioSnapshot:
        status = await self.read(ADDR_STATUS)
        dmem = []
        for addr in range(16):
            dmem.append(await self.read_dmem(addr))
        return MmioSnapshot(
            halted=(status >> 4) & 0x1,
            overflow=(status >> 3) & 0x1,
            neg=(status >> 2) & 0x1,
            carry=(status >> 1) & 0x1,
            zero=status & 0x1,
            acc=await self.read(ADDR_ACC),
            pc=await self.read(ADDR_PC) & 0xF,
            dmem=dmem,
        )
