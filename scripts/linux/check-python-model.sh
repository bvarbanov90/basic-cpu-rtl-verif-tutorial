#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

find_python_with_pytest() {
    local candidates=(
        ".venv_ci/bin/python"
        ".venv_model_linux/bin/python"
        ".venv/bin/python"
        ".venv_pyuvm_probe/bin/python"
        "python3"
    )

    for candidate in "${candidates[@]}"; do
        if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" - <<'PY' >/dev/null 2>&1
import sys
assert sys.version_info < (3, 14)
import pytest
PY
        then
            printf '%s\n' "${candidate}"
            return 0
        fi
    done

    return 1
}

PYTHON_BIN="$(find_python_with_pytest || true)"
if [[ -z "${PYTHON_BIN}" ]]; then
    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 is required for reference model checks." >&2
        exit 1
    fi
    if ! python3 - <<'PY' >/dev/null 2>&1
import sys
assert sys.version_info < (3, 14)
PY
    then
        echo "Python < 3.14 is required for reference model checks." >&2
        exit 1
    fi

    python3 -m venv .venv_model_linux
    .venv_model_linux/bin/python -m pip install --upgrade pip
    .venv_model_linux/bin/python -m pip install "pytest>=8.0"
    PYTHON_BIN=".venv_model_linux/bin/python"
fi

export PYTHONPATH="${PROJECT_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"

"${PYTHON_BIN}" -m pytest -q tb/test_cpu_lib_unit.py

mkdir -p sim_build/model_trace
"${PYTHON_BIN}" scripts/model_trace.py --builtin smoke --format table --output sim_build/model_trace/smoke.txt
"${PYTHON_BIN}" scripts/model_trace.py --builtin branch --format json --output sim_build/model_trace/branch.json

echo "Python reference model checks passed."
