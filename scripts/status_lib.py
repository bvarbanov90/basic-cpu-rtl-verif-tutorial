from __future__ import annotations

import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[1]
STATUS_PASS = "PASS"
STATUS_FAIL = "FAIL"
STATUS_MISSING = "MISSING"
STATUS_PARTIAL = "PARTIAL"


def project_now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def relpath(path: Path) -> str:
    try:
        return path.resolve().relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return str(path)


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


def aggregate_status(statuses: list[str]) -> str:
    normalized = [status for status in statuses if status]
    if not normalized:
        return STATUS_MISSING
    if any(status == STATUS_FAIL for status in normalized):
        return STATUS_FAIL
    if all(status == STATUS_PASS for status in normalized):
        return STATUS_PASS
    if all(status == STATUS_MISSING for status in normalized):
        return STATUS_MISSING
    return STATUS_PARTIAL


def badge_color(status: str) -> str:
    if status == STATUS_PASS:
        return "brightgreen"
    if status == STATUS_FAIL:
        return "red"
    if status == STATUS_PARTIAL:
        return "yellow"
    return "lightgrey"


def badge_payload(label: str, message: str, status: str) -> dict[str, Any]:
    return {
        "schemaVersion": 1,
        "label": label,
        "message": message,
        "color": badge_color(status),
    }


def parse_elapsed_seconds(text: str) -> int | None:
    matches = re.findall(r"##\s+([0-9]+):([0-9]{2}):([0-9]{2})", text)
    if not matches:
        matches = re.findall(r"Elapsed clock time \[H:MM:SS \(secs\)\]: ([0-9]+):([0-9]{2}):([0-9]{2})", text)
    if not matches:
        return None
    values = [int(hours) * 3600 + int(minutes) * 60 + int(seconds) for hours, minutes, seconds in matches]
    return max(values, default=None)


def format_elapsed(seconds: int | None) -> str | None:
    if seconds is None:
        return None
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    return f"{hours}:{minutes:02d}:{secs:02d}"


def parse_solver(text: str) -> str | None:
    match = re.search(r"Solver:\s+([^\s]+)", text)
    if match:
        return match.group(1)
    return None


def read_first_existing(paths: list[Path]) -> str | None:
    for path in paths:
        if path.exists():
            return path.read_text(encoding="utf-8", errors="replace")
    return None


def formal_target_status(target_dir: Path) -> dict[str, Any]:
    target_dir = target_dir.resolve()
    payload: dict[str, Any] = {
        "name": target_dir.name,
        "path": relpath(target_dir),
        "status": STATUS_MISSING,
    }

    status_file = target_dir / "status"
    pass_file = target_dir / "PASS"
    fail_file = target_dir / "FAIL"
    raw_status = None
    if status_file.exists():
        raw_status = status_file.read_text(encoding="utf-8", errors="replace").strip()
        if raw_status:
            token = raw_status.split()[0].upper()
            if token in {STATUS_PASS, STATUS_FAIL}:
                payload["status"] = token
            else:
                payload["status"] = STATUS_PARTIAL
    elif pass_file.exists():
        payload["status"] = STATUS_PASS
    elif fail_file.exists():
        payload["status"] = STATUS_FAIL

    log_text = read_first_existing([target_dir / "logfile.txt", target_dir / "engine_0" / "logfile.txt"])
    if log_text:
        payload["solver"] = parse_solver(log_text)
        payload["elapsed"] = format_elapsed(parse_elapsed_seconds(log_text))
        if payload["status"] == STATUS_MISSING:
            if "DONE (PASS" in log_text:
                payload["status"] = STATUS_PASS
            elif "DONE (FAIL" in log_text:
                payload["status"] = STATUS_FAIL

    if raw_status:
        payload["raw_status"] = raw_status
    return payload


def summarize_formal(target_dirs: list[Path]) -> dict[str, Any]:
    targets = [formal_target_status(path) for path in target_dirs]
    statuses = [target["status"] for target in targets]
    passed = sum(1 for status in statuses if status == STATUS_PASS)
    return {
        "status": aggregate_status(statuses),
        "passed": passed,
        "total": len(targets),
        "targets": targets,
    }


def coverage_summary(path: Path, kind: str) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "path": relpath(path),
        "status": STATUS_MISSING,
        "required": kind in {"core", "mmio"},
    }
    if not path.exists():
        return payload

    report = load_json(path)
    payload["status"] = STATUS_PASS if int(report.get("coverage_pass", 0)) else STATUS_FAIL
    if kind == "core":
        opcode_hits = report.get("opcode_hits", {})
        payload.update(
            {
                "program_runs": int(report.get("program_runs", 0)),
                "total_cycles": int(report.get("total_cycles", 0)),
                "opcode_hits": sum(int(value) for value in opcode_hits.values()),
                "coverage_pass": int(report.get("coverage_pass", 0)),
            }
        )
    elif kind == "mmio":
        payload.update(
            {
                "program_runs": int(report.get("program_runs", 0)),
                "shadow_writes": int(report.get("shadow_writes", 0)),
                "shadow_reads": int(report.get("shadow_reads", 0)),
                "status_reads": int(report.get("status_reads", 0)),
                "coverage_pass": int(report.get("coverage_pass", 0)),
            }
        )
    elif kind == "pyuvm":
        opcode_hits = report.get("opcode_hits", {})
        payload["required"] = False
        payload.update(
            {
                "program_runs": int(report.get("program_runs", 0)),
                "total_cycles": int(report.get("total_cycles", 0)),
                "opcode_hits": sum(int(value) for value in opcode_hits.values()),
                "coverage_pass": int(report.get("coverage_pass", 0)),
            }
        )
    return payload


def mutation_summary(path: Path) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "path": relpath(path),
        "status": STATUS_MISSING,
        "required": False,
    }
    if not path.exists():
        return payload

    report = load_json(path)
    total = int(report.get("total_mutations", 0))
    killed = sum(int(mutation.get("mutation_pass", 0)) for mutation in report.get("mutations", []))
    payload.update(
        {
            "status": STATUS_PASS if int(report.get("campaign_pass", 0)) else STATUS_FAIL,
            "campaign_pass": int(report.get("campaign_pass", 0)),
            "total_mutations": total,
            "killed_mutations": killed,
        }
    )
    return payload


def verilator_coverage_summary(path: Path) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "path": relpath(path),
        "status": STATUS_MISSING,
        "required": False,
    }
    if not path.exists():
        return payload

    report = load_json(path)
    overall = report.get("categories", {}).get("overall", {})
    line = report.get("categories", {}).get("line", {})
    toggle = report.get("categories", {}).get("toggle", {})
    expr = report.get("categories", {}).get("expr", {})
    payload.update(
        {
            "status": STATUS_PASS if report.get("status") == STATUS_PASS else STATUS_FAIL,
            "overall_percent": overall.get("percent"),
            "line_percent": line.get("percent"),
            "toggle_percent": toggle.get("percent"),
            "expr_percent": expr.get("percent"),
        }
    )
    return payload


def static_analysis_summary(path: Path) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "path": relpath(path),
        "status": STATUS_MISSING,
        "required": False,
    }
    if not path.exists():
        return payload

    report = load_json(path)
    tools = report.get("tools", [])
    passed = sum(1 for tool in tools if tool.get("status") == STATUS_PASS)
    payload.update(
        {
            "status": report.get("status", STATUS_MISSING),
            "tool_count": len(tools),
            "passed_tools": passed,
            "tools": tools,
        }
    )
    return payload


def equivalence_summary(target_dir: Path) -> dict[str, Any]:
    target_dir = target_dir.resolve()
    payload: dict[str, Any] = {
        "path": relpath(target_dir),
        "status": STATUS_MISSING,
        "required": True,
    }
    if not target_dir.exists():
        return payload

    if (target_dir / "PASS").exists():
        payload["status"] = STATUS_PASS
    elif (target_dir / "FAIL").exists():
        payload["status"] = STATUS_FAIL
    else:
        payload["status"] = STATUS_PARTIAL

    log_text = read_first_existing([target_dir / "logfile.txt"])
    if log_text:
        payload["elapsed"] = format_elapsed(parse_elapsed_seconds(log_text))
        if payload["status"] == STATUS_MISSING:
            if "DONE (PASS" in log_text:
                payload["status"] = STATUS_PASS
            elif "DONE (FAIL" in log_text:
                payload["status"] = STATUS_FAIL

    summary_targets = target_dir / "summary_targets.list"
    if summary_targets.exists():
        targets = [line.strip() for line in summary_targets.read_text(encoding="utf-8").splitlines() if line.strip()]
        payload["partitions"] = len(targets)

    return payload


def history_latest(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    report = load_json(path)
    entries = report.get("entries", [])
    if not entries:
        return None
    return entries[-1]
