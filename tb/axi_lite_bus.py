from __future__ import annotations

from cocotb.triggers import RisingEdge, Timer

from tb.mmio_bus import ADDR_ACC, ADDR_CONTROL, ADDR_PC, ADDR_STATUS, MmioSnapshot


class SimpleCpuAxiLiteBus:
    """Small AXI-Lite-style bus helper for the tutorial wrapper.

    The RTL intentionally implements a restricted subset: write address and
    write data must be presented together, and only one read/write response may
    be outstanding. Keeping that contract explicit makes the tests useful as a
    protocol-adapter tutorial without pulling in a full AXI VIP dependency.
    """

    def __init__(self, dut, *, max_wait_cycles: int = 32) -> None:
        self.dut = dut
        self.max_wait_cycles = int(max_wait_cycles)

    async def reset(self) -> None:
        self.dut.aresetn.value = 0
        self.dut.axi_awvalid.value = 0
        self.dut.axi_awaddr.value = 0
        self.dut.axi_wvalid.value = 0
        self.dut.axi_wdata.value = 0
        self.dut.axi_bready.value = 0
        self.dut.axi_arvalid.value = 0
        self.dut.axi_araddr.value = 0
        self.dut.axi_rready.value = 0
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        await RisingEdge(self.dut.aclk)
        self.dut.aresetn.value = 1
        await Timer(1, unit="ns")

    async def wait_write_accept(self, *, max_cycles: int | None = None) -> None:
        wait_budget = self.max_wait_cycles if max_cycles is None else int(max_cycles)
        for _ in range(wait_budget):
            await Timer(1, unit="ns")
            if int(self.dut.axi_awready.value) == 1 and int(self.dut.axi_wready.value) == 1:
                return
            await RisingEdge(self.dut.aclk)
        raise AssertionError(f"AXI-Lite write accept did not assert within {wait_budget} cycles")

    async def wait_write_response(self, *, max_cycles: int | None = None) -> None:
        wait_budget = self.max_wait_cycles if max_cycles is None else int(max_cycles)
        for _ in range(wait_budget):
            await Timer(1, unit="ns")
            if int(self.dut.axi_bvalid.value) == 1:
                assert int(self.dut.axi_bresp.value) == 0, "AXI-Lite write response must be OKAY"
                return
            await RisingEdge(self.dut.aclk)
        raise AssertionError(f"AXI-Lite BVALID did not assert within {wait_budget} cycles")

    async def wait_read_accept(self, *, max_cycles: int | None = None) -> None:
        wait_budget = self.max_wait_cycles if max_cycles is None else int(max_cycles)
        for _ in range(wait_budget):
            await Timer(1, unit="ns")
            if int(self.dut.axi_arready.value) == 1:
                return
            await RisingEdge(self.dut.aclk)
        raise AssertionError(f"AXI-Lite ARREADY did not assert within {wait_budget} cycles")

    async def wait_read_response(self, *, max_cycles: int | None = None) -> int:
        wait_budget = self.max_wait_cycles if max_cycles is None else int(max_cycles)
        for _ in range(wait_budget):
            await Timer(1, unit="ns")
            if int(self.dut.axi_rvalid.value) == 1:
                assert int(self.dut.axi_rresp.value) == 0, "AXI-Lite read response must be OKAY"
                return int(self.dut.axi_rdata.value)
            await RisingEdge(self.dut.aclk)
        raise AssertionError(f"AXI-Lite RVALID did not assert within {wait_budget} cycles")

    async def write(self, addr: int, value: int) -> None:
        self.dut.axi_awvalid.value = 1
        self.dut.axi_awaddr.value = addr & 0xFF
        self.dut.axi_wvalid.value = 1
        self.dut.axi_wdata.value = value & 0xFF
        self.dut.axi_bready.value = 0
        await self.wait_write_accept()
        await RisingEdge(self.dut.aclk)
        self.dut.axi_awvalid.value = 0
        self.dut.axi_awaddr.value = 0
        self.dut.axi_wvalid.value = 0
        self.dut.axi_wdata.value = 0

        self.dut.axi_bready.value = 1
        await self.wait_write_response()
        await RisingEdge(self.dut.aclk)
        self.dut.axi_bready.value = 0
        await Timer(1, unit="ns")

    async def read(self, addr: int) -> int:
        self.dut.axi_arvalid.value = 1
        self.dut.axi_araddr.value = addr & 0xFF
        self.dut.axi_rready.value = 0
        await self.wait_read_accept()
        await RisingEdge(self.dut.aclk)
        self.dut.axi_arvalid.value = 0
        self.dut.axi_araddr.value = 0

        self.dut.axi_rready.value = 1
        value = await self.wait_read_response()
        await RisingEdge(self.dut.aclk)
        self.dut.axi_rready.value = 0
        await Timer(1, unit="ns")
        return value

    async def attempt_partial_write(self, *, awvalid: int, wvalid: int, addr: int, value: int) -> None:
        self.dut.axi_awvalid.value = awvalid & 0x1
        self.dut.axi_awaddr.value = addr & 0xFF
        self.dut.axi_wvalid.value = wvalid & 0x1
        self.dut.axi_wdata.value = value & 0xFF
        self.dut.axi_bready.value = 1
        await Timer(1, unit="ns")
        assert int(self.dut.axi_awready.value) == 0, "partial AXI-Lite write must keep AWREADY low"
        assert int(self.dut.axi_wready.value) == 0, "partial AXI-Lite write must keep WREADY low"
        await RisingEdge(self.dut.aclk)
        await Timer(1, unit="ns")
        assert int(self.dut.axi_bvalid.value) == 0, "partial AXI-Lite write must not create BVALID"
        self.dut.axi_awvalid.value = 0
        self.dut.axi_awaddr.value = 0
        self.dut.axi_wvalid.value = 0
        self.dut.axi_wdata.value = 0
        self.dut.axi_bready.value = 0
        await Timer(1, unit="ns")

    async def load_shadow_program(self, program: list[int]) -> None:
        for addr, value in enumerate(program[:16]):
            await self.write(addr, value)

    async def load_program(self, program: list[int]) -> None:
        await self.load_shadow_program(program)

    async def verify_loaded_program(self, program: list[int]) -> None:
        for addr, value in enumerate(program[:16]):
            observed = await self.read(addr)
            assert observed == (value & 0xFF), f"shadow[{addr}] got {observed}, expected {value & 0xFF}"

    async def wait_for_control_state(self, *, run: int, load: int, max_cycles: int = 64) -> None:
        expected = ((load & 1) << 1) | (run & 1)
        for _ in range(max_cycles):
            control = await self.read(ADDR_CONTROL)
            if (control & 0x3) == expected:
                return
            await RisingEdge(self.dut.aclk)
        raise AssertionError(f"AXI-Lite control register never reached load={load} run={run}")

    async def start_program(self) -> None:
        await self.write(ADDR_CONTROL, 0x01)
        await self.wait_for_control_state(run=1, load=0)

    async def begin_execution(self) -> None:
        await self.start_program()

    async def stop_program(self) -> None:
        await self.write(ADDR_CONTROL, 0x00)
        await self.wait_for_control_state(run=0, load=0)

    async def run_until_halt(self, max_cycles: int = 256) -> int:
        for cycle in range(max_cycles):
            status = await self.read(ADDR_STATUS)
            if (status >> 4) & 0x1:
                return cycle
            await RisingEdge(self.dut.aclk)
        raise AssertionError("AXI-Lite DUT did not halt in time")

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
