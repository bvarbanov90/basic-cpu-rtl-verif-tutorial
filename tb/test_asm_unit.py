from __future__ import annotations

import json
from pathlib import Path

import pytest

from scripts.asm import MEM_SIZE, assemble, parse_source
from scripts.asm_corpus_report import render_markdown
from scripts.check_asm_corpus import validate_manifest

PROJECT_ROOT = Path(__file__).resolve().parents[1]


def assemble_text(text: str) -> list[int]:
    stmts, labels = parse_source(text)
    return assemble(stmts, labels)


def test_assembler_supports_labels_org_and_raw_bytes() -> None:
    mem = assemble_text(
        """
        JMP start
        .byte 0xF0
        .org 8
start:  LDI #5
        STA 0
        HLT
        """
    )

    assert mem[0] == 0x68
    assert mem[1] == 0xF0
    assert mem[8:11] == [0x15, 0x40, 0x80]
    assert len(mem) == MEM_SIZE


@pytest.mark.parametrize(
    ("source", "message"),
    [
        ("label: NOP\nlabel: HLT\n", "duplicate label"),
        ("LDI\n", "requires one operand"),
        ("SHL 1\n", "takes no operand"),
        ("LDI 16\n", "operand out of range"),
        (".org 16\n", ".org out of range"),
        ("BOGUS\n", "unknown instruction"),
        ("\n".join("NOP" for _ in range(MEM_SIZE + 1)), "program exceeds"),
    ],
)
def test_assembler_rejects_bad_sources(source: str, message: str) -> None:
    with pytest.raises(ValueError, match=message):
        assemble_text(source)


def test_manifest_lists_every_program_source_once() -> None:
    manifest_path = PROJECT_ROOT / "docs" / "assembler-regressions.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    assert validate_manifest(manifest, manifest_path) == []


def test_manifest_validation_catches_duplicate_names_and_bad_hex() -> None:
    manifest_path = PROJECT_ROOT / "docs" / "assembler-regressions.json"
    manifest = {
        "programs": [
            {
                "name": "dupe",
                "source": "programs/logic_flags.asm",
                "expected_hex": ["00"] * MEM_SIZE,
                "expected_final": {"dmem": [0] * MEM_SIZE},
                "coverage_signature": {"opcode_hit_bitmap": "0" * 15},
            },
            {
                "name": "dupe",
                "source": "programs/logic_flags.asm",
                "expected_hex": ["0"] * MEM_SIZE,
                "expected_final": {"dmem": []},
                "coverage_signature": {},
            },
        ]
    }

    failures = validate_manifest(manifest, manifest_path)
    assert any("duplicate program name" in failure for failure in failures)
    assert any("duplicate source" in failure for failure in failures)
    assert any("expected two uppercase hex digits" in failure for failure in failures)
    assert any("expected 16 entries" in failure for failure in failures)


def test_assembler_corpus_report_matches_tracked_doc() -> None:
    manifest_path = PROJECT_ROOT / "docs" / "assembler-regressions.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    expected = render_markdown(manifest, manifest_path)

    assert (PROJECT_ROOT / "docs" / "assembler-regressions.md").read_text(encoding="utf-8") == expected
