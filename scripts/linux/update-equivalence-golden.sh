#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

mkdir -p equiv
cp rtl/simple_cpu.sv equiv/simple_cpu_golden.sv

echo "Updated equivalence golden snapshot: equiv/simple_cpu_golden.sv"
