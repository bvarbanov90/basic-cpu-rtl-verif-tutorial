#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

COVERAGE_FILE="${1:-sim_build/mmio_wait_coverage.json}"

if [[ ! -f "${COVERAGE_FILE}" ]]; then
    echo "MMIO-wait coverage file not found: ${COVERAGE_FILE}. Run bash scripts/run-mmio-wait.sh first." >&2
    exit 1
fi

python3 - "${COVERAGE_FILE}" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    cov = json.load(handle)

print("MMIO-wait Coverage Summary")
print(f"  pass:                  {cov.get('coverage_pass')}")
print(f"  program_runs:          {cov.get('program_runs')}")
print(f"  external_program_runs: {cov.get('external_program_runs')}")
print(f"  shadow_writes:         {cov.get('shadow_writes')}")
print(f"  shadow_reads:          {cov.get('shadow_reads')}")
print(f"  dmem_reads:            {cov.get('dmem_reads')}")
print(f"  status_reads:          {cov.get('status_reads')}")
print(f"  acc_reads:             {cov.get('acc_reads')}")
print(f"  pc_reads:              {cov.get('pc_reads')}")
print(f"  control_reads:         {cov.get('control_reads')}")
print(f"  start_writes:          {cov.get('control_start_writes')}")
print(f"  stop_writes:           {cov.get('control_stop_writes')}")
print(f"  read_transactions:     {cov.get('read_transactions')}")
print(f"  write_transactions:    {cov.get('write_transactions')}")
print(f"  wait_transactions:     {cov.get('wait_transactions')}")
print(f"  wait_cycles:           {cov.get('wait_cycles')}")
print(f"  max_wait_observed:     {cov.get('max_wait_observed')}")

state_seen = cov.get("state_seen", {})
if state_seen:
    print("\nWrapper States Seen")
    for key in sorted(state_seen):
        print(f"  {key}: {state_seen[key]}")

coverage_goals = cov.get("coverage_goals", {})
if coverage_goals:
    print("\nCoverage Goals")
    for key in sorted(coverage_goals):
        print(f"  {key}: {coverage_goals[key]}")
PY

