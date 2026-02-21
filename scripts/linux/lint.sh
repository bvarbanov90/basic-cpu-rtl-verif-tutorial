#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if ! command -v verilator >/dev/null 2>&1; then
    echo "verilator is required for linting." >&2
    exit 1
fi

verilator --lint-only -Wall rtl/simple_cpu.sv
