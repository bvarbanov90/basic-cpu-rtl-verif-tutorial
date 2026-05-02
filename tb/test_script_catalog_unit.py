from __future__ import annotations

from pathlib import Path

from scripts.script_catalog import render_markdown, script_entrypoints, validate_script_entrypoints

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_script_entrypoints_are_valid() -> None:
    assert validate_script_entrypoints() == []


def test_script_catalog_has_expected_cross_platform_shape() -> None:
    entries = script_entrypoints()
    names = {entry.name for entry in entries}

    assert len(entries) >= 50
    assert {"run", "check-python-model", "run-formal", "run-mutations", "generate-script-catalog"} <= names
    assert all(entry.top_windows.startswith("scripts/") for entry in entries)
    assert all(entry.top_linux.startswith("scripts/") for entry in entries)
    assert all(entry.windows_impl.startswith("scripts/windows/") for entry in entries)
    assert all(entry.linux_impl.startswith("scripts/linux/") for entry in entries)


def test_script_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "script-catalog.md").read_text(encoding="utf-8")
    assert actual == expected
