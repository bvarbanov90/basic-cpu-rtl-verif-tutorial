from __future__ import annotations

import argparse
from pathlib import Path

from status_lib import PROJECT_ROOT, STATUS_PASS, summarize_formal


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Print a concise formal-target status summary.")
    parser.add_argument(
        "targets",
        nargs="*",
        default=[
            "formal/simple_cpu",
            "formal/simple_cpu_mmio",
            "formal/simple_cpu_cover",
            "formal/simple_cpu_mmio_cover",
        ],
        help="Formal output directories to inspect.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    targets = [Path(target).resolve() for target in args.targets]
    summary = summarize_formal(targets)

    print("Formal status summary")
    print(f"  aggregate: {summary['status']} ({summary['passed']}/{summary['total']} passing)")
    for target in summary["targets"]:
        solver = target.get("solver") or "-"
        elapsed = target.get("elapsed") or "-"
        print(
            "  {name:<18} {status:<8} solver={solver:<8} elapsed={elapsed:<8} path={path}".format(
                name=target["name"],
                status=target["status"],
                solver=solver,
                elapsed=elapsed,
                path=target["path"],
            )
        )
        if target["status"] != STATUS_PASS and target.get("raw_status"):
            print(f"    raw_status={target['raw_status']}")

    return 0 if summary["status"] == STATUS_PASS else 1


if __name__ == "__main__":
    raise SystemExit(main())
