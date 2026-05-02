from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.asm import OPCODES
from tb.cpu_lib import (
    OPC_ADD,
    OPC_AND,
    OPC_CMP,
    OPC_HLT,
    OPC_JMP,
    OPC_JZ,
    OPC_LDA,
    OPC_LDI,
    OPC_NOP,
    OPC_OR,
    OPC_SHL,
    OPC_SHR,
    OPC_STA,
    OPC_SUB,
    OPC_XOR,
    OPCODE_NAMES,
    OPCODES_WITH_DMEM_READ,
    OPCODES_WITH_DMEM_WRITE,
    OPCODES_WITH_OPERANDS,
)


@dataclass(frozen=True)
class IsaDocRow:
    opcode: int
    mnemonic: str
    operand: str
    behavior: str
    flags: str
    pc_effect: str
    memory: str


ISA_DOC_ROWS = [
    IsaDocRow(OPC_NOP, "NOP", "none", "No operation.", "unchanged", "PC + 1", "none"),
    IsaDocRow(OPC_LDI, "LDI", "imm4", "Load zero-extended 4-bit immediate into ACC.", "Z set from ACC; N=0, C=0, V=0", "PC + 1", "none"),
    IsaDocRow(OPC_ADD, "ADD", "addr4", "ACC = ACC + DMEM[addr4].", "Z, N, C, V updated", "PC + 1", "read DMEM[addr4]"),
    IsaDocRow(OPC_SUB, "SUB", "addr4", "ACC = ACC - DMEM[addr4].", "Z, N, C, V updated", "PC + 1", "read DMEM[addr4]"),
    IsaDocRow(OPC_STA, "STA", "addr4", "DMEM[addr4] = ACC.", "unchanged", "PC + 1", "write DMEM[addr4]"),
    IsaDocRow(OPC_LDA, "LDA", "addr4", "ACC = DMEM[addr4].", "Z, N updated; C=0, V=0", "PC + 1", "read DMEM[addr4]"),
    IsaDocRow(OPC_JMP, "JMP", "addr4", "Unconditional branch.", "unchanged", "PC = addr4", "none"),
    IsaDocRow(OPC_JZ, "JZ", "addr4", "Branch when ZERO is set.", "unchanged", "PC = addr4 if ZERO else PC + 1", "none"),
    IsaDocRow(OPC_HLT, "HLT", "none", "Halt execution.", "unchanged", "PC holds", "none"),
    IsaDocRow(OPC_AND, "AND", "addr4", "ACC = ACC & DMEM[addr4].", "Z, N updated; C=0, V=0", "PC + 1", "read DMEM[addr4]"),
    IsaDocRow(OPC_OR, "OR", "addr4", "ACC = ACC | DMEM[addr4].", "Z, N updated; C=0, V=0", "PC + 1", "read DMEM[addr4]"),
    IsaDocRow(OPC_XOR, "XOR", "addr4", "ACC = ACC ^ DMEM[addr4].", "Z, N updated; C=0, V=0", "PC + 1", "read DMEM[addr4]"),
    IsaDocRow(OPC_SHL, "SHL", "none", "ACC = ACC << 1.", "Z, N, C, V updated", "PC + 1", "none"),
    IsaDocRow(OPC_SHR, "SHR", "none", "ACC = ACC >> 1.", "Z, N, C updated; V=0", "PC + 1", "none"),
    IsaDocRow(OPC_CMP, "CMP", "addr4", "Update flags from ACC - DMEM[addr4]; ACC is unchanged.", "Z, N, C, V updated", "PC + 1", "read DMEM[addr4]"),
]


def validate_isa_tables() -> list[str]:
    errors: list[str] = []
    seen_opcodes: dict[int, str] = {}

    for mnemonic, (opcode, mode) in OPCODES.items():
        if opcode in seen_opcodes:
            errors.append(f"opcode 0x{opcode:X} is assigned to both {seen_opcodes[opcode]} and {mnemonic}")
        seen_opcodes[opcode] = mnemonic

        expected_name = OPCODE_NAMES.get(opcode)
        if expected_name != mnemonic:
            errors.append(f"assembler mnemonic {mnemonic} for opcode 0x{opcode:X} does not match cpu_lib name {expected_name}")

        expects_operand = opcode in OPCODES_WITH_OPERANDS
        has_operand = mode == "nibble"
        if expects_operand != has_operand:
            errors.append(f"operand-mode mismatch for {mnemonic}: assembler={mode}, cpu_lib_operand={expects_operand}")

    for opcode, mnemonic in sorted(OPCODE_NAMES.items()):
        if opcode not in seen_opcodes:
            errors.append(f"cpu_lib opcode 0x{opcode:X} ({mnemonic}) is missing from assembler OPCODES")

    for row in ISA_DOC_ROWS:
        if OPCODE_NAMES.get(row.opcode) != row.mnemonic:
            errors.append(f"ISA doc row for opcode 0x{row.opcode:X} has stale mnemonic {row.mnemonic}")
        asm_mode = OPCODES.get(row.mnemonic, (None, None))[1]
        if row.operand == "none" and asm_mode != "none":
            errors.append(f"ISA doc row for {row.mnemonic} says no operand, assembler mode is {asm_mode}")
        if row.operand != "none" and asm_mode != "nibble":
            errors.append(f"ISA doc row for {row.mnemonic} says operand {row.operand}, assembler mode is {asm_mode}")

        mentions_read = row.memory.startswith("read")
        mentions_write = row.memory.startswith("write")
        if (row.opcode in OPCODES_WITH_DMEM_READ) != mentions_read:
            errors.append(f"ISA doc memory-read metadata is stale for {row.mnemonic}")
        if (row.opcode in OPCODES_WITH_DMEM_WRITE) != mentions_write:
            errors.append(f"ISA doc memory-write metadata is stale for {row.mnemonic}")

    documented = {row.opcode for row in ISA_DOC_ROWS}
    for opcode in sorted(OPCODE_NAMES):
        if opcode not in documented:
            errors.append(f"opcode 0x{opcode:X} ({OPCODE_NAMES[opcode]}) is missing from ISA_DOC_ROWS")

    return errors


def encoding_for(row: IsaDocRow) -> str:
    if row.operand == "none":
        return f"`0x{row.opcode:X}0` (`operand` ignored by RTL for this opcode)"
    return f"`0x{row.opcode:X}n`, where `n` is `{row.operand}`"


def md_cell(text: str) -> str:
    return text.replace("|", "\\|")


def render_markdown() -> str:
    lines: list[str] = [
        "<!-- Generated by scripts/isa_report.py. Do not edit by hand. -->",
        "",
        "# ISA Reference",
        "",
        "This page is generated from the assembler opcode table and checked against the Python reference model metadata.",
        "",
        "## Encoding",
        "",
        "Each instruction is one byte: bits `[7:4]` hold the opcode and bits `[3:0]` hold the operand nibble.",
        "Instruction memory and data memory each contain 16 entries, so address operands are 4-bit values.",
        "",
        "## Valid Opcodes",
        "",
        "| Opcode | Mnemonic | Operand | Encoding | Behavior | Flags | PC effect | Memory |",
        "|---|---|---|---|---|---|---|---|",
    ]

    for row in sorted(ISA_DOC_ROWS, key=lambda item: item.opcode):
        lines.append(
            f"| `0x{row.opcode:X}` | `{row.mnemonic}` | `{row.operand}` | {md_cell(encoding_for(row))} | "
            f"{md_cell(row.behavior)} | {md_cell(row.flags)} | {md_cell(row.pc_effect)} | {md_cell(row.memory)} |"
        )

    lines.extend(
        [
            "",
            "## Illegal Opcode",
            "",
            "`0xF*` is intentionally left illegal. The RTL and Python reference model both trap it by setting `HALTED=1` and holding `PC`.",
            "",
            "## Consistency Checks",
            "",
            "Run the generated-doc check with:",
            "",
            "```bash",
            "bash scripts/check-python-model.sh",
            "```",
            "",
            "Regenerate this page after intentional ISA edits with:",
            "",
            "```bash",
            "bash scripts/generate-isa-docs.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the tutorial CPU ISA reference.")
    parser.add_argument("--output", type=Path, default=Path("docs/isa.md"), help="Output Markdown path.")
    parser.add_argument("--check", action="store_true", help="Fail if the output file is missing or stale.")
    args = parser.parse_args()

    errors = validate_isa_tables()
    if errors:
        for error in errors:
            print(f"ISA table error: {error}", file=sys.stderr)
        raise SystemExit(1)

    expected = render_markdown()
    if args.check:
        if not args.output.exists():
            print(f"ISA doc is missing: {args.output}", file=sys.stderr)
            raise SystemExit(1)
        actual = args.output.read_text(encoding="utf-8")
        if actual != expected:
            print(f"ISA doc is stale: {args.output}. Regenerate with scripts/generate-isa-docs.*", file=sys.stderr)
            raise SystemExit(1)
        print(f"ISA doc is up to date: {args.output}")
        return

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
