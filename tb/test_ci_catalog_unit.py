from __future__ import annotations

from pathlib import Path

from scripts.ci_catalog import parse_workflow, render_markdown, validate_workflow

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_ci_workflow_catalog_is_valid() -> None:
    assert validate_workflow() == []


def test_ci_workflow_has_expected_job_shape() -> None:
    workflow = parse_workflow()
    jobs = {job.name: job for job in workflow.jobs}

    assert workflow.name == "CI"
    assert workflow.oss_cad_suite_release_tag
    assert workflow.concurrency_group == "${{ github.workflow }}-${{ github.ref }}"
    assert workflow.cancel_in_progress == "true"
    assert {
        "python-model",
        "native-sim",
        "lint",
        "formal",
        "cocotb-verilator",
        "equivalence",
        "pyuvm",
        "mutations",
        "summary",
    } <= set(jobs)
    assert "scripts/check-python-model.sh" in jobs["python-model"].scripts
    assert "scripts/run-formal.sh" in jobs["formal"].scripts
    assert "scripts/run-mutations.sh" in jobs["mutations"].scripts
    assert jobs["summary"].needs == tuple(name for name in jobs if name != "summary")


def test_ci_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "ci-catalog.md").read_text(encoding="utf-8")
    assert actual == expected
