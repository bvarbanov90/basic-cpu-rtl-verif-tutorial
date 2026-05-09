from __future__ import annotations

from pathlib import Path

from scripts.protocol_catalog import (
    PROTOCOL_TESTS,
    render_markdown,
    scenario_summaries,
    validate_protocol_catalog,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_protocol_catalog_is_valid() -> None:
    assert validate_protocol_catalog() == []


def test_protocol_catalog_has_expected_scenarios() -> None:
    names = {scenario.name for scenario in scenario_summaries()}

    assert {"smoke", "logic_ops", "jump_loop", "branch_stress", "random_dataflow"} <= names
    assert all(scenario.halted for scenario in scenario_summaries())


def test_protocol_catalog_covers_all_adapter_tests() -> None:
    assert {"direct-core", "mmio", "apb", "wishbone", "axi-lite"} <= set(PROTOCOL_TESTS)


def test_protocol_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "protocol-conformance.md").read_text(encoding="utf-8")
    assert actual == expected
