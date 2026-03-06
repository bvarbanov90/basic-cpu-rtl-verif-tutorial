from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


LOWER_BOUND_SCALARS = [
    "coverage_pass",
    "illegal_opcode_hit",
    "jz_taken",
    "jz_not_taken",
    "zero_transition_00",
    "zero_transition_01",
    "zero_transition_10",
    "zero_transition_11",
    "carry_0",
    "carry_1",
    "neg_0",
    "neg_1",
    "overflow_0",
    "overflow_1",
    "program_runs",
    "total_cycles",
    "random_suite_iterations",
    "branch_random_suite_iterations",
]

LOWER_BOUND_MAPS = [
    "opcode_hits",
    "opcode_counts",
]

EXACT_MAPS = [
    "opcode_zero_cross_reachability",
    "opcode_carry_cross_reachability",
    "opcode_neg_cross_reachability",
    "opcode_overflow_cross_reachability",
    "coverage_goals",
]

CROSS_MAPS = [
    ("opcode_zero_cross", "opcode_zero_cross_reachability"),
    ("opcode_carry_cross", "opcode_carry_cross_reachability"),
    ("opcode_neg_cross", "opcode_neg_cross_reachability"),
    ("opcode_overflow_cross", "opcode_overflow_cross_reachability"),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Check coverage against a repo-tracked baseline.")
    parser.add_argument(
        "--current",
        default="sim_build/coverage.json",
        help="Path to the current coverage JSON file.",
    )
    parser.add_argument(
        "--baseline",
        default="docs/coverage-baseline.json",
        help="Path to the baseline coverage JSON file.",
    )
    return parser.parse_args()


def load_json(path_str: str) -> dict:
    path = Path(path_str)
    if not path.is_file():
        raise FileNotFoundError(f"File not found: {path}")
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def flatten(prefix: str, value) -> list[tuple[str, object]]:
    if isinstance(value, dict):
        items: list[tuple[str, object]] = []
        for key in sorted(value, key=lambda item: str(item)):
            child_prefix = f"{prefix}.{key}" if prefix else str(key)
            items.extend(flatten(child_prefix, value[key]))
        return items
    return [(prefix, value)]


def main() -> int:
    args = parse_args()

    try:
        current = load_json(args.current)
        baseline = load_json(args.baseline)
    except FileNotFoundError as exc:
        print(f"[COVERAGE-DELTA][FAIL] {exc}", file=sys.stderr)
        return 1

    failures: list[str] = []
    checks = 0

    def fail(message: str) -> None:
        failures.append(message)

    for key in LOWER_BOUND_SCALARS:
        if key not in baseline:
            fail(f"Baseline is missing scalar '{key}'")
            continue
        if key not in current:
            fail(f"Current coverage is missing scalar '{key}'")
            continue
        checks += 1
        current_value = int(current[key])
        baseline_value = int(baseline[key])
        if current_value < baseline_value:
            fail(f"{key} regressed: baseline={baseline_value}, current={current_value}")

    for section in LOWER_BOUND_MAPS:
        baseline_map = baseline.get(section)
        current_map = current.get(section)
        if not isinstance(baseline_map, dict):
            fail(f"Baseline section '{section}' is missing or not an object")
            continue
        if not isinstance(current_map, dict):
            fail(f"Current section '{section}' is missing or not an object")
            continue

        for key, baseline_value in baseline_map.items():
            if key not in current_map:
                fail(f"{section}.{key} is missing from current coverage")
                continue
            checks += 1
            current_value = int(current_map[key])
            baseline_count = int(baseline_value)
            if current_value < baseline_count:
                fail(f"{section}.{key} regressed: baseline={baseline_count}, current={current_value}")

    for section, reachability_section in CROSS_MAPS:
        baseline_map = baseline.get(section)
        current_map = current.get(section)
        reachability_map = baseline.get(reachability_section)
        if not isinstance(baseline_map, dict):
            fail(f"Baseline section '{section}' is missing or not an object")
            continue
        if not isinstance(current_map, dict):
            fail(f"Current section '{section}' is missing or not an object")
            continue
        if not isinstance(reachability_map, dict):
            fail(f"Baseline section '{reachability_section}' is missing or not an object")
            continue

        for opcode, baseline_row in baseline_map.items():
            current_row = current_map.get(opcode)
            reachability_row = reachability_map.get(opcode)
            if not isinstance(baseline_row, dict):
                fail(f"Baseline row '{section}.{opcode}' is not an object")
                continue
            if not isinstance(current_row, dict):
                fail(f"Current row '{section}.{opcode}' is missing or not an object")
                continue
            if not isinstance(reachability_row, dict):
                fail(f"Baseline row '{reachability_section}.{opcode}' is missing or not an object")
                continue

            for state_key, baseline_value in baseline_row.items():
                if state_key not in current_row:
                    fail(f"{section}.{opcode}.{state_key} is missing from current coverage")
                    continue
                if state_key not in reachability_row:
                    fail(f"{reachability_section}.{opcode}.{state_key} is missing from baseline")
                    continue

                checks += 1
                current_value = int(current_row[state_key])
                baseline_count = int(baseline_value)
                reachable = int(reachability_row[state_key])
                if reachable:
                    if current_value < baseline_count:
                        fail(
                            f"{section}.{opcode}.{state_key} regressed: "
                            f"baseline={baseline_count}, current={current_value}"
                        )
                elif current_value != 0:
                    fail(
                        f"{section}.{opcode}.{state_key} should remain 0 because it is unreachable; "
                        f"current={current_value}"
                    )

    for section in EXACT_MAPS:
        baseline_map = baseline.get(section)
        current_map = current.get(section)
        if baseline_map is None:
            fail(f"Baseline section '{section}' is missing")
            continue
        if current_map is None:
            fail(f"Current section '{section}' is missing")
            continue

        baseline_items = dict(flatten(section, baseline_map))
        current_items = dict(flatten(section, current_map))

        for key, baseline_value in baseline_items.items():
            checks += 1
            if key not in current_items:
                fail(f"{key} is missing from current coverage")
                continue
            if current_items[key] != baseline_value:
                fail(f"{key} changed: baseline={baseline_value}, current={current_items[key]}")

        for key in current_items:
            if key not in baseline_items:
                fail(f"{key} exists in current coverage but not in baseline")

    if failures:
        print("[COVERAGE-DELTA] baseline comparison failed")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(
        f"[COVERAGE-DELTA] baseline comparison passed "
        f"({checks} checks, baseline={args.baseline}, current={args.current})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
