from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_HISTORY_PATH = PROJECT_ROOT / "docs" / "coverage-history.json"
DEFAULT_MARKDOWN_PATH = PROJECT_ROOT / "docs" / "coverage-history.md"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def run_git(*args: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None

    value = result.stdout.strip()
    return value or None


def git_dirty() -> int:
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return 0
    return int(bool(result.stdout.strip()))


def summarize_core_coverage(report: dict[str, Any]) -> dict[str, int]:
    opcode_hits = report.get("opcode_hits", {})
    return {
        "coverage_pass": int(report.get("coverage_pass", 0)),
        "opcode_hits": sum(int(value) for value in opcode_hits.values()),
        "program_runs": int(report.get("program_runs", 0)),
        "total_cycles": int(report.get("total_cycles", 0)),
        "jz_taken": int(report.get("jz_taken", 0)),
        "jz_not_taken": int(report.get("jz_not_taken", 0)),
        "illegal_opcode_hit": int(report.get("illegal_opcode_hit", 0)),
        "carry_1": int(report.get("carry_1", 0)),
        "neg_1": int(report.get("neg_1", 0)),
        "overflow_1": int(report.get("overflow_1", 0)),
    }


def summarize_mmio_coverage(report: dict[str, Any]) -> dict[str, int]:
    return {
        "coverage_pass": int(report.get("coverage_pass", 0)),
        "program_runs": int(report.get("program_runs", 0)),
        "external_program_runs": int(report.get("external_program_runs", 0)),
        "shadow_writes": int(report.get("shadow_writes", 0)),
        "shadow_reads": int(report.get("shadow_reads", 0)),
        "dmem_reads": int(report.get("dmem_reads", 0)),
        "status_reads": int(report.get("status_reads", 0)),
        "acc_reads": int(report.get("acc_reads", 0)),
        "pc_reads": int(report.get("pc_reads", 0)),
        "control_start_writes": int(report.get("control_start_writes", 0)),
        "control_stop_writes": int(report.get("control_stop_writes", 0)),
    }


def summarize_mmio_wait_coverage(report: dict[str, Any]) -> dict[str, int]:
    return {
        "coverage_pass": int(report.get("coverage_pass", 0)),
        "program_runs": int(report.get("program_runs", 0)),
        "external_program_runs": int(report.get("external_program_runs", 0)),
        "shadow_writes": int(report.get("shadow_writes", 0)),
        "shadow_reads": int(report.get("shadow_reads", 0)),
        "status_reads": int(report.get("status_reads", 0)),
        "wait_transactions": int(report.get("wait_transactions", 0)),
        "wait_cycles": int(report.get("wait_cycles", 0)),
        "max_wait_observed": int(report.get("max_wait_observed", 0)),
    }


def summarize_apb_coverage(report: dict[str, Any]) -> dict[str, int]:
    return {
        "coverage_pass": int(report.get("coverage_pass", 0)),
        "program_runs": int(report.get("program_runs", 0)),
        "external_program_runs": int(report.get("external_program_runs", 0)),
        "shadow_writes": int(report.get("shadow_writes", 0)),
        "shadow_reads": int(report.get("shadow_reads", 0)),
        "status_reads": int(report.get("status_reads", 0)),
        "setup_phases": int(report.get("setup_phases", 0)),
        "access_phases": int(report.get("access_phases", 0)),
    }


def load_history(path: Path) -> dict[str, Any]:
    if path.exists():
        data = load_json(path)
        if isinstance(data, dict) and "entries" in data:
            return data
    return {"version": 1, "entries": []}


def short_label(entry: dict[str, Any]) -> str:
    timestamp = entry.get("timestamp_utc", "unknown-time")
    commit = entry.get("git_commit") or "no-git"
    label = entry.get("label") or "snapshot"
    return f"{timestamp} {commit} {label}"


def bar(value: int, max_value: int, width: int = 28) -> str:
    if value <= 0 or max_value <= 0:
        return ""
    cells = max(1, round((value / max_value) * width))
    return "#" * cells


def render_trend_block(entries: list[dict[str, Any]], section: str, metric: str, title: str) -> list[str]:
    values = [int(entry.get(section, {}).get(metric, 0)) for entry in entries]
    max_value = max(values, default=0)
    lines = [title]
    if not entries:
        lines.append("  no data")
        return lines

    for index, (entry, value) in enumerate(zip(entries, values), start=1):
        lines.append(f"[{index:02d}] {bar(value, max_value):<28} {value:>6}  {short_label(entry)}")
    return lines


def render_markdown(history: dict[str, Any], limit: int) -> str:
    entries = history.get("entries", [])[-limit:]
    lines: list[str] = [
        "# Coverage History",
        "",
        "Generated by `python scripts/coverage_history.py snapshot` after a passing regression run.",
        "",
        "## Recent Snapshots",
        "",
        "| # | Timestamp UTC | Commit | Dirty | Label | Core pass | Core runs | Core cycles | MMIO pass | MMIO runs | MMIO-wait pass | MMIO-wait runs | APB pass | APB runs |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]

    if not entries:
        lines.append("| - | - | - | - | - | - | - | - | - | - | - | - | - | - |")
    else:
        for index, entry in enumerate(entries, start=1):
            core = entry.get("core", {})
            mmio = entry.get("mmio", {})
            mmio_wait = entry.get("mmio_wait", {})
            apb = entry.get("apb", {})
            lines.append(
                "| {index} | {timestamp} | {commit} | {dirty} | {label} | {core_pass} | {core_runs} | {core_cycles} | {mmio_pass} | {mmio_runs} | {mmio_wait_pass} | {mmio_wait_runs} | {apb_pass} | {apb_runs} |".format(
                    index=index,
                    timestamp=entry.get("timestamp_utc", "-"),
                    commit=entry.get("git_commit") or "-",
                    dirty=entry.get("git_dirty", 0),
                    label=entry.get("label") or "-",
                    core_pass=core.get("coverage_pass", "-"),
                    core_runs=core.get("program_runs", "-"),
                    core_cycles=core.get("total_cycles", "-"),
                    mmio_pass=mmio.get("coverage_pass", "-"),
                    mmio_runs=mmio.get("program_runs", "-"),
                    mmio_wait_pass=mmio_wait.get("coverage_pass", "-"),
                    mmio_wait_runs=mmio_wait.get("program_runs", "-"),
                    apb_pass=apb.get("coverage_pass", "-"),
                    apb_runs=apb.get("program_runs", "-"),
                )
            )

    lines.extend(
        [
            "",
            "## Core Trends",
            "",
            "```text",
            *render_trend_block(entries, "core", "program_runs", "program_runs"),
            "",
            *render_trend_block(entries, "core", "total_cycles", "total_cycles"),
            "",
            *render_trend_block(entries, "core", "overflow_1", "overflow_1"),
            "```",
            "",
            "## MMIO Trends",
            "",
            "```text",
            *render_trend_block(entries, "mmio", "program_runs", "program_runs"),
            "",
            *render_trend_block(entries, "mmio", "shadow_writes", "shadow_writes"),
            "",
            *render_trend_block(entries, "mmio", "status_reads", "status_reads"),
            "```",
            "",
            "## APB Trends",
            "",
            "```text",
            *render_trend_block(entries, "apb", "program_runs", "program_runs"),
            "",
            *render_trend_block(entries, "apb", "setup_phases", "setup_phases"),
            "",
            *render_trend_block(entries, "apb", "access_phases", "access_phases"),
            "```",
            "",
            "## MMIO-wait Trends",
            "",
            "```text",
            *render_trend_block(entries, "mmio_wait", "program_runs", "program_runs"),
            "",
            *render_trend_block(entries, "mmio_wait", "wait_transactions", "wait_transactions"),
            "",
            *render_trend_block(entries, "mmio_wait", "wait_cycles", "wait_cycles"),
            "```",
            "",
        ]
    )
    return "\n".join(lines)


def render_terminal_report(history: dict[str, Any], limit: int) -> str:
    entries = history.get("entries", [])[-limit:]
    lines = [f"Coverage trend report (last {len(entries)} snapshots)"]
    if not entries:
        lines.append("  no snapshots recorded")
        return "\n".join(lines)

    for index, entry in enumerate(entries, start=1):
        core = entry.get("core", {})
        mmio = entry.get("mmio", {})
        mmio_wait = entry.get("mmio_wait", {})
        apb = entry.get("apb", {})
        lines.append(
            "[{index:02d}] {label} commit={commit} dirty={dirty} core(pass={core_pass}, runs={core_runs}, cycles={core_cycles}, opcodes={opcode_hits}) mmio(pass={mmio_pass}, runs={mmio_runs}) mmio_wait(pass={mmio_wait_pass}, runs={mmio_wait_runs}, waits={wait_transactions}) apb(pass={apb_pass}, runs={apb_runs})".format(
                index=index,
                label=short_label(entry),
                commit=entry.get("git_commit") or "no-git",
                dirty=entry.get("git_dirty", 0),
                core_pass=core.get("coverage_pass", 0),
                core_runs=core.get("program_runs", 0),
                core_cycles=core.get("total_cycles", 0),
                opcode_hits=core.get("opcode_hits", 0),
                mmio_pass=mmio.get("coverage_pass", 0),
                mmio_runs=mmio.get("program_runs", 0),
                mmio_wait_pass=mmio_wait.get("coverage_pass", 0),
                mmio_wait_runs=mmio_wait.get("program_runs", 0),
                wait_transactions=mmio_wait.get("wait_transactions", 0),
                apb_pass=apb.get("coverage_pass", 0),
                apb_runs=apb.get("program_runs", 0),
            )
        )

    lines.append("")
    lines.extend(render_trend_block(entries, "core", "program_runs", "Core program_runs"))
    lines.append("")
    lines.extend(render_trend_block(entries, "core", "total_cycles", "Core total_cycles"))
    lines.append("")
    lines.extend(render_trend_block(entries, "mmio", "program_runs", "MMIO program_runs"))
    lines.append("")
    lines.extend(render_trend_block(entries, "mmio_wait", "program_runs", "MMIO-wait program_runs"))
    lines.append("")
    lines.extend(render_trend_block(entries, "apb", "program_runs", "APB program_runs"))
    return "\n".join(lines)


def snapshot(args: argparse.Namespace) -> int:
    history_path = Path(args.history).resolve()
    markdown_path = Path(args.markdown).resolve()
    history = load_history(history_path)

    core_report = load_json(Path(args.core).resolve())
    mmio_path = Path(args.mmio).resolve() if args.mmio else None
    mmio_wait_path = Path(args.mmio_wait).resolve() if args.mmio_wait else None
    apb_path = Path(args.apb).resolve() if args.apb else None
    mmio_report = load_json(mmio_path) if mmio_path and mmio_path.exists() else {}
    mmio_wait_report = load_json(mmio_wait_path) if mmio_wait_path and mmio_wait_path.exists() else {}
    apb_report = load_json(apb_path) if apb_path and apb_path.exists() else {}

    entry = {
        "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "label": args.label,
        "git_commit": run_git("rev-parse", "--short", "HEAD"),
        "git_branch": run_git("rev-parse", "--abbrev-ref", "HEAD"),
        "git_dirty": git_dirty(),
        "core": summarize_core_coverage(core_report),
        "mmio": summarize_mmio_coverage(mmio_report) if mmio_report else {},
        "mmio_wait": summarize_mmio_wait_coverage(mmio_wait_report) if mmio_wait_report else {},
        "apb": summarize_apb_coverage(apb_report) if apb_report else {},
    }

    entries = history.setdefault("entries", [])
    if entries:
        latest = entries[-1]
        same_identity = (
            latest.get("label") == entry["label"]
            and latest.get("git_commit") == entry["git_commit"]
            and latest.get("git_dirty") == entry["git_dirty"]
            and latest.get("core") == entry["core"]
            and latest.get("mmio") == entry["mmio"]
            and latest.get("mmio_wait") == entry["mmio_wait"]
            and latest.get("apb") == entry["apb"]
        )
        if same_identity:
            entries[-1] = entry
        else:
            entries.append(entry)
    else:
        entries.append(entry)

    if args.max_entries > 0 and len(entries) > args.max_entries:
        history["entries"] = entries[-args.max_entries :]

    write_json(history_path, history)
    markdown_path.parent.mkdir(parents=True, exist_ok=True)
    markdown_path.write_text(render_markdown(history, args.limit), encoding="utf-8")

    print(f"[COVERAGE-HISTORY] updated {history_path.relative_to(PROJECT_ROOT)}")
    print(f"[COVERAGE-HISTORY] updated {markdown_path.relative_to(PROJECT_ROOT)}")
    return 0


def report(args: argparse.Namespace) -> int:
    history_path = Path(args.history).resolve()
    if not history_path.exists():
        raise FileNotFoundError(f"Coverage history file not found: {history_path}")
    history = load_history(history_path)
    print(render_terminal_report(history, args.limit))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Record and report core/MMIO/MMIO-wait/APB coverage history.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    snapshot_parser = subparsers.add_parser("snapshot", help="Append or refresh a coverage history snapshot.")
    snapshot_parser.add_argument("--core", default=str(PROJECT_ROOT / "sim_build" / "coverage.json"))
    snapshot_parser.add_argument("--mmio", default=str(PROJECT_ROOT / "sim_build" / "mmio_coverage.json"))
    snapshot_parser.add_argument("--mmio-wait", default=str(PROJECT_ROOT / "sim_build" / "mmio_wait_coverage.json"))
    snapshot_parser.add_argument("--apb", default=str(PROJECT_ROOT / "sim_build" / "apb_coverage.json"))
    snapshot_parser.add_argument("--history", default=str(DEFAULT_HISTORY_PATH))
    snapshot_parser.add_argument("--markdown", default=str(DEFAULT_MARKDOWN_PATH))
    snapshot_parser.add_argument("--label", default="tutorial-regression")
    snapshot_parser.add_argument("--limit", type=int, default=12, help="Number of entries to render into markdown.")
    snapshot_parser.add_argument("--max-entries", type=int, default=64, help="Maximum entries to retain in the history file.")
    snapshot_parser.set_defaults(func=snapshot)

    report_parser = subparsers.add_parser("report", help="Print the tracked coverage trend report.")
    report_parser.add_argument("--history", default=str(DEFAULT_HISTORY_PATH))
    report_parser.add_argument("--limit", type=int, default=12)
    report_parser.set_defaults(func=report)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
