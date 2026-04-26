#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

COVERAGE_FILE="${1:-sim_build/axi_lite_fault_coverage.json}"

if [[ ! -f "${COVERAGE_FILE}" ]]; then
    echo "AXI-Lite fault coverage file not found: ${COVERAGE_FILE}. Run bash scripts/run-axi-lite-fault.sh first." >&2
    exit 1
fi

python3 - "${COVERAGE_FILE}" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    cov = json.load(handle)

print("AXI-Lite Fault Coverage Summary")
print(f"  pass:                             {cov.get('coverage_pass')}")
print(f"  aw_only_writes_ignored:           {cov.get('aw_only_writes_ignored')}")
print(f"  w_only_writes_ignored:            {cov.get('w_only_writes_ignored')}")
print(f"  split_write_attempts_ignored:     {cov.get('split_write_attempts_ignored')}")
print(f"  pending_response_blocks_writes:   {cov.get('pending_response_blocks_writes')}")
print(f"  shadow_fault_write_observed:      {cov.get('shadow_fault_write_observed')}")
print(f"  deferred_shadow_updates:          {cov.get('deferred_shadow_updates')}")
print(f"  reload_observed_updates:          {cov.get('reload_observed_updates')}")
print(f"  program_runs:                     {cov.get('program_runs')}")
print(f"  fault_readbacks:                  {cov.get('fault_readbacks')}")

coverage_goals = cov.get("coverage_goals", {})
if coverage_goals:
    print("\nCoverage Goals")
    for key in sorted(coverage_goals):
        print(f"  {key}: {coverage_goals[key]}")
PY
