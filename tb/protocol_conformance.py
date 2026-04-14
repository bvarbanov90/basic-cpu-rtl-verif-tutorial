from __future__ import annotations

from dataclasses import dataclass

from tb.cpu_lib import (
    ReferenceCPU,
    build_branch_stress_program,
    build_jump_loop_program,
    build_logic_ops_program,
    build_random_dataflow_program,
    build_smoke_program,
)
from tb.mmio_bus import MmioSnapshot


@dataclass(frozen=True)
class ProtocolConformanceScenario:
    name: str
    program: list[int]
    max_cycles: int
    verify_loaded_program: bool = True


def build_protocol_conformance_scenarios() -> list[ProtocolConformanceScenario]:
    return [
        ProtocolConformanceScenario("smoke", build_smoke_program(), 96),
        ProtocolConformanceScenario("logic_ops", build_logic_ops_program(), 128),
        ProtocolConformanceScenario("jump_loop", build_jump_loop_program(), 128),
        ProtocolConformanceScenario(
            "branch_stress",
            build_branch_stress_program(seed=0xBADC0DE0),
            192,
        ),
        ProtocolConformanceScenario(
            "random_dataflow",
            build_random_dataflow_program(seed=20260221, length=12),
            128,
        ),
    ]


def assert_snapshot_matches_model(snapshot: MmioSnapshot, model: ReferenceCPU, label: str) -> None:
    assert snapshot.halted == model.halted, f"{label}: HALTED mismatch"
    assert snapshot.acc == model.acc, f"{label}: ACC mismatch"
    assert snapshot.pc == model.pc, f"{label}: PC mismatch"
    assert snapshot.zero == model.zero, f"{label}: ZERO mismatch"
    assert snapshot.carry == model.carry, f"{label}: CARRY mismatch"
    assert snapshot.neg == model.neg, f"{label}: NEG mismatch"
    assert snapshot.overflow == model.overflow, f"{label}: OVERFLOW mismatch"
    assert snapshot.dmem == model.dmem, f"{label}: DMEM mismatch"


async def run_protocol_conformance_suite(adapter, protocol_name: str) -> None:
    for scenario in build_protocol_conformance_scenarios():
        model = ReferenceCPU()
        model.load_program(scenario.program)
        model.run(max_cycles=scenario.max_cycles)

        await adapter.reset()
        load_program = getattr(adapter, "load_program", None)
        if callable(load_program):
            await load_program(scenario.program)
        else:
            load_shadow_program = getattr(adapter, "load_shadow_program", None)
            if callable(load_shadow_program):
                await load_shadow_program(scenario.program)
            else:
                raise AttributeError(f"{type(adapter).__name__} is missing load_program()/load_shadow_program()")

        verify_loaded_program = getattr(adapter, "verify_loaded_program", None)
        if scenario.verify_loaded_program and callable(verify_loaded_program):
            await verify_loaded_program(scenario.program)

        begin_execution = getattr(adapter, "begin_execution", None)
        if callable(begin_execution):
            await begin_execution()

        await adapter.run_until_halt(max_cycles=scenario.max_cycles)
        snapshot = await adapter.sample_state()
        assert_snapshot_matches_model(snapshot, model, f"{protocol_name}:{scenario.name}")
