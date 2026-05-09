#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

COVERAGE_FILE="${1:-sim_build/pyuvm_coverage.json}"

if [[ ! -f "${COVERAGE_FILE}" ]]; then
    echo "pyuvm coverage file not found: ${COVERAGE_FILE}. Run bash scripts/run-uvm.sh --no-waves first." >&2
    exit 1
fi

exec bash "${SCRIPT_DIR}/show-coverage.sh" "${COVERAGE_FILE}"
