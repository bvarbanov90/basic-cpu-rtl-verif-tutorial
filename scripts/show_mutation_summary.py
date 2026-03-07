from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SUMMARY = PROJECT_ROOT / "sim_build" / "mutations" / "mutation_summary.json"


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Print a readable mutation campaign summary.")
    parser.add_argument("summary", nargs="?", default=str(DEFAULT_SUMMARY))
    args = parser.parse_args()

    summary_path = Path(args.summary).resolve()
    if not summary_path.exists():
        raise FileNotFoundError(f"Mutation summary not found: {summary_path}")

    payload = load_json(summary_path)
    mutations = payload.get("mutations", [])
    bench_kill_counts = payload.get("bench_kill_counts", {})

    print("Mutation campaign summary")
    print(f"  pass:            {payload.get('campaign_pass', 0)}")
    print(f"  total_mutations: {payload.get('total_mutations', len(mutations))}")
    print("")

    if bench_kill_counts:
        print("Bench kill counts")
        for bench_name in sorted(bench_kill_counts):
            print(f"  {bench_name}: {bench_kill_counts[bench_name]}")
        print("")

    print("Mutation details")
    for mutation in mutations:
        killed_by = mutation.get("killed_by", [])
        result = "PASS" if mutation.get("mutation_pass", 0) else "FAIL"
        benches = ", ".join(killed_by) if killed_by else "none"
        print(
            "  {name}: {result} category={category} killed_by={killed_by} description={description}".format(
                name=mutation.get("name", "unknown"),
                result=result,
                category=mutation.get("category", "uncategorized"),
                killed_by=benches,
                description=mutation.get("description", ""),
            )
        )

    return 0 if int(payload.get("campaign_pass", 0)) else 1


if __name__ == "__main__":
    raise SystemExit(main())
