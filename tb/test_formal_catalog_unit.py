from __future__ import annotations

from pathlib import Path

from scripts.formal_catalog import formal_targets, render_markdown, validate_formal_targets

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_formal_targets_are_valid() -> None:
    assert validate_formal_targets() == []


def test_formal_catalog_covers_expected_target_mix() -> None:
    targets = formal_targets()
    kinds = {target.kind for target in targets}
    modes = {target.mode for target in targets}

    assert len(targets) == 16
    assert kinds == {"prove", "fault-prove", "cover"}
    assert modes == {"bmc", "cover"}
    assert sum(1 for target in targets if target.kind == "cover") == 6
    assert sum(1 for target in targets if target.kind == "fault-prove") == 4


def test_formal_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "formal-targets.md").read_text(encoding="utf-8")
    assert actual == expected
