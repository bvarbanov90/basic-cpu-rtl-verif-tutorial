from __future__ import annotations

from pathlib import Path

from scripts.requirements_traceability import REQUIREMENTS, render_markdown, validate_requirements

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_requirements_traceability_is_valid() -> None:
    assert validate_requirements() == []


def test_requirements_cover_protocol_and_fault_families() -> None:
    req_ids = {requirement.req_id for requirement in REQUIREMENTS}

    assert {
        "REQ-CORE-ISA",
        "REQ-MMIO",
        "REQ-MMIO-WAIT",
        "REQ-APB",
        "REQ-APB-FAULTS",
        "REQ-WISHBONE",
        "REQ-WISHBONE-FAULTS",
        "REQ-AXI-LITE",
        "REQ-AXI-LITE-FAULTS",
        "REQ-MUTATION",
        "REQ-CI-ARTIFACTS",
    } <= req_ids


def test_each_requirement_has_lane_and_review_artifact() -> None:
    for requirement in REQUIREMENTS:
        assert requirement.lanes, requirement.req_id
        assert requirement.artifacts, requirement.req_id


def test_requirements_traceability_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "requirements-traceability.md").read_text(encoding="utf-8")
    assert actual == expected
