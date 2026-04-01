from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
STATUS_PASS = "PASS"
STATUS_FAIL = "FAIL"
STATUS_MISSING = "MISSING"

VERILATOR_FILES = [
    Path("rtl/simple_cpu.sv"),
    Path("rtl/simple_cpu_mmio.sv"),
]

VERIBLE_FILES = [
    Path("rtl/simple_cpu.sv"),
    Path("tb/simple_cpu_mmio_assertions.sv"),
    Path("tb/simple_cpu_tb.sv"),
    Path("tb/simple_cpu_mmio_tb.sv"),
    Path("formal/simple_cpu_formal.sv"),
    Path("formal/simple_cpu_mmio_formal.sv"),
    Path("formal/simple_cpu_cover_formal.sv"),
    Path("formal/simple_cpu_mmio_cover_formal.sv"),
    Path("formal/simple_cpu_mmio_stub.sv"),
    Path("equiv/simple_cpu_golden.sv"),
]

SVLINT_FILES = [
    Path("rtl/simple_cpu.sv"),
    Path("rtl/simple_cpu_mmio.sv"),
]

STATIC_ANALYSIS_NOTES = [
    "Verible is intentionally scoped to the hand-written SV set that the current release parses cleanly; rtl/simple_cpu_mmio.sv remains covered by Verilator lint and svlint.",
    "svlint is intentionally scoped to synthesizable RTL so the secondary checker stays focused on design hazards instead of tutorial bench naming/style noise.",
]


def relpath(path: Path) -> str:
    try:
        return path.resolve().relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return str(path)


def file_args(paths: list[Path]) -> list[str]:
    return [str((PROJECT_ROOT / path).resolve()) for path in paths]


def shell_join(argv: list[str]) -> str:
    return " ".join(shlex.quote(arg) for arg in argv)


def ensure_exists(path: str | None) -> str | None:
    if not path:
        return None
    resolved = Path(path)
    if not resolved.exists():
        raise FileNotFoundError(f"Required tool not found: {path}")
    return str(resolved.resolve())


def build_tool_env(command: list[str]) -> dict[str, str]:
    env = os.environ.copy()
    executable = Path(command[0])
    if executable.name.lower() == "verilator_bin.exe":
        env.setdefault("VERILATOR_ROOT", str(executable.parent.parent / "share" / "verilator"))
    return env


def run_command(command: list[str], log_path: Path) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        command,
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=build_tool_env(command),
        check=False,
    )
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("w", encoding="utf-8") as handle:
        handle.write("$ " + shell_join(command) + "\n\n")
        if result.stdout:
            handle.write("[stdout]\n")
            handle.write(result.stdout)
            if not result.stdout.endswith("\n"):
                handle.write("\n")
        if result.stderr:
            handle.write("\n[stderr]\n")
            handle.write(result.stderr)
            if not result.stderr.endswith("\n"):
                handle.write("\n")
        handle.write(f"\n[exit_code] {result.returncode}\n")
    return result


def tool_result(name: str, command: list[str], files: list[Path], logs_dir: Path) -> dict[str, Any]:
    log_path = logs_dir / f"{name}.log"
    result = run_command(command, log_path)
    return {
        "name": name,
        "status": STATUS_PASS if result.returncode == 0 else STATUS_FAIL,
        "returncode": result.returncode,
        "log": relpath(log_path),
        "command": shell_join(command),
        "files": [path.as_posix() for path in files],
    }


def format_tool_result(executable: str, files: list[Path], logs_dir: Path) -> dict[str, Any]:
    log_path = logs_dir / "verible_format.log"
    status = STATUS_PASS
    commands: list[str] = []
    combined_output: list[str] = []

    for file_path in files:
        command = [executable, "--verify", str((PROJECT_ROOT / file_path).resolve())]
        result = subprocess.run(
            command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            check=False,
        )
        commands.append(shell_join(command))
        combined_output.append("$ " + shell_join(command))
        if result.stdout:
            combined_output.append("[stdout]")
            combined_output.append(result.stdout.rstrip())
        if result.stderr:
            combined_output.append("[stderr]")
            combined_output.append(result.stderr.rstrip())
        combined_output.append(f"[exit_code] {result.returncode}")
        combined_output.append("")
        if result.returncode != 0:
            status = STATUS_FAIL

    log_path.parent.mkdir(parents=True, exist_ok=True)
    log_path.write_text("\n".join(combined_output).rstrip() + "\n", encoding="utf-8")
    return {
        "name": "verible_format",
        "status": status,
        "returncode": 0 if status == STATUS_PASS else 1,
        "log": relpath(log_path),
        "command": "\n".join(commands),
        "files": [path.as_posix() for path in files],
    }


def aggregate_status(items: list[dict[str, Any]]) -> str:
    if not items:
        return STATUS_MISSING
    if any(item["status"] == STATUS_FAIL for item in items):
        return STATUS_FAIL
    if all(item["status"] == STATUS_PASS for item in items):
        return STATUS_PASS
    return STATUS_MISSING


def render_markdown(summary: dict[str, Any]) -> str:
    lines = [
        "# Static Analysis Summary",
        "",
        f"Status: `{summary['status']}`",
        "",
        "| Tool | Status | Files | Log |",
        "|---|---|---:|---|",
    ]
    for item in summary["tools"]:
        lines.append(
            "| {name} | `{status}` | {count} | `{log}` |".format(
                name=item["name"],
                status=item["status"],
                count=len(item["files"]),
                log=item["log"],
            )
        )
    lines.extend(
        [
            "",
            "## File Sets",
            "",
            f"1. Verilator lint: `{', '.join(path.as_posix() for path in VERILATOR_FILES)}`",
            f"2. Verible lint/format: `{', '.join(path.as_posix() for path in VERIBLE_FILES)}`",
            f"3. svlint: `{', '.join(path.as_posix() for path in SVLINT_FILES)}`",
        ]
    )
    lines.extend(["", "## Notes", ""])
    for index, note in enumerate(summary.get("notes", []), start=1):
        lines.append(f"{index}. {note}")
    return "\n".join(lines) + "\n"


def write_summary(summary: dict[str, Any], summary_path: Path) -> None:
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    markdown_path = summary_path.with_suffix(".md")
    summary_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    markdown_path.write_text(render_markdown(summary), encoding="utf-8")


def do_run(args: argparse.Namespace) -> int:
    verilator = ensure_exists(args.verilator)
    verible_lint = ensure_exists(args.verible_lint)
    verible_format = ensure_exists(args.verible_format)
    svlint = ensure_exists(args.svlint)

    summary_path = Path(args.summary).resolve()
    logs_dir = summary_path.parent
    tools: list[dict[str, Any]] = []

    if verilator is not None:
        tools.append(
            tool_result(
                "verilator",
                [verilator, "--lint-only", "-Wall", *file_args(VERILATOR_FILES)],
                VERILATOR_FILES,
                logs_dir,
            )
        )

    if verible_lint is not None:
        tools.append(
            tool_result(
                "verible_lint",
                [
                    verible_lint,
                    "--parse_fatal",
                    "--rules_config",
                    str((PROJECT_ROOT / ".rules.verible_lint").resolve()),
                    *file_args(VERIBLE_FILES),
                ],
                VERIBLE_FILES,
                logs_dir,
            )
        )

    if verible_format is not None:
        tools.append(format_tool_result(verible_format, VERIBLE_FILES, logs_dir))

    if svlint is not None:
        tools.append(
            tool_result(
                "svlint",
                [
                    svlint,
                    "--config",
                    str((PROJECT_ROOT / ".svlint.toml").resolve()),
                    *file_args(SVLINT_FILES),
                ],
                SVLINT_FILES,
                logs_dir,
            )
        )

    summary = {
        "status": aggregate_status(tools),
        "summary_path": relpath(summary_path),
        "tools": tools,
        "notes": STATIC_ANALYSIS_NOTES,
    }
    write_summary(summary, summary_path)
    print(f"[STATIC] wrote {relpath(summary_path)}")
    print(f"[STATIC] wrote {relpath(summary_path.with_suffix('.md'))}")
    return 0 if summary["status"] == STATUS_PASS else 1


def do_show(args: argparse.Namespace) -> int:
    summary_path = Path(args.summary).resolve()
    if not summary_path.exists():
        raise FileNotFoundError(f"Static-analysis summary not found: {summary_path}")
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    print("Static analysis summary")
    print(f"  status: {summary.get('status', STATUS_MISSING)}")
    for item in summary.get("tools", []):
        print(
            "  {name}: {status} ({count} files)".format(
                name=item.get("name", "unknown"),
                status=item.get("status", STATUS_MISSING),
                count=len(item.get("files", [])),
            )
        )
        print(f"    log: {item.get('log', '-')}")
    return 0 if summary.get("status") == STATUS_PASS else 1


def do_format(args: argparse.Namespace) -> int:
    verible_format = ensure_exists(args.verible_format)
    if verible_format is None:
        raise FileNotFoundError("verible format binary is required")
    result = subprocess.run(
        [verible_format, "--inplace", *file_args(VERIBLE_FILES)],
        cwd=PROJECT_ROOT,
        check=False,
    )
    return result.returncode


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run or summarize static analysis.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    run_parser = subparsers.add_parser("run", help="Run all static analysis tools.")
    run_parser.add_argument("--verilator", required=True, help="Path to verilator.")
    run_parser.add_argument("--verible-lint", required=True, help="Path to verible-verilog-lint.")
    run_parser.add_argument("--verible-format", required=True, help="Path to verible-verilog-format.")
    run_parser.add_argument("--svlint", required=True, help="Path to svlint.")
    run_parser.add_argument(
        "--summary",
        default="sim_build/static_analysis/summary.json",
        help="Summary JSON output path.",
    )
    run_parser.set_defaults(func=do_run)

    show_parser = subparsers.add_parser("show", help="Show the most recent static-analysis summary.")
    show_parser.add_argument(
        "--summary",
        default="sim_build/static_analysis/summary.json",
        help="Summary JSON input path.",
    )
    show_parser.set_defaults(func=do_show)

    format_parser = subparsers.add_parser("format", help="Format tracked SystemVerilog sources in place.")
    format_parser.add_argument("--verible-format", required=True, help="Path to verible-verilog-format.")
    format_parser.set_defaults(func=do_format)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
