from __future__ import annotations

from pathlib import Path

from scripts.reference_regression_catalog import (
    case_summaries,
    combined_coverage_report,
    regression_cases,
    render_markdown,
    validate_reference_regression_catalog,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_reference_regression_catalog_is_valid() -> None:
    assert validate_reference_regression_catalog() == []


def test_reference_regression_cases_cover_required_kinds() -> None:
    kinds = {case.kind for case in regression_cases()}

    assert {"directed", "negative", "random-dataflow", "random-branch"} <= kinds


def test_reference_regression_combined_coverage_closes() -> None:
    report = combined_coverage_report()

    assert report["coverage_pass"] == 1
    assert report["opcode_hit_bitmap"] == "111111111111111"
    assert report["illegal_opcode_hit"] == 1
    assert report["jz_taken"] > 0
    assert report["jz_not_taken"] > 0


def test_reference_regression_cases_halt() -> None:
    for summary in case_summaries():
        assert summary.cycles > 0, summary.name
        assert summary.final["halted"] == 1, summary.name


def test_reference_regression_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "reference-regression.md").read_text(encoding="utf-8")
    assert actual == expected
