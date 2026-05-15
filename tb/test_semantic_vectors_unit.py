from __future__ import annotations

from pathlib import Path

from scripts.semantic_vectors import (
    render_markdown,
    semantic_vectors,
    validate_semantic_vectors,
    vector_results,
)
from tb.cpu_lib import OPCODE_NAMES, decode_instruction

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_semantic_vectors_are_valid() -> None:
    assert validate_semantic_vectors() == []


def test_semantic_vectors_cover_all_opcodes_and_illegal_path() -> None:
    covered = {decode_instruction(vector.instruction)[0] for vector in semantic_vectors()}

    assert set(OPCODE_NAMES) <= covered
    assert 0xF in covered


def test_semantic_vectors_all_pass() -> None:
    assert all(result.passed for result in vector_results())


def test_semantic_vectors_include_flag_edge_cases() -> None:
    names = {vector.name for vector in semantic_vectors()}

    assert "add_signed_overflow" in names
    assert "add_unsigned_carry" in names
    assert "sub_borrow_negative" in names
    assert "cmp_signed_overflow" in names


def test_semantic_vector_catalog_matches_tracked_doc() -> None:
    expected = render_markdown()
    actual = (PROJECT_ROOT / "docs" / "semantic-vectors.md").read_text(encoding="utf-8")
    assert actual == expected
