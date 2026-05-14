from __future__ import annotations

import argparse
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tb.coverage_utils import CoverageModel, trace_program
from tb.cpu_lib import (
    MEM_SIZE,
    build_add_carry_program,
    build_branch_not_taken_program,
    build_branch_stress_program,
    build_cmp_negative_program,
    build_illegal_opcode_program,
    build_jump_loop_program,
    build_logic_ops_program,
    build_random_dataflow_program,
    build_shift_overflow_program,
    build_smoke_program,
    build_sub_carry_program,
    disassemble_program,
)


@dataclass(frozen=True)
class RegressionCase:
    name: str
    kind: str
    seed: str
    program: tuple[int, ...]
    max_cycles: int
    purpose: str


@dataclass(frozen=True)
class CaseSummary:
    name: str
    kind: str
    seed: str
    program_len: int
    cycles: int
    final: dict
    first_instructions: tuple[str, ...]
    purpose: str


def regression_cases() -> tuple[RegressionCase, ...]:
    return (
        RegressionCase(
            name="smoke_branch_taken",
            kind="directed",
            seed="-",
            program=tuple(build_smoke_program()),
            max_cycles=96,
            purpose="Baseline load/store/add path with a taken `JZ` into `HLT`.",
        ),
        RegressionCase(
            name="branch_not_taken",
            kind="directed",
            seed="-",
            program=tuple(build_branch_not_taken_program()),
            max_cycles=64,
            purpose="Complements the smoke branch by proving `JZ` fall-through.",
        ),
        RegressionCase(
            name="logic_flags",
            kind="directed",
            seed="-",
            program=tuple(build_logic_ops_program()),
            max_cycles=128,
            purpose="AND/OR/XOR/shift/CMP flag coverage.",
        ),
        RegressionCase(
            name="jump_loop",
            kind="directed",
            seed="-",
            program=tuple(build_jump_loop_program()),
            max_cycles=128,
            purpose="Looping `JMP` and terminating `JZ` control-flow coverage.",
        ),
        RegressionCase(
            name="add_carry",
            kind="directed",
            seed="-",
            program=tuple(build_add_carry_program()),
            max_cycles=96,
            purpose="ADD carry and negative-result flag coverage.",
        ),
        RegressionCase(
            name="sub_carry",
            kind="directed",
            seed="-",
            program=tuple(build_sub_carry_program()),
            max_cycles=96,
            purpose="SUB carry/no-borrow and borrow behavior.",
        ),
        RegressionCase(
            name="shift_overflow",
            kind="directed",
            seed="-",
            program=tuple(build_shift_overflow_program()),
            max_cycles=96,
            purpose="SHL carry/overflow closure.",
        ),
        RegressionCase(
            name="cmp_negative",
            kind="directed",
            seed="-",
            program=tuple(build_cmp_negative_program()),
            max_cycles=64,
            purpose="CMP negative and borrow closure without modifying ACC.",
        ),
        RegressionCase(
            name="illegal_opcode",
            kind="negative",
            seed="-",
            program=tuple(build_illegal_opcode_program()),
            max_cycles=4,
            purpose="Illegal opcode halts without advancing PC.",
        ),
        RegressionCase(
            name="dataflow_20260221",
            kind="random-dataflow",
            seed="20260221",
            program=tuple(build_random_dataflow_program(seed=20260221, length=12)),
            max_cycles=128,
            purpose="Deterministic randomized dataflow over memory and ALU operations.",
        ),
        RegressionCase(
            name="dataflow_0000c0de",
            kind="random-dataflow",
            seed="0x0000C0DE",
            program=tuple(build_random_dataflow_program(seed=0xC0DE, length=16)),
            max_cycles=128,
            purpose="Full 16-byte deterministic dataflow image with final-slot halt.",
        ),
        RegressionCase(
            name="branch_badc0de0",
            kind="random-branch",
            seed="0xBADC0DE0",
            program=tuple(build_branch_stress_program(seed=0xBADC0DE0)),
            max_cycles=192,
            purpose="Seeded loop-body opcode and data selection for branch stress.",
        ),
        RegressionCase(
            name="branch_12345678",
            kind="random-branch",
            seed="0x12345678",
            program=tuple(build_branch_stress_program(seed=0x12345678)),
            max_cycles=192,
            purpose="Independent seeded branch stress point for regression drift detection.",
        ),
    )


def case_summaries() -> tuple[CaseSummary, ...]:
    summaries: list[CaseSummary] = []
    for case in regression_cases():
        steps, model = trace_program(list(case.program), max_cycles=case.max_cycles)
        summaries.append(
            CaseSummary(
                name=case.name,
                kind=case.kind,
                seed=case.seed,
                program_len=len(case.program),
                cycles=len(steps),
                final=asdict(model.final_state()),
                first_instructions=tuple(disassemble_program(case.program)[:4]),
                purpose=case.purpose,
            )
        )
    return tuple(summaries)


def combined_coverage_report() -> dict:
    coverage = CoverageModel()
    random_suite_iterations = 0
    branch_random_suite_iterations = 0

    for case in regression_cases():
        steps, _ = trace_program(list(case.program), max_cycles=case.max_cycles)
        coverage.sample_run(steps)
        random_suite_iterations += int(case.kind == "random-dataflow")
        branch_random_suite_iterations += int(case.kind == "random-branch")

    return coverage.to_report(
        random_suite_iterations=random_suite_iterations,
        branch_random_suite_iterations=branch_random_suite_iterations,
    )


def validate_reference_regression_catalog() -> list[str]:
    failures: list[str] = []
    cases = regression_cases()
    names = [case.name for case in cases]

    if len(names) != len(set(names)):
        failures.append("reference regression cases contain duplicate names")
    if len(cases) < 10:
        failures.append("reference regression must keep at least 10 programs for coverage-model closure")

    required_kinds = {"directed", "negative", "random-dataflow", "random-branch"}
    observed_kinds = {case.kind for case in cases}
    for missing in sorted(required_kinds - observed_kinds):
        failures.append(f"missing regression case kind `{missing}`")

    for case in cases:
        if not case.program:
            failures.append(f"{case.name}: program is empty")
            continue
        if len(case.program) > MEM_SIZE:
            failures.append(f"{case.name}: program length exceeds {MEM_SIZE} bytes")
        try:
            steps, model = trace_program(list(case.program), max_cycles=case.max_cycles)
        except AssertionError as exc:
            failures.append(f"{case.name}: {exc}")
            continue
        if not steps:
            failures.append(f"{case.name}: produced an empty trace")
        if model.halted != 1:
            failures.append(f"{case.name}: model did not halt")

    report = combined_coverage_report()
    if not report["coverage_pass"]:
        failures.extend(f"combined coverage: {failure}" for failure in report["coverage_failures"])

    readme_text = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")
    plan_text = (PROJECT_ROOT / "docs" / "verification-plan.md").read_text(encoding="utf-8")
    if "docs/reference-regression.md" not in readme_text:
        failures.append("README.md must link to docs/reference-regression.md")
    if "docs/reference-regression.md" not in plan_text:
        failures.append("docs/verification-plan.md must link to docs/reference-regression.md")

    return failures


def _hex_bytes(program: tuple[int, ...]) -> str:
    return "`" + " ".join(f"{value:02X}" for value in program) + "`"


def _final_state_text(final: dict) -> str:
    return (
        f"ACC=0x{final['acc']:02X} PC=0x{final['pc']:X} "
        f"Z{final['zero']} C{final['carry']} N{final['neg']} V{final['overflow']} H{final['halted']}"
    )


def render_markdown() -> str:
    failures = validate_reference_regression_catalog()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"reference regression catalog is invalid:\n{joined}")

    cases = regression_cases()
    summaries = case_summaries()
    coverage = combined_coverage_report()

    lines = [
        "<!-- Generated by scripts/reference_regression_catalog.py. Do not edit by hand. -->",
        "",
        "# Reference Regression Catalog",
        "",
        "This page is generated from deterministic Python reference-model regression cases and checked by the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Regression programs: {len(cases)}",
        f"- Program runs sampled: {coverage['program_runs']}",
        f"- Total reference cycles: {coverage['total_cycles']}",
        f"- Opcode hit bitmap: `{coverage['opcode_hit_bitmap']}`",
        f"- Coverage pass: `{coverage['coverage_pass']}`",
        f"- Dataflow random seeds: {coverage['random_suite_iterations']}",
        f"- Branch random seeds: {coverage['branch_random_suite_iterations']}",
        "",
        "## Coverage Closure",
        "",
        "| Goal | Observed |",
        "|---|---:|",
        f"| Valid opcode bitmap | `{coverage['opcode_hit_bitmap']}` |",
        f"| Illegal opcode hit | {coverage['illegal_opcode_hit']} |",
        f"| JZ taken | {coverage['jz_taken']} |",
        f"| JZ not taken | {coverage['jz_not_taken']} |",
        f"| ZERO 0->1 transitions | {coverage['zero_transition_01']} |",
        f"| ZERO 1->0 transitions | {coverage['zero_transition_10']} |",
        f"| Carry=0 samples | {coverage['carry_0']} |",
        f"| Carry=1 samples | {coverage['carry_1']} |",
        f"| Negative=0 samples | {coverage['neg_0']} |",
        f"| Negative=1 samples | {coverage['neg_1']} |",
        f"| Overflow=0 samples | {coverage['overflow_0']} |",
        f"| Overflow=1 samples | {coverage['overflow_1']} |",
        "",
        "## Cases",
        "",
        "| Case | Kind | Seed | Bytes | Cycles | Final state | First instructions | Purpose |",
        "|---|---|---|---|---:|---|---|---|",
    ]

    summary_by_name = {summary.name: summary for summary in summaries}
    for case in cases:
        summary = summary_by_name[case.name]
        lines.append(
            "| `{name}` | `{kind}` | `{seed}` | {bytes} | {cycles} | {final} | {insns} | {purpose} |".format(
                name=case.name,
                kind=case.kind,
                seed=case.seed,
                bytes=_hex_bytes(case.program),
                cycles=summary.cycles,
                final=_final_state_text(summary.final),
                insns="<br>".join(f"`{insn}`" for insn in summary.first_instructions),
                purpose=case.purpose,
            )
        )

    lines.extend(
        [
            "",
            "Regenerate this page after intentional reference-regression edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-reference-regression.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-reference-regression.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the Python reference regression catalog.")
    parser.add_argument("--output", type=Path, default=Path("docs/reference-regression.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Reference regression catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Reference regression catalog is stale: {output_path}. "
                "Regenerate with scripts/generate-reference-regression.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Reference regression catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
