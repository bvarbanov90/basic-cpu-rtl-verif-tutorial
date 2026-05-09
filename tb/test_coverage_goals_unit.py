from __future__ import annotations

from pathlib import Path

from scripts.coverage_goals import (
    SUITES,
    goals_for_suite,
    parse_sv_coverage_goals,
    python_coverage_goals,
    render_markdown,
    validate_coverage_goals,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_coverage_goal_catalog_is_valid() -> None:
    assert validate_coverage_goals() == []


def test_coverage_goal_catalog_covers_native_report_families() -> None:
    suite_ids = {suite.suite_id for suite in SUITES}

    assert {
        "core",
        "pyuvm-core",
        "mmio",
        "mmio-wait",
        "apb",
        "apb-fault",
        "wishbone",
        "wishbone-fault",
        "axi-lite",
        "axi-lite-fault",
    } <= suite_ids


def test_core_sv_goals_match_python_coverage_model() -> None:
    sv_goals = parse_sv_coverage_goals("tb/simple_cpu_tb.sv")

    assert sv_goals == python_coverage_goals()


def test_each_suite_has_artifact_and_multiple_goals() -> None:
    for suite in SUITES:
        goals = goals_for_suite(suite)
        assert suite.artifact.endswith(".json")
        assert suite.show_helper.startswith("show-")
        assert len(goals) >= 5


def test_coverage_goals_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "coverage-goals.md").read_text(encoding="utf-8")
    assert actual == expected
