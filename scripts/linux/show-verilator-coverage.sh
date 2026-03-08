#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

PYTHON_BIN=""
if [[ -x ".venv/bin/python" ]]; then
    PYTHON_BIN=".venv/bin/python"
elif [[ -x ".venv_pyuvm_probe/bin/python" ]]; then
    PYTHON_BIN=".venv_pyuvm_probe/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
else
    echo "python3 is required to display the Verilator coverage summary." >&2
    exit 1
fi

"${PYTHON_BIN}" scripts/verilator_coverage_report.py show "$@"
