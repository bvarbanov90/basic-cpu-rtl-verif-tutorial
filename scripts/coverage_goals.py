from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.artifact_catalog import artifact_entries
from tb.coverage_utils import CoverageModel


@dataclass(frozen=True)
class CoverageSuite:
    suite_id: str
    title: str
    source: str
    artifact: str
    show_helper: str
    goal_source: str
    notes: str


SUITES: tuple[CoverageSuite, ...] = (
    CoverageSuite(
        suite_id="core",
        title="Core native SV functional coverage",
        source="tb/simple_cpu_tb.sv",
        artifact="sim_build/coverage.json",
        show_helper="show-coverage",
        goal_source="sv",
        notes="Opcode, branch, flag, cross-bin, reachability, and minimum-run closure.",
    ),
    CoverageSuite(
        suite_id="pyuvm-core",
        title="Core pyuvm subscriber coverage",
        source="tb/coverage_utils.py",
        artifact="sim_build/pyuvm_coverage.json",
        show_helper="show-pyuvm-coverage",
        goal_source="python",
        notes="Subscriber-based pyuvm coverage using the same Python `CoverageModel` as the core scoreboard.",
    ),
    CoverageSuite(
        suite_id="mmio",
        title="Always-ready MMIO wrapper coverage",
        source="tb/simple_cpu_mmio_tb.sv",
        artifact="sim_build/mmio_coverage.json",
        show_helper="show-mmio-coverage",
        goal_source="sv",
        notes="Shadow-window, status, state, control, and program-run coverage.",
    ),
    CoverageSuite(
        suite_id="mmio-wait",
        title="Wait-state MMIO wrapper coverage",
        source="tb/simple_cpu_mmio_wait_tb.sv",
        artifact="sim_build/mmio_wait_coverage.json",
        show_helper="show-mmio-wait-coverage",
        goal_source="sv",
        notes="MMIO wrapper goals plus delayed-ready transaction and wait-cycle bins.",
    ),
    CoverageSuite(
        suite_id="apb",
        title="APB wrapper coverage",
        source="tb/simple_cpu_apb_tb.sv",
        artifact="sim_build/apb_coverage.json",
        show_helper="show-apb-coverage",
        goal_source="sv",
        notes="APB setup/access accounting, transactions, wrapper state, and CPU-visible reads.",
    ),
    CoverageSuite(
        suite_id="apb-fault",
        title="APB fault-injection coverage",
        source="tb/simple_cpu_apb_fault_tb.sv",
        artifact="sim_build/apb_fault_coverage.json",
        show_helper="show-apb-fault-coverage",
        goal_source="sv",
        notes="Malformed APB accesses and reload recovery scenarios.",
    ),
    CoverageSuite(
        suite_id="wishbone",
        title="Wishbone wrapper coverage",
        source="tb/simple_cpu_wishbone_tb.sv",
        artifact="sim_build/wishbone_coverage.json",
        show_helper="show-wishbone-coverage",
        goal_source="sv",
        notes="Wishbone transaction accounting, state coverage, and shared wrapper observability.",
    ),
    CoverageSuite(
        suite_id="wishbone-fault",
        title="Wishbone fault-injection coverage",
        source="tb/simple_cpu_wishbone_fault_tb.sv",
        artifact="sim_build/wishbone_fault_coverage.json",
        show_helper="show-wishbone-fault-coverage",
        goal_source="sv",
        notes="CYC/STB misuse, idle behavior, and reload recovery scenarios.",
    ),
    CoverageSuite(
        suite_id="axi-lite",
        title="AXI-Lite wrapper coverage",
        source="tb/simple_cpu_axi_lite_tb.sv",
        artifact="sim_build/axi_lite_coverage.json",
        show_helper="show-axi-lite-coverage",
        goal_source="sv",
        notes="Coupled write-channel, response, readback, state, and shadow-update coverage.",
    ),
    CoverageSuite(
        suite_id="axi-lite-fault",
        title="AXI-Lite fault-injection coverage",
        source="tb/simple_cpu_axi_lite_fault_tb.sv",
        artifact="sim_build/axi_lite_fault_coverage.json",
        show_helper="show-axi-lite-fault-coverage",
        goal_source="sv",
        notes="Partial-write, split-channel, pending-response, and reload recovery scenarios.",
    ),
)


GOAL_BLOCK_RE = re.compile(
    r'\$fwrite\(fd_json,\s*"  \\"coverage_goals\\": \{\\n"\);\s*(?P<body>.*?)'
    r'\$fwrite\(fd_json,\s*"  \}\\n"\);',
    re.S,
)
CONSTANT_RE = re.compile(
    r"\b(?:localparam|parameter)\s+(?:integer\s+)?(?P<name>[A-Za-z0-9_]+)\s*=\s*(?P<value>\d+)"
)
GOAL_RE = re.compile(r'\$fwrite\(fd_json,\s*"    \\"(?P<name>[A-Za-z0-9_]+)\\": (?P<value>\d+),?\\n"\);')
GOAL_CONSTANT_RE = re.compile(
    r'\$fwrite\(fd_json,\s*"    \\"(?P<name>[A-Za-z0-9_]+)\\": %0d,?\\n",\s*(?P<constant>[A-Za-z0-9_]+)\);'
)


def parse_sv_coverage_goals(path: str) -> dict[str, int]:
    text = (PROJECT_ROOT / path).read_text(encoding="utf-8")
    match = GOAL_BLOCK_RE.search(text)
    if not match:
        raise ValueError(f"{path}: could not find coverage_goals block")
    constants = {const.group("name"): int(const.group("value")) for const in CONSTANT_RE.finditer(text)}
    goals = {goal.group("name"): int(goal.group("value")) for goal in GOAL_RE.finditer(match.group("body"))}
    for goal in GOAL_CONSTANT_RE.finditer(match.group("body")):
        constant = goal.group("constant")
        if constant not in constants:
            raise ValueError(f"{path}: coverage goal `{goal.group('name')}` references unknown constant `{constant}`")
        goals[goal.group("name")] = constants[constant]
    if not goals:
        raise ValueError(f"{path}: coverage_goals block did not contain parseable goals")
    return goals


def python_coverage_goals() -> dict[str, int]:
    return {key: int(value) for key, value in CoverageModel().to_report()["coverage_goals"].items()}


def goals_for_suite(suite: CoverageSuite) -> dict[str, int]:
    if suite.goal_source == "sv":
        return parse_sv_coverage_goals(suite.source)
    if suite.goal_source == "python":
        return python_coverage_goals()
    raise ValueError(f"{suite.suite_id}: unknown goal source `{suite.goal_source}`")


def validate_coverage_goals() -> list[str]:
    failures: list[str] = []
    suite_ids = [suite.suite_id for suite in SUITES]
    if len(suite_ids) != len(set(suite_ids)):
        failures.append("coverage goal catalog contains duplicate suite IDs")

    artifacts = {entry.path: entry for entry in artifact_entries()}
    for suite in SUITES:
        source_path = PROJECT_ROOT / suite.source
        if not source_path.exists():
            failures.append(f"{suite.suite_id}: source path does not exist: {suite.source}")

        artifact = artifacts.get(suite.artifact)
        if not artifact:
            failures.append(f"{suite.suite_id}: artifact is not tracked by docs/artifact-catalog.md: {suite.artifact}")
        elif artifact.show_helper != suite.show_helper:
            failures.append(
                f"{suite.suite_id}: expected show helper `{suite.show_helper}`, got `{artifact.show_helper}`"
            )

        try:
            goals = goals_for_suite(suite)
        except ValueError as exc:
            failures.append(str(exc))
            continue

        if len(goals) < 5:
            failures.append(f"{suite.suite_id}: expected at least five coverage goals, got {len(goals)}")
        for name, value in goals.items():
            if value < 1:
                failures.append(f"{suite.suite_id}: goal `{name}` must have a positive threshold")

        if suite.suite_id == "core":
            python_goals = python_coverage_goals()
            if goals != python_goals:
                failures.append("native core SV goals must match the Python CoverageModel goals")

    readme_text = (PROJECT_ROOT / "README.md").read_text(encoding="utf-8")
    plan_text = (PROJECT_ROOT / "docs" / "verification-plan.md").read_text(encoding="utf-8")
    if "docs/coverage-goals.md" not in readme_text:
        failures.append("README.md must link to docs/coverage-goals.md")
    if "docs/coverage-goals.md" not in plan_text:
        failures.append("docs/verification-plan.md must link to docs/coverage-goals.md")

    return failures


def render_markdown() -> str:
    failures = validate_coverage_goals()
    if failures:
        joined = "\n".join(f"- {failure}" for failure in failures)
        raise ValueError(f"coverage goal catalog is invalid:\n{joined}")

    suite_goals = [(suite, goals_for_suite(suite)) for suite in SUITES]
    total_goals = sum(len(goals) for _, goals in suite_goals)

    lines = [
        "<!-- Generated by scripts/coverage_goals.py. Do not edit by hand. -->",
        "",
        "# Coverage Goals Catalog",
        "",
        "This page is generated from the executable coverage goal definitions and checked by the Python-model CI lane.",
        "",
        "## Summary",
        "",
        f"- Coverage suites: {len(SUITES)}",
        f"- Total explicit goals: {total_goals}",
        "- Native SV suites are parsed from their `$fwrite(... coverage_goals ...)` report blocks.",
        "- The native core SV goals are checked against the Python `CoverageModel` used by cocotb/pyuvm.",
        "- Artifact and show-helper links are checked against `docs/artifact-catalog.md`.",
        "",
        "## Suites",
        "",
        "| Suite | Source | Artifact | Show helper | Goals | Notes |",
        "|---|---|---|---|---:|---|",
    ]

    for suite, goals in suite_goals:
        lines.append(
            f"| `{suite.suite_id}` {suite.title} | `{suite.source}` | `{suite.artifact}` | "
            f"`{suite.show_helper}` | {len(goals)} | {suite.notes} |"
        )

    lines.extend(["", "## Goal Details", ""])

    for suite, goals in suite_goals:
        lines.extend(
            [
                f"### `{suite.suite_id}`",
                "",
                f"- Source: `{suite.source}`",
                f"- Artifact: `{suite.artifact}`",
                f"- Review helper: `{suite.show_helper}`",
                "",
                "| Goal | Threshold |",
                "|---|---:|",
            ]
        )
        for name, value in sorted(goals.items()):
            lines.append(f"| `{name}` | {value} |")
        lines.append("")

    lines.extend(
        [
            "Regenerate this page after intentional coverage-goal edits with:",
            "",
            "```powershell",
            ".\\scripts\\generate-coverage-goals.ps1",
            "```",
            "",
            "```bash",
            "bash scripts/generate-coverage-goals.sh",
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and check the functional coverage goals catalog.")
    parser.add_argument("--output", type=Path, default=Path("docs/coverage-goals.md"))
    parser.add_argument("--check", action="store_true", help="Fail if the generated output is stale.")
    args = parser.parse_args()

    output_path = (PROJECT_ROOT / args.output).resolve()
    expected = render_markdown()

    if args.check:
        if not output_path.exists():
            print(f"Coverage goals catalog is missing: {output_path}", file=sys.stderr)
            raise SystemExit(1)
        actual = output_path.read_text(encoding="utf-8")
        if actual != expected:
            print(
                f"Coverage goals catalog is stale: {output_path}. "
                "Regenerate with scripts/generate-coverage-goals.*",
                file=sys.stderr,
            )
            raise SystemExit(1)
        print(f"Coverage goals catalog is up to date: {args.output}")
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(expected, encoding="utf-8")
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
