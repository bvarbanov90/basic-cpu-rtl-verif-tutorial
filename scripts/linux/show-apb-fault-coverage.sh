#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

COVERAGE_FILE="${1:-sim_build/apb_fault_coverage.json}"

if [[ ! -f "${COVERAGE_FILE}" ]]; then
    echo "APB fault coverage file not found: ${COVERAGE_FILE}. Run bash scripts/run-apb-fault.sh first." >&2
    exit 1
fi

python3 - "${COVERAGE_FILE}" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    cov = json.load(handle)

print("APB Fault Coverage Summary")
print(f"  pass:                          {cov.get('coverage_pass')}")
print(f"  setup_only_writes_ignored:     {cov.get('setup_only_writes_ignored')}")
print(f"  aborted_writes_ignored:        {cov.get('aborted_writes_ignored')}")
print(f"  setup_only_starts_ignored:     {cov.get('setup_only_starts_ignored')}")
print(f"  penable_without_select_ignore: {cov.get('penable_without_select_ignored')}")
print(f"  shadow_fault_write_observed:   {cov.get('shadow_fault_write_observed')}")
print(f"  deferred_shadow_updates:       {cov.get('deferred_shadow_updates')}")
print(f"  reload_observed_updates:       {cov.get('reload_observed_updates')}")
print(f"  program_runs:                  {cov.get('program_runs')}")
print(f"  fault_readbacks:               {cov.get('fault_readbacks')}")

coverage_goals = cov.get("coverage_goals", {})
if coverage_goals:
    print("\nCoverage Goals")
    for key in sorted(coverage_goals):
        print(f"  {key}: {coverage_goals[key]}")
PY
