from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tb.cpu_lib import (
    MEM_SIZE,
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
    ReferenceCPU,
    decode_instruction,
    disassemble_instruction,
    ins,
)


@dataclass(frozen=True)
class CpuState:
    acc: int
    pc: int
    zero: int
    carry: int
    neg: int
    overflow: int
    halted: int = 0


@dataclass(frozen=True)
class SemanticVector:
    name: str
    instruction: int
    initial: CpuState
    expected: CpuState
    initial_dmem: tuple[tuple[int, int], ...] = ()
    expected_dmem: tuple[tuple[int, int], ...] = ()
    purpose: str = ""


@dataclass(frozen=True)
class VectorResult:
    name: str
    instruction: int
    mnemonic: str
    initial: CpuState
    observed: CpuState
    expected: CpuState
    observed_dmem: tuple[tuple[int, int], ...]
    expected_dmem: tuple[tuple[int, int], ...]
    passed: bool


def semantic_vectors() -> tuple[SemanticVector, ...]:
    return (
        SemanticVector(
            name="nop_preserves_state",
            instruction=ins(OPC_NOP, 0),
            initial=CpuState(acc=0x5A, pc=3, zero=0, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x5A, pc=4, zero=0, carry=1, neg=1, overflow=1),
            purpose="NOP advances PC and leaves architectural state unchanged.",
        ),
        SemanticVector(
            name="ldi_zero_clears_flags",
            instruction=ins(OPC_LDI, 0),
            initial=CpuState(acc=0xAA, pc=2, zero=0, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x00, pc=3, zero=1, carry=0, neg=0, overflow=0),
            purpose="LDI zero sets ZERO and clears C/N/V.",
        ),
        SemanticVector(
            name="ldi_nonzero",
            instruction=ins(OPC_LDI, 0xF),
            initial=CpuState(acc=0x00, pc=1, zero=1, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x0F, pc=2, zero=0, carry=0, neg=0, overflow=0),
            purpose="LDI zero-extends the immediate nibble.",
        ),
        SemanticVector(
            name="add_no_carry",
            instruction=ins(OPC_ADD, 2),
            initial=CpuState(acc=0x05, pc=4, zero=1, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x0C, pc=5, zero=0, carry=0, neg=0, overflow=0),
            initial_dmem=((2, 0x07),),
            expected_dmem=((2, 0x07),),
            purpose="ADD updates ACC and clears carry/overflow when the sum fits.",
        ),
        SemanticVector(
            name="add_signed_overflow",
            instruction=ins(OPC_ADD, 1),
            initial=CpuState(acc=0x7F, pc=5, zero=0, carry=0, neg=0, overflow=0),
            expected=CpuState(acc=0x80, pc=6, zero=0, carry=0, neg=1, overflow=1),
            initial_dmem=((1, 0x01),),
            expected_dmem=((1, 0x01),),
            purpose="ADD detects positive signed overflow without unsigned carry.",
        ),
        SemanticVector(
            name="add_unsigned_carry",
            instruction=ins(OPC_ADD, 1),
            initial=CpuState(acc=0xF0, pc=6, zero=0, carry=0, neg=1, overflow=0),
            expected=CpuState(acc=0x10, pc=7, zero=0, carry=1, neg=0, overflow=0),
            initial_dmem=((1, 0x20),),
            expected_dmem=((1, 0x20),),
            purpose="ADD reports unsigned carry independently from signed overflow.",
        ),
        SemanticVector(
            name="sub_no_borrow",
            instruction=ins(OPC_SUB, 3),
            initial=CpuState(acc=0x09, pc=3, zero=0, carry=0, neg=1, overflow=1),
            expected=CpuState(acc=0x05, pc=4, zero=0, carry=1, neg=0, overflow=0),
            initial_dmem=((3, 0x04),),
            expected_dmem=((3, 0x04),),
            purpose="SUB sets carry when no borrow is required.",
        ),
        SemanticVector(
            name="sub_borrow_negative",
            instruction=ins(OPC_SUB, 3),
            initial=CpuState(acc=0x01, pc=3, zero=0, carry=1, neg=0, overflow=1),
            expected=CpuState(acc=0xFF, pc=4, zero=0, carry=0, neg=1, overflow=0),
            initial_dmem=((3, 0x02),),
            expected_dmem=((3, 0x02),),
            purpose="SUB clears carry on borrow and exposes a negative two's-complement result.",
        ),
        SemanticVector(
            name="sub_signed_overflow",
            instruction=ins(OPC_SUB, 3),
            initial=CpuState(acc=0x80, pc=3, zero=0, carry=0, neg=1, overflow=0),
            expected=CpuState(acc=0x7F, pc=4, zero=0, carry=1, neg=0, overflow=1),
            initial_dmem=((3, 0x01),),
            expected_dmem=((3, 0x01),),
            purpose="SUB detects signed overflow independently from borrow.",
        ),
        SemanticVector(
            name="sta_writes_memory_preserves_flags",
            instruction=ins(OPC_STA, 4),
            initial=CpuState(acc=0xA5, pc=8, zero=0, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0xA5, pc=9, zero=0, carry=1, neg=1, overflow=1),
            initial_dmem=((4, 0x11),),
            expected_dmem=((4, 0xA5),),
            purpose="STA writes ACC to DMEM and leaves flags unchanged.",
        ),
        SemanticVector(
            name="lda_zero",
            instruction=ins(OPC_LDA, 5),
            initial=CpuState(acc=0x44, pc=8, zero=0, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x00, pc=9, zero=1, carry=0, neg=0, overflow=0),
            initial_dmem=((5, 0x00),),
            expected_dmem=((5, 0x00),),
            purpose="LDA zero updates ZERO and clears C/V.",
        ),
        SemanticVector(
            name="lda_negative",
            instruction=ins(OPC_LDA, 5),
            initial=CpuState(acc=0x00, pc=8, zero=1, carry=1, neg=0, overflow=1),
            expected=CpuState(acc=0x80, pc=9, zero=0, carry=0, neg=1, overflow=0),
            initial_dmem=((5, 0x80),),
            expected_dmem=((5, 0x80),),
            purpose="LDA reflects the sign bit in NEG.",
        ),
        SemanticVector(
            name="jmp_sets_pc",
            instruction=ins(OPC_JMP, 0xC),
            initial=CpuState(acc=0x22, pc=3, zero=1, carry=1, neg=0, overflow=1),
            expected=CpuState(acc=0x22, pc=0xC, zero=1, carry=1, neg=0, overflow=1),
            purpose="JMP replaces PC and leaves flags unchanged.",
        ),
        SemanticVector(
            name="jz_taken",
            instruction=ins(OPC_JZ, 0xD),
            initial=CpuState(acc=0x22, pc=3, zero=1, carry=0, neg=1, overflow=0),
            expected=CpuState(acc=0x22, pc=0xD, zero=1, carry=0, neg=1, overflow=0),
            purpose="JZ takes the branch when ZERO is set.",
        ),
        SemanticVector(
            name="jz_not_taken",
            instruction=ins(OPC_JZ, 0xD),
            initial=CpuState(acc=0x22, pc=3, zero=0, carry=0, neg=1, overflow=0),
            expected=CpuState(acc=0x22, pc=4, zero=0, carry=0, neg=1, overflow=0),
            purpose="JZ falls through when ZERO is clear.",
        ),
        SemanticVector(
            name="hlt_sticks_pc",
            instruction=ins(OPC_HLT, 0),
            initial=CpuState(acc=0x33, pc=7, zero=0, carry=1, neg=1, overflow=0),
            expected=CpuState(acc=0x33, pc=7, zero=0, carry=1, neg=1, overflow=0, halted=1),
            purpose="HLT raises halted and holds PC.",
        ),
        SemanticVector(
            name="and_masks_acc",
            instruction=ins(OPC_AND, 6),
            initial=CpuState(acc=0xAA, pc=1, zero=1, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x0A, pc=2, zero=0, carry=0, neg=0, overflow=0),
            initial_dmem=((6, 0x0F),),
            expected_dmem=((6, 0x0F),),
            purpose="AND updates ACC and clears carry/overflow.",
        ),
        SemanticVector(
            name="or_sets_negative",
            instruction=ins(OPC_OR, 6),
            initial=CpuState(acc=0x80, pc=1, zero=1, carry=1, neg=0, overflow=1),
            expected=CpuState(acc=0x81, pc=2, zero=0, carry=0, neg=1, overflow=0),
            initial_dmem=((6, 0x01),),
            expected_dmem=((6, 0x01),),
            purpose="OR can set NEG while clearing carry/overflow.",
        ),
        SemanticVector(
            name="xor_zero",
            instruction=ins(OPC_XOR, 6),
            initial=CpuState(acc=0x5A, pc=1, zero=0, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x00, pc=2, zero=1, carry=0, neg=0, overflow=0),
            initial_dmem=((6, 0x5A),),
            expected_dmem=((6, 0x5A),),
            purpose="XOR equal operands drives ZERO.",
        ),
        SemanticVector(
            name="shl_carry_overflow",
            instruction=ins(OPC_SHL, 0),
            initial=CpuState(acc=0x80, pc=1, zero=0, carry=0, neg=1, overflow=0),
            expected=CpuState(acc=0x00, pc=2, zero=1, carry=1, neg=0, overflow=1),
            purpose="SHL reports shifted-out bit and sign-change overflow.",
        ),
        SemanticVector(
            name="shr_carry",
            instruction=ins(OPC_SHR, 0),
            initial=CpuState(acc=0x81, pc=1, zero=0, carry=0, neg=1, overflow=1),
            expected=CpuState(acc=0x40, pc=2, zero=0, carry=1, neg=0, overflow=0),
            purpose="SHR reports bit 0 as carry and always clears overflow.",
        ),
        SemanticVector(
            name="cmp_equal_preserves_acc",
            instruction=ins(OPC_CMP, 7),
            initial=CpuState(acc=0x05, pc=1, zero=0, carry=0, neg=1, overflow=1),
            expected=CpuState(acc=0x05, pc=2, zero=1, carry=1, neg=0, overflow=0),
            initial_dmem=((7, 0x05),),
            expected_dmem=((7, 0x05),),
            purpose="CMP updates flags for equality without modifying ACC.",
        ),
        SemanticVector(
            name="cmp_borrow_negative",
            instruction=ins(OPC_CMP, 7),
            initial=CpuState(acc=0x01, pc=1, zero=1, carry=1, neg=0, overflow=1),
            expected=CpuState(acc=0x01, pc=2, zero=0, carry=0, neg=1, overflow=0),
            initial_dmem=((7, 0x02),),
            expected_dmem=((7, 0x02),),
            purpose="CMP reports borrow and negative result while preserving ACC.",
        ),
        SemanticVector(
            name="cmp_signed_overflow",
            instruction=ins(OPC_CMP, 7),
            initial=CpuState(acc=0x80, pc=1, zero=0, carry=0, neg=1, overflow=0),
            expected=CpuState(acc=0x80, pc=2, zero=0, carry=1, neg=0, overflow=1),
            initial_dmem=((7, 0x01),),
            expected_dmem=((7, 0x01),),
            purpose="CMP shares SUB overflow semantics without changing ACC.",
        ),
        SemanticVector(
            name="illegal_opcode_halts",
            instruction=0xF3,
            initial=CpuState(acc=0x66, pc=9, zero=0, carry=1, neg=1, overflow=1),
            expected=CpuState(acc=0x66, pc=9, zero=0, carry=1, neg=1, overflow=1, halted=1),
            purpose="Illegal opcode traps by halting and holding PC.",
        ),
    )


def _state_from_model(model: ReferenceCPU) -> CpuState:
    return CpuState(
        acc=model.acc,
        pc=model.pc,
        zero=model.zero,
        carry=model.carry,
        neg=model.neg,
        overflow=model.overflow,
        halted=model.halted,
    )


def _selected_dmem(model: ReferenceCPU, addresses: tuple[int, ...]) -> tuple[tuple[int, int], ...]:
    return tuple((addr, model.dmem[addr]) for addr in addresses)


def _expected_full_dmem(vector: SemanticVector) -> tuple[int, ...]:
    dmem = [0] * MEM_SIZE
    for addr, value in vector.initial_dmem:
        dmem[addr & 0xF] = value & 0xFF
    for addr, value in vector.expected_dmem:
        dmem[addr & 0xF] = value & 0xFF
    return tuple(dmem)


def run_vector(vector: SemanticVector) -> VectorResult:
    model = ReferenceCPU()
    model.acc = vector.initial.acc & 0xFF
    model.pc = vector.initial.pc & 0xF
    model.zero = vector.initial.zero & 0x1
    model.carry = vector.initial.carry & 0x1
    model.neg = vector.initial.neg & 0x1
    model.overflow = vector.initial.overflow & 0x1
    model.halted = vector.initial.halted & 0x1
    model.imem[model.pc] = vector.instruction & 0xFF

    for addr, value in vector.initial_dmem:
        model.dmem[addr & 0xF] = value & 0xFF

    step = model.step()
    if step is None:
        raise AssertionError(f"{vector.name}: initial state was already halted")

    expected_addresses = tuple(addr & 0xF for addr, _ in vector.expected_dmem)
    observed = _state_from_model(model)
    observed_dmem = _selected_dmem(model, expected_addresses)
    passed = (
        observed == vector.expected
        and observed_dmem == vector.expected_dmem
        and tuple(model.dmem) == _expected_full_dmem(vector)
    )

    return VectorResult(
        name=vector.name,
        instruction=vector.instruction,
        mnemonic=disassemble_instruction(vector.instruction),
        initial=vector.initial,
        observed=observed,
        expected=vector.expected,
        observed_dmem=observed_dmem,
        expected_dmem=vector.expected_dmem,
        passed=passed,
    )


def vector_results() -> tuple[VectorResult, ...]:
    return tuple(run_vector(vector) for vector in semantic_vectors())


def validate_semantic_vectors() -> list[str]:
    failures: list[str] = []
    vectors = semantic_vectors()
    names = [vector.name for vector in vectors]
    if len(names) != len(set(names)):
        failures.append("semantic vectors contain duplicate names")

    covered_opcodes = {decode_instruction(vector.instruction)[0] for vector in vectors if vector.instruction < 0xF0}
    for opcode, mnemonic in OPCODE_NAMES.items():
        if opcode not in covered_opcodes:
            failures.append(f"missing semantic vector for opcode 0x{opcode:X} ({mnemonic})")

    if not any(decode_instruction(vector.instruction)[0] == 0xF for vector in vectors):
        failures.append("missing semantic vector for illegal opcode 0xF")

    for vector in vectors:
        if not 0 <= vector.initial.pc < MEM_SIZE:
            failures.append(f"{vector.name}: initial PC out of range")
        for addr, _ in vector.initial_dmem + vector.expected_dmem:
            if not 0 <= addr < MEM_SIZE:
                failures.append(f"{vector.name}: DMEM address {addr} out of range")
        try:
            result = run_vector(vector)
        except AssertionError as exc:
            failures.append(str(exc))
            continue
        if not result.passed:
            failures.append(
                f"{vector.name}: observed {result.observed} dmem={result.observed_dmem}, "
                f"expected {result.expected} dmem={result.expected_dmem}"
            )

    readme_text = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")
    plan_text = (PROJECT_ROOT / "docs" / "verification-plan.md").read_text(encoding="utf-8")
    if "docs/semantic-vectors.md" not in readme_text:
        failures.append("README.md must link to docs/semantic-vectors.md")
    if "docs/semantic-vectors.md" not in plan_text:
        failures.append("docs/verification-plan.md must link to docs/semantic-vectors.md")

    return failures


def _state_text(state: CpuState) -> str:
    return (
        f"ACC=0x{state.acc:02X} PC=0x{state.pc:X} "
        f"Z{state.zero} C{state.carry} N{state.neg} V{state.overflow} H{state.halted}"
    )


def _dmem_text(values: tuple[tuple[int, int], ...]) -> str:
    if not values:
        return "-"
    return "<br>".join(f"`DMEM[{addr:X}]=0x{value:02X}`" for addr, value in values)


def render_markdown() -> str:
    failures = validate_semantic_vectors()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"semantic vector catalog is invalid:\n{joined}")

    results = vector_results()
    covered_valid_opcodes = sorted({decode_instruction(result.instruction)[0] for result in results if result.instruction < 0xF0})
    illegal_vectors = sum(1 for result in results if decode_instruction(result.instruction)[0] == 0xF)

    lines = [
        "<!-- Generated by scripts/semantic_vectors.py. Do not edit by hand. -->",
        "",
        "# Semantic Vectors",
        "",
        "This page is generated from executable single-instruction reference-model checks and verified in the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Semantic vectors: {len(results)}",
        f"- Valid opcodes covered: {len(covered_valid_opcodes)} / {len(OPCODE_NAMES)}",
        f"- Illegal opcode vectors: {illegal_vectors}",
        "- Each vector initializes the reference CPU, executes one instruction, and compares ACC, PC, flags, HALTED, and selected DMEM bytes.",
        "",
        "## Opcode Coverage",
        "",
        "| Opcode | Mnemonic | Covered |",
        "|---|---|---|",
    ]

    for opcode, mnemonic in sorted(OPCODE_NAMES.items()):
        covered = int(opcode in covered_valid_opcodes)
        lines.append(f"| `0x{opcode:X}` | `{mnemonic}` | `{covered}` |")
    lines.append("| `0xF` | `illegal` | `1` |")

    lines.extend(
        [
            "",
            "## Vectors",
            "",
            "| Vector | Instruction | Initial state | Initial DMEM | Expected state | Expected DMEM | Purpose |",
            "|---|---|---|---|---|---|---|",
        ]
    )

    vector_by_name = {vector.name: vector for vector in semantic_vectors()}
    for result in results:
        vector = vector_by_name[result.name]
        lines.append(
            "| `{name}` | `0x{instruction:02X}` {mnemonic} | {initial} | {initial_dmem} | {expected} | {expected_dmem} | {purpose} |".format(
                name=result.name,
                instruction=result.instruction,
                mnemonic=f"`{result.mnemonic}`",
                initial=_state_text(result.initial),
                initial_dmem=_dmem_text(vector.initial_dmem),
                expected=_state_text(result.expected),
                expected_dmem=_dmem_text(result.expected_dmem),
                purpose=vector.purpose,
            )
        )

    lines.extend(
        [
            "",
            "Regenerate this page after intentional semantic-vector edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-semantic-vectors.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-semantic-vectors.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check single-instruction semantic vectors.")
    parser.add_argument("--output", type=Path, default=Path("docs/semantic-vectors.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Semantic vector catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Semantic vector catalog is stale: {output_path}. "
                "Regenerate with scripts/generate-semantic-vectors.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Semantic vector catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
