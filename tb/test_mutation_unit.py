from __future__ import annotations

from pathlib import Path

from scripts.mutation_catalog import render_markdown, validate_mutation_definitions
from scripts.run_mutation_campaign import MUTATIONS, apply_mutation

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_mutation_definitions_are_valid() -> None:
    assert validate_mutation_definitions() == []


def test_each_mutation_changes_its_target_file() -> None:
    for mutation in MUTATIONS:
        target_text = (PROJECT_ROOT / mutation.target_file).read_text(encoding="utf-8")
        mutated_text = apply_mutation(target_text, mutation)
        assert mutated_text != target_text, mutation.name


def test_mutation_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "mutation-catalog.md").read_text(encoding="utf-8")
    assert actual == expected
