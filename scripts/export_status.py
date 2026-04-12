from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

from status_lib import (
    PROJECT_ROOT,
    STATUS_PASS,
    aggregate_status,
    badge_payload,
    coverage_summary,
    equivalence_summary,
    git_dirty,
    history_latest,
    junit_summary,
    mutation_summary,
    project_now_utc,
    relpath,
    run_git,
    summarize_formal,
    static_analysis_summary,
    verilator_coverage_summary,
    write_json,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export repo-tracked verification status markdown/json/badges.")
    parser.add_argument("--core", default="sim_build/coverage.json", help="Core coverage JSON path.")
    parser.add_argument("--mmio", default="sim_build/mmio_coverage.json", help="MMIO coverage JSON path.")
    parser.add_argument(
        "--mmio-wait",
        default="sim_build/mmio_wait_coverage.json",
        help="MMIO wait-state coverage JSON path.",
    )
    parser.add_argument("--apb", default="sim_build/apb_coverage.json", help="APB coverage JSON path.")
    parser.add_argument(
        "--apb-fault",
        default="sim_build/apb_fault_coverage.json",
        help="APB fault-coverage JSON path.",
    )
    parser.add_argument("--pyuvm", default="sim_build/pyuvm_coverage.json", help="pyuvm coverage JSON path.")
    parser.add_argument(
        "--cocotb-verilator",
        default="sim_build/verilator_results.xml",
        help="Core cocotb-Verilator JUnit XML path.",
    )
    parser.add_argument(
        "--mmio-cocotb",
        default="sim_build/mmio_cocotb_results.xml",
        help="MMIO cocotb JUnit XML path.",
    )
    parser.add_argument(
        "--mmio-pyuvm",
        default="sim_build/mmio_uvm_results.xml",
        help="MMIO pyuvm JUnit XML path.",
    )
    parser.add_argument(
        "--mmio-wait-cocotb",
        default="sim_build/mmio_wait_cocotb_results.xml",
        help="MMIO wait-state cocotb JUnit XML path.",
    )
    parser.add_argument(
        "--mmio-wait-pyuvm",
        default="sim_build/mmio_wait_uvm_results.xml",
        help="MMIO wait-state pyuvm JUnit XML path.",
    )
    parser.add_argument(
        "--apb-cocotb",
        default="sim_build/apb_cocotb_results.xml",
        help="APB cocotb JUnit XML path.",
    )
    parser.add_argument(
        "--apb-pyuvm",
        default="sim_build/apb_uvm_results.xml",
        help="APB pyuvm JUnit XML path.",
    )
    parser.add_argument(
        "--mutations",
        default="sim_build/mutations/mutation_summary.json",
        help="Mutation summary JSON path.",
    )
    parser.add_argument(
        "--verilator-coverage",
        default="sim_build/verilator_coverage/summary.json",
        help="Verilator coverage summary JSON path.",
    )
    parser.add_argument(
        "--equivalence",
        default="equiv/simple_cpu_eqy",
        help="EQY work directory to inspect.",
    )
    parser.add_argument(
        "--static-analysis",
        default="sim_build/static_analysis/summary.json",
        help="Static-analysis summary JSON path.",
    )
    parser.add_argument(
        "--history",
        default="docs/coverage-history.json",
        help="Coverage history JSON path for the latest tracked snapshot.",
    )
    parser.add_argument(
        "--formal-target",
        action="append",
        dest="formal_targets",
        default=[],
        help="Formal output directory to inspect. Repeat for multiple targets.",
    )
    parser.add_argument(
        "--status-json",
        default="docs/status/status.json",
        help="Output JSON status snapshot.",
    )
    parser.add_argument(
        "--status-markdown",
        default="docs/status/status.md",
        help="Output Markdown status snapshot.",
    )
    parser.add_argument(
        "--badge-dir",
        default="docs/status/badges",
        help="Output directory for shields.io endpoint JSON files.",
    )
    parser.add_argument("--label", default="", help="Optional label describing the current snapshot.")
    return parser.parse_args()


def format_domain_details(name: str, payload: dict[str, Any]) -> str:
    status = payload["status"]
    if name == "core":
        if status == "MISSING":
            return "artifact missing"
        return "program_runs={runs}, total_cycles={cycles}, opcode_hits={hits}".format(
            runs=payload.get("program_runs", 0),
            cycles=payload.get("total_cycles", 0),
            hits=payload.get("opcode_hits", 0),
        )
    if name == "mmio":
        if status == "MISSING":
            return "artifact missing"
        return "program_runs={runs}, shadow_writes={writes}, status_reads={reads}".format(
            runs=payload.get("program_runs", 0),
            writes=payload.get("shadow_writes", 0),
            reads=payload.get("status_reads", 0),
        )
    if name == "mmio_wait":
        if status == "MISSING":
            return "artifact missing"
        return "program_runs={runs}, wait_transactions={transactions}, wait_cycles={cycles}, max_wait={max_wait}".format(
            runs=payload.get("program_runs", 0),
            transactions=payload.get("wait_transactions", 0),
            cycles=payload.get("wait_cycles", 0),
            max_wait=payload.get("max_wait_observed", 0),
        )
    if name == "apb":
        if status == "MISSING":
            return "artifact missing"
        return "program_runs={runs}, shadow_writes={writes}, setup_phases={setup}, access_phases={access}".format(
            runs=payload.get("program_runs", 0),
            writes=payload.get("shadow_writes", 0),
            setup=payload.get("setup_phases", 0),
            access=payload.get("access_phases", 0),
        )
    if name == "apb_fault":
        if status == "MISSING":
            return "artifact missing"
        return "fault_cases={faults}, deferred_updates={deferred}, reload_updates={reloads}, readbacks={readbacks}".format(
            faults=(
                payload.get("setup_only_writes_ignored", 0)
                + payload.get("aborted_writes_ignored", 0)
                + payload.get("setup_only_starts_ignored", 0)
                + payload.get("penable_without_select_ignored", 0)
            ),
            deferred=payload.get("deferred_shadow_updates", 0),
            reloads=payload.get("reload_observed_updates", 0),
            readbacks=payload.get("fault_readbacks", 0),
        )
    if name == "pyuvm":
        if status == "MISSING":
            return "artifact missing"
        return "program_runs={runs}, total_cycles={cycles}, opcode_hits={hits}".format(
            runs=payload.get("program_runs", 0),
            cycles=payload.get("total_cycles", 0),
            hits=payload.get("opcode_hits", 0),
        )
    if name in {
        "cocotb_verilator",
        "mmio_cocotb",
        "mmio_pyuvm",
        "mmio_wait_cocotb",
        "mmio_wait_pyuvm",
        "apb_cocotb",
        "apb_pyuvm",
    }:
        if status == "MISSING":
            return "artifact missing"
        return "tests={tests}, failures={failures}, errors={errors}, skipped={skipped}".format(
            tests=payload.get("tests", 0),
            failures=payload.get("failures", 0),
            errors=payload.get("errors", 0),
            skipped=payload.get("skipped", 0),
        )
    if name == "mutations":
        if status == "MISSING":
            return "artifact missing"
        return "killed_mutations={killed}/{total}".format(
            killed=payload.get("killed_mutations", 0),
            total=payload.get("total_mutations", 0),
        )
    if name == "verilator":
        if status == "MISSING":
            return "artifact missing"
        return "overall={overall}%, line={line}%, toggle={toggle}%, expr={expr}%".format(
            overall=payload.get("overall_percent", "-"),
            line=payload.get("line_percent", "-"),
            toggle=payload.get("toggle_percent", "-"),
            expr=payload.get("expr_percent", "-"),
        )
    if name == "equivalence":
        if status == "MISSING":
            return "artifact missing"
        return "partitions={partitions}, elapsed={elapsed}".format(
            partitions=payload.get("partitions", 0),
            elapsed=payload.get("elapsed", "-"),
        )
    if name == "static_analysis":
        if status == "MISSING":
            return "artifact missing"
        return "tools={passed}/{count}".format(
            passed=payload.get("passed_tools", 0),
            count=payload.get("tool_count", 0),
        )
    if name == "formal":
        targets = payload.get("targets", [])
        if not targets:
            return "artifact missing"
        fragments = []
        for target in targets:
            fragments.append(
                "{name}:{status} solver={solver} elapsed={elapsed}".format(
                    name=target.get("name", "unknown"),
                    status=target.get("status", "MISSING"),
                    solver=target.get("solver", "-"),
                    elapsed=target.get("elapsed", "-"),
                )
            )
        return "; ".join(fragments)
    return ""


def render_markdown(status: dict[str, Any]) -> str:
    lines = [
        "# Verification Status",
        "",
        f"Generated UTC: `{status['generated_utc']}`",
        "",
        "| Field | Value |",
        "|---|---|",
        f"| Label | {status.get('label') or '-'} |",
        f"| Git branch | `{status.get('git_branch') or '-'}` |",
        f"| Git commit | `{status.get('git_commit') or '-'}` |",
        f"| Git dirty | `{status.get('git_dirty', 0)}` |",
        f"| Overall required-suite status | `{status['overall_required_status']}` |",
        "",
        "Required suites are `core_coverage`, `mmio_coverage`, `formal`, and `equivalence`. Optional suites are reported separately.",
        "",
        "## Suite Summary",
        "",
        "| Suite | Required | Status | Details | Source |",
        "|---|---|---|---|---|",
    ]

    suite_order = [
        ("core_coverage", "core"),
        ("mmio_coverage", "mmio"),
        ("mmio_wait_coverage", "mmio_wait"),
        ("apb_coverage", "apb"),
        ("apb_fault_coverage", "apb_fault"),
        ("formal", "formal"),
        ("equivalence", "equivalence"),
        ("static_analysis", "static_analysis"),
        ("pyuvm_coverage", "pyuvm"),
        ("cocotb_verilator", "cocotb_verilator"),
        ("mmio_cocotb", "mmio_cocotb"),
        ("mmio_pyuvm", "mmio_pyuvm"),
        ("mmio_wait_cocotb", "mmio_wait_cocotb"),
        ("mmio_wait_pyuvm", "mmio_wait_pyuvm"),
        ("apb_cocotb", "apb_cocotb"),
        ("apb_pyuvm", "apb_pyuvm"),
        ("verilator_coverage", "verilator"),
        ("mutations", "mutations"),
    ]
    for key, name in suite_order:
        payload = status[key]
        lines.append(
            "| {suite} | {required} | `{state}` | {details} | `{source}` |".format(
                suite=key,
                required="yes" if payload.get("required", key in {"core_coverage", "mmio_coverage", "formal", "equivalence"}) else "no",
                state=payload["status"],
                details=format_domain_details(name, payload),
                source=payload.get("path", "-"),
            )
        )

    formal_targets = status["formal"].get("targets", [])
    if formal_targets:
        lines.extend(
            [
                "",
                "## Formal Targets",
                "",
                "| Target | Status | Solver | Elapsed | Path |",
                "|---|---|---|---|---|",
            ]
        )
        for target in formal_targets:
            lines.append(
                "| {name} | `{status}` | `{solver}` | `{elapsed}` | `{path}` |".format(
                    name=target.get("name", "unknown"),
                    status=target.get("status", "MISSING"),
                    solver=target.get("solver", "-"),
                    elapsed=target.get("elapsed", "-"),
                    path=target.get("path", "-"),
                )
            )

    latest_history = status.get("latest_history")
    if latest_history:
        lines.extend(
            [
                "",
                "## Latest Coverage History Snapshot",
                "",
                "| Field | Value |",
                "|---|---|",
                f"| Timestamp UTC | `{latest_history.get('timestamp_utc', '-')}` |",
                f"| Label | {latest_history.get('label', '-')} |",
                f"| Commit | `{latest_history.get('git_commit', '-')}` |",
                f"| Dirty | `{latest_history.get('git_dirty', 0)}` |",
            ]
        )

    lines.extend(
        [
            "",
            "## Badge Endpoints",
            "",
            "Generated shields-compatible endpoint JSON files:",
            "",
        ]
    )
    for badge_name in sorted(status.get("badges", {})):
        lines.append(f"1. `{status['badges'][badge_name]['path']}`")

    return "\n".join(lines) + "\n"


def build_badges(status: dict[str, Any], badge_dir: Path) -> dict[str, dict[str, Any]]:
    badge_specs = {
        "overall": (
            "required suite",
            status["overall_required_status"],
            status["overall_required_status"],
        ),
        "core-coverage": (
            "core coverage",
            "PASS {runs} runs".format(runs=status["core_coverage"].get("program_runs", 0))
            if status["core_coverage"]["status"] == STATUS_PASS
            else status["core_coverage"]["status"],
            status["core_coverage"]["status"],
        ),
        "mmio-coverage": (
            "mmio coverage",
            "PASS {runs} runs".format(runs=status["mmio_coverage"].get("program_runs", 0))
            if status["mmio_coverage"]["status"] == STATUS_PASS
            else status["mmio_coverage"]["status"],
            status["mmio_coverage"]["status"],
        ),
        "mmio-wait-coverage": (
            "mmio wait coverage",
            "PASS {runs} runs".format(runs=status["mmio_wait_coverage"].get("program_runs", 0))
            if status["mmio_wait_coverage"]["status"] == STATUS_PASS
            else status["mmio_wait_coverage"]["status"],
            status["mmio_wait_coverage"]["status"],
        ),
        "apb-coverage": (
            "apb coverage",
            "PASS {runs} runs".format(runs=status["apb_coverage"].get("program_runs", 0))
            if status["apb_coverage"]["status"] == STATUS_PASS
            else status["apb_coverage"]["status"],
            status["apb_coverage"]["status"],
        ),
        "apb-fault-coverage": (
            "apb fault",
            "PASS {cases} cases".format(
                cases=(
                    status["apb_fault_coverage"].get("setup_only_writes_ignored", 0)
                    + status["apb_fault_coverage"].get("aborted_writes_ignored", 0)
                    + status["apb_fault_coverage"].get("setup_only_starts_ignored", 0)
                    + status["apb_fault_coverage"].get("penable_without_select_ignored", 0)
                )
            )
            if status["apb_fault_coverage"]["status"] == STATUS_PASS
            else status["apb_fault_coverage"]["status"],
            status["apb_fault_coverage"]["status"],
        ),
        "formal": (
            "formal",
            "{passed}/{total} PASS".format(
                passed=status["formal"].get("passed", 0),
                total=status["formal"].get("total", 0),
            )
            if status["formal"]["status"] == STATUS_PASS
            else status["formal"]["status"],
            status["formal"]["status"],
        ),
        "pyuvm": (
            "pyuvm",
            "PASS {runs} runs".format(runs=status["pyuvm_coverage"].get("program_runs", 0))
            if status["pyuvm_coverage"]["status"] == STATUS_PASS
            else status["pyuvm_coverage"]["status"],
            status["pyuvm_coverage"]["status"],
        ),
        "cocotb-verilator": (
            "cocotb verilator",
            "PASS {tests} tests".format(tests=status["cocotb_verilator"].get("tests", 0))
            if status["cocotb_verilator"]["status"] == STATUS_PASS
            else status["cocotb_verilator"]["status"],
            status["cocotb_verilator"]["status"],
        ),
        "mmio-cocotb": (
            "mmio cocotb",
            "PASS {tests} tests".format(tests=status["mmio_cocotb"].get("tests", 0))
            if status["mmio_cocotb"]["status"] == STATUS_PASS
            else status["mmio_cocotb"]["status"],
            status["mmio_cocotb"]["status"],
        ),
        "mmio-pyuvm": (
            "mmio pyuvm",
            "PASS {tests} tests".format(tests=status["mmio_pyuvm"].get("tests", 0))
            if status["mmio_pyuvm"]["status"] == STATUS_PASS
            else status["mmio_pyuvm"]["status"],
            status["mmio_pyuvm"]["status"],
        ),
        "mmio-wait-cocotb": (
            "mmio wait cocotb",
            "PASS {tests} tests".format(tests=status["mmio_wait_cocotb"].get("tests", 0))
            if status["mmio_wait_cocotb"]["status"] == STATUS_PASS
            else status["mmio_wait_cocotb"]["status"],
            status["mmio_wait_cocotb"]["status"],
        ),
        "mmio-wait-pyuvm": (
            "mmio wait pyuvm",
            "PASS {tests} tests".format(tests=status["mmio_wait_pyuvm"].get("tests", 0))
            if status["mmio_wait_pyuvm"]["status"] == STATUS_PASS
            else status["mmio_wait_pyuvm"]["status"],
            status["mmio_wait_pyuvm"]["status"],
        ),
        "apb-cocotb": (
            "apb cocotb",
            "PASS {tests} tests".format(tests=status["apb_cocotb"].get("tests", 0))
            if status["apb_cocotb"]["status"] == STATUS_PASS
            else status["apb_cocotb"]["status"],
            status["apb_cocotb"]["status"],
        ),
        "apb-pyuvm": (
            "apb pyuvm",
            "PASS {tests} tests".format(tests=status["apb_pyuvm"].get("tests", 0))
            if status["apb_pyuvm"]["status"] == STATUS_PASS
            else status["apb_pyuvm"]["status"],
            status["apb_pyuvm"]["status"],
        ),
        "verilator-coverage": (
            "verilator cov",
            "{overall}% overall".format(overall=status["verilator_coverage"].get("overall_percent", "-"))
            if status["verilator_coverage"]["status"] == STATUS_PASS
            else status["verilator_coverage"]["status"],
            status["verilator_coverage"]["status"],
        ),
        "equivalence": (
            "equivalence",
            "PASS {partitions} partitions".format(partitions=status["equivalence"].get("partitions", 0))
            if status["equivalence"]["status"] == STATUS_PASS
            else status["equivalence"]["status"],
            status["equivalence"]["status"],
        ),
        "static-analysis": (
            "static analysis",
            "{passed}/{count} PASS".format(
                passed=status["static_analysis"].get("passed_tools", 0),
                count=status["static_analysis"].get("tool_count", 0),
            )
            if status["static_analysis"]["status"] == STATUS_PASS
            else status["static_analysis"]["status"],
            status["static_analysis"]["status"],
        ),
        "mutations": (
            "mutations",
            "{killed}/{total} killed".format(
                killed=status["mutations"].get("killed_mutations", 0),
                total=status["mutations"].get("total_mutations", 0),
            )
            if status["mutations"]["status"] == STATUS_PASS
            else status["mutations"]["status"],
            status["mutations"]["status"],
        ),
    }

    badges: dict[str, dict[str, Any]] = {}
    for filename, (label, message, badge_status) in badge_specs.items():
        path = badge_dir / f"{filename}.json"
        write_json(path, badge_payload(label, message, badge_status))
        badges[filename] = {
            "path": relpath(path),
            "label": label,
            "message": message,
            "status": badge_status,
        }

    for target in status["formal"].get("targets", []):
        filename = f"formal-{target['name']}.json"
        message = target["status"]
        if target["status"] == STATUS_PASS:
            solver = target.get("solver") or "solver?"
            elapsed = target.get("elapsed") or "-"
            message = f"PASS {solver} {elapsed}"
        path = badge_dir / filename
        write_json(path, badge_payload(f"formal {target['name']}", message, target["status"]))
        badges[filename[:-5]] = {
            "path": relpath(path),
            "label": f"formal {target['name']}",
            "message": message,
            "status": target["status"],
        }

    return badges


def main() -> int:
    args = parse_args()
    formal_targets = args.formal_targets or [
        "formal/simple_cpu",
        "formal/simple_cpu_mmio",
        "formal/simple_cpu_mmio_wait",
        "formal/simple_cpu_apb",
        "formal/simple_cpu_cover",
        "formal/simple_cpu_mmio_cover",
        "formal/simple_cpu_mmio_wait_cover",
        "formal/simple_cpu_apb_cover",
    ]

    core = coverage_summary(Path(args.core).resolve(), "core")
    mmio = coverage_summary(Path(args.mmio).resolve(), "mmio")
    mmio_wait = coverage_summary(Path(args.mmio_wait).resolve(), "mmio_wait")
    apb = coverage_summary(Path(args.apb).resolve(), "apb")
    apb_fault = coverage_summary(Path(args.apb_fault).resolve(), "apb_fault")
    pyuvm = coverage_summary(Path(args.pyuvm).resolve(), "pyuvm")
    cocotb_verilator = junit_summary(Path(args.cocotb_verilator).resolve(), required=False)
    mmio_cocotb = junit_summary(Path(args.mmio_cocotb).resolve(), required=False)
    mmio_pyuvm = junit_summary(Path(args.mmio_pyuvm).resolve(), required=False)
    mmio_wait_cocotb = junit_summary(Path(args.mmio_wait_cocotb).resolve(), required=False)
    mmio_wait_pyuvm = junit_summary(Path(args.mmio_wait_pyuvm).resolve(), required=False)
    apb_cocotb = junit_summary(Path(args.apb_cocotb).resolve(), required=False)
    apb_pyuvm = junit_summary(Path(args.apb_pyuvm).resolve(), required=False)
    formal = summarize_formal([Path(target).resolve() for target in formal_targets])
    formal["required"] = True
    equivalence = equivalence_summary(Path(args.equivalence).resolve())
    static_analysis = static_analysis_summary(Path(args.static_analysis).resolve())
    verilator_coverage = verilator_coverage_summary(Path(args.verilator_coverage).resolve())
    mutations = mutation_summary(Path(args.mutations).resolve())

    required_statuses = [core["status"], mmio["status"], formal["status"], equivalence["status"]]
    overall_required_status = aggregate_status(required_statuses)

    status: dict[str, Any] = {
        "generated_utc": project_now_utc(),
        "label": args.label,
        "git_branch": run_git("rev-parse", "--abbrev-ref", "HEAD"),
        "git_commit": run_git("rev-parse", "--short", "HEAD"),
        "git_dirty": git_dirty(),
        "overall_required_status": overall_required_status,
        "core_coverage": core,
        "mmio_coverage": mmio,
        "mmio_wait_coverage": mmio_wait,
        "apb_coverage": apb,
        "apb_fault_coverage": apb_fault,
        "pyuvm_coverage": pyuvm,
        "cocotb_verilator": cocotb_verilator,
        "mmio_cocotb": mmio_cocotb,
        "mmio_pyuvm": mmio_pyuvm,
        "mmio_wait_cocotb": mmio_wait_cocotb,
        "mmio_wait_pyuvm": mmio_wait_pyuvm,
        "apb_cocotb": apb_cocotb,
        "apb_pyuvm": apb_pyuvm,
        "verilator_coverage": verilator_coverage,
        "formal": formal,
        "equivalence": equivalence,
        "static_analysis": static_analysis,
        "mutations": mutations,
    }

    latest = history_latest(Path(args.history).resolve())
    if latest:
        status["latest_history"] = latest

    badge_dir = Path(args.badge_dir).resolve()
    status["badges"] = build_badges(status, badge_dir)

    status_json = Path(args.status_json).resolve()
    status_markdown = Path(args.status_markdown).resolve()
    write_json(status_json, status)
    status_markdown.parent.mkdir(parents=True, exist_ok=True)
    status_markdown.write_text(render_markdown(status), encoding="utf-8")

    print(f"[STATUS] wrote {relpath(status_json)}")
    print(f"[STATUS] wrote {relpath(status_markdown)}")
    print(f"[STATUS] overall required-suite status: {overall_required_status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
