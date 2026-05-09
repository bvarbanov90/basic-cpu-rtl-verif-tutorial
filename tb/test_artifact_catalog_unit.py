from __future__ import annotations

from pathlib import Path

from scripts.artifact_catalog import artifact_entries, render_markdown, validate_artifact_catalog

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_artifact_catalog_is_valid() -> None:
    assert validate_artifact_catalog() == []


def test_artifact_catalog_covers_major_outputs() -> None:
    entries = {entry.path: entry for entry in artifact_entries()}

    assert "sim_build/coverage.json" in entries
    assert "sim_build/verilator_results.xml" in entries
    assert "sim_build/mutations" in entries
    assert "formal/simple_cpu" in entries
    assert entries["sim_build/coverage.json"].show_helper == "show-coverage"
    assert entries["sim_build/mutations"].show_helper == "show-mutations"
    assert entries["formal/simple_cpu"].show_helper == "show-formal-status"


def test_all_sim_build_entries_have_ci_upload_coverage() -> None:
    for entry in artifact_entries():
        if entry.path.startswith("sim_build/"):
            assert entry.ci_artifact, entry.path


def test_artifact_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "artifact-catalog.md").read_text(encoding="utf-8")
    assert actual == expected
