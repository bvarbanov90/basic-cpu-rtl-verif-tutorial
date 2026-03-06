#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

COVERAGE_FILE="${1:-sim_build/coverage.json}"

if [[ ! -f "${COVERAGE_FILE}" ]]; then
    echo "Coverage file not found: ${COVERAGE_FILE}. Run bash scripts/run.sh first." >&2
    exit 1
fi

python3 - "${COVERAGE_FILE}" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    cov = json.load(f)

print("Coverage Summary")
print(f"  pass:               {cov.get('coverage_pass')}")
print(f"  opcode_hit_bitmap:  {cov.get('opcode_hit_bitmap')}")
print(f"  illegal_opcode_hit: {cov.get('illegal_opcode_hit')}")
print(f"  jz_taken:           {cov.get('jz_taken')}")
print(f"  jz_not_taken:       {cov.get('jz_not_taken')}")
print(f"  zero_transition_00: {cov.get('zero_transition_00')}")
print(f"  zero_transition_01: {cov.get('zero_transition_01')}")
print(f"  zero_transition_10: {cov.get('zero_transition_10')}")
print(f"  zero_transition_11: {cov.get('zero_transition_11')}")
print(f"  carry_0:           {cov.get('carry_0')}")
print(f"  carry_1:           {cov.get('carry_1')}")
print(f"  neg_0:             {cov.get('neg_0')}")
print(f"  neg_1:             {cov.get('neg_1')}")
print(f"  overflow_0:        {cov.get('overflow_0')}")
print(f"  overflow_1:        {cov.get('overflow_1')}")
print(f"  program_runs:       {cov.get('program_runs')}")
print(f"  total_cycles:       {cov.get('total_cycles')}")

print("\nOpcode Hit Details")
for key in sorted(cov.get("opcode_hits", {}), key=lambda k: int(k)):
    print(f"  opcode_{key}: {cov['opcode_hits'][key]}")

if "opcode_counts" in cov:
    print("\nOpcode Execution Counts")
    for key in sorted(cov["opcode_counts"], key=lambda k: int(k)):
        print(f"  opcode_{key}_count: {cov['opcode_counts'][key]}")

if "opcode_zero_cross" in cov:
    print("\nOpcode x ZERO Cross (post-instruction ZERO)")
    for key in sorted(cov["opcode_zero_cross"], key=lambda k: int(k)):
        row = cov["opcode_zero_cross"][key]
        print(f"  opcode_{key}: zero0={row['zero0']} zero1={row['zero1']}")

if "opcode_carry_cross" in cov:
    print("\nOpcode x CARRY Cross (post-instruction CARRY)")
    for key in sorted(cov["opcode_carry_cross"], key=lambda k: int(k)):
        row = cov["opcode_carry_cross"][key]
        print(f"  opcode_{key}: carry0={row['carry0']} carry1={row['carry1']}")

if "opcode_neg_cross" in cov:
    print("\nOpcode x NEG Cross (post-instruction NEG)")
    for key in sorted(cov["opcode_neg_cross"], key=lambda k: int(k)):
        row = cov["opcode_neg_cross"][key]
        print(f"  opcode_{key}: neg0={row['neg0']} neg1={row['neg1']}")

if "opcode_overflow_cross" in cov:
    print("\nOpcode x OVERFLOW Cross (post-instruction OVERFLOW)")
    for key in sorted(cov["opcode_overflow_cross"], key=lambda k: int(k)):
        row = cov["opcode_overflow_cross"][key]
        print(f"  opcode_{key}: overflow0={row['overflow0']} overflow1={row['overflow1']}")
PY
