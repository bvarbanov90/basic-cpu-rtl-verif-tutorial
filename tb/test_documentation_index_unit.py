from __future__ import annotations

from pathlib import Path

from scripts.documentation_index import (
    DOCUMENTATION,
    render_markdown,
    tracked_markdown_docs,
    validate_documentation_index,
)

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_documentation_index_is_valid() -> None:
    assert validate_documentation_index() == []


def test_documentation_index_covers_tracked_markdown() -> None:
    indexed = {entry.path for entry in DOCUMENTATION if entry.path.endswith(".md")}
    assert set(tracked_markdown_docs()) <= indexed


def test_generated_docs_have_generators_and_freshness_checks() -> None:
    generated = [entry for entry in DOCUMENTATION if entry.kind == "generated"]

    assert len(generated) >= 10
    assert all(entry.generator.startswith("generate-") for entry in generated)
    assert all(entry.check == "scripts/check-python-model.*" for entry in generated)


def test_documentation_index_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "documentation-index.md").read_text(encoding="utf-8")
    assert actual == expected
