#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/oss-cad-suite.sh"

if ! command -v eqy >/dev/null 2>&1; then
    ensure_linux_oss_cad_suite "eqy" "eqy is not available"
fi

if ! command -v eqy >/dev/null 2>&1; then
    echo "eqy is required for equivalence checks. Install EQY and retry." >&2
    exit 1
fi

eqy -f -d equiv/simple_cpu_eqy equiv/simple_cpu.eqy

echo "Equivalence run complete. Artifacts are in equiv/simple_cpu_eqy/"
