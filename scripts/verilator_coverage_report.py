from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def project_now_utc() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_lcov_info(path: Path) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "path": str(path).replace("\\", "/"),
        "points_found": 0,
        "points_hit": 0,
        "percent": None,
    }
    if not path.exists():
        payload["status"] = "MISSING"
        return payload

    found = 0
    hit = 0
    for raw_line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw_line.strip()
        if line.startswith("LF:"):
            found += int(line.split(":", 1)[1])
        elif line.startswith("LH:"):
            hit += int(line.split(":", 1)[1])
        elif line.startswith("DA:"):
            found += 1
            if int(line.split(",", 1)[1]) > 0:
                hit += 1
        elif line.startswith("BRDA:"):
            found += 1
            if line.rsplit(",", 1)[1] not in {"0", "-"}:
                hit += 1

    payload["points_found"] = found
    payload["points_hit"] = hit
    payload["status"] = "PASS" if found > 0 else "EMPTY"
    if found > 0:
        payload["percent"] = round((100.0 * hit) / found, 2)
    return payload


def render_markdown(summary: dict[str, Any]) -> str:
    lines = [
        "# Verilator Coverage Summary",
        "",
        f"Generated UTC: `{summary['generated_utc']}`",
        "",
        "| Kind | Status | Hit | Found | Percent | Source |",
        "|---|---|---:|---:|---:|---|",
    ]
    for kind in ("overall", "line", "toggle", "expr"):
        payload = summary["categories"][kind]
        percent = "-" if payload["percent"] is None else f"{payload['percent']:.2f}%"
        lines.append(
            "| {kind} | `{status}` | {hit} | {found} | {percent} | `{path}` |".format(
                kind=kind,
                status=payload["status"],
                hit=payload["points_hit"],
                found=payload["points_found"],
                percent=percent,
                path=payload["path"],
            )
        )

    lines.extend(
        [
            "",
            "## Artifacts",
            "",
            f"1. Merged coverage: `{summary['merged_dat']}`",
            f"2. Annotated sources: `{summary['annotated_dir']}`",
        ]
    )
    return "\n".join(lines) + "\n"


def print_summary(summary: dict[str, Any]) -> None:
    print("Verilator coverage summary")
    for kind in ("overall", "line", "toggle", "expr"):
        payload = summary["categories"][kind]
        percent = "-" if payload["percent"] is None else f"{payload['percent']:.2f}%"
        print(
            "  {kind:<7} {status:<6} hit={hit:<6} found={found:<6} percent={percent:<8} path={path}".format(
                kind=kind,
                status=payload["status"],
                hit=payload["points_hit"],
                found=payload["points_found"],
                percent=percent,
                path=payload["path"],
            )
        )


def build_summary(args: argparse.Namespace) -> int:
    categories = {
        "overall": parse_lcov_info(Path(args.overall).resolve()),
        "line": parse_lcov_info(Path(args.line).resolve()),
        "toggle": parse_lcov_info(Path(args.toggle).resolve()),
        "expr": parse_lcov_info(Path(args.expr).resolve()),
    }
    status = "PASS" if categories["overall"]["points_found"] > 0 else "FAIL"
    summary = {
        "generated_utc": project_now_utc(),
        "status": status,
        "merged_dat": str(Path(args.merged_dat).resolve()).replace("\\", "/"),
        "annotated_dir": str(Path(args.annotated_dir).resolve()).replace("\\", "/"),
        "categories": categories,
    }

    summary_json = Path(args.summary_json).resolve()
    summary_json.parent.mkdir(parents=True, exist_ok=True)
    summary_json.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")

    summary_markdown = Path(args.summary_markdown).resolve()
    summary_markdown.parent.mkdir(parents=True, exist_ok=True)
    summary_markdown.write_text(render_markdown(summary), encoding="utf-8")

    print_summary(summary)
    print(f"[COVERAGE] wrote {summary_json}")
    print(f"[COVERAGE] wrote {summary_markdown}")
    return 0 if status == "PASS" else 1


def show_summary(args: argparse.Namespace) -> int:
    summary_path = Path(args.summary_json).resolve()
    if not summary_path.exists():
        print(f"Coverage summary not found: {summary_path}")
        return 1

    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    print_summary(summary)
    return 0 if summary.get("status") == "PASS" else 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build or show Verilator coverage summaries.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    build = subparsers.add_parser("build", help="Create JSON/Markdown summaries from lcov info files.")
    build.add_argument("--overall", required=True, help="Overall lcov info file.")
    build.add_argument("--line", required=True, help="Line-only lcov info file.")
    build.add_argument("--toggle", required=True, help="Toggle-only lcov info file.")
    build.add_argument("--expr", required=True, help="Expression-only lcov info file.")
    build.add_argument("--merged-dat", required=True, help="Merged Verilator coverage data file.")
    build.add_argument("--annotated-dir", required=True, help="Annotated source output directory.")
    build.add_argument("--summary-json", required=True, help="Output JSON summary path.")
    build.add_argument("--summary-markdown", required=True, help="Output Markdown summary path.")
    build.set_defaults(func=build_summary)

    show = subparsers.add_parser("show", help="Print a previously generated summary JSON file.")
    show.add_argument(
        "--summary-json",
        default="sim_build/verilator_coverage/summary.json",
        help="Existing JSON summary path.",
    )
    show.set_defaults(func=show_summary)

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
