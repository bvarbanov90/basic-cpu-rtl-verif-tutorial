#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/run-mmio-wait-uvm.sh [--no-waves]
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

NO_WAVES=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-waves)
            NO_WAVES=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if ! command -v make >/dev/null 2>&1; then
    echo "make is required for cocotb/pyuvm runs." >&2
    exit 1
fi

PYTHON_BIN=""
if [[ -x ".venv/bin/python" ]]; then
    PYTHON_BIN=".venv/bin/python"
elif [[ -x ".venv_pyuvm_probe/bin/python" ]]; then
    PYTHON_BIN=".venv_pyuvm_probe/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
else
    echo "python3 is required for cocotb/pyuvm runs." >&2
    exit 1
fi

if ! "${PYTHON_BIN}" - <<'PY' >/dev/null 2>&1
import sys
assert sys.version_info < (3, 14)
import cocotb
import pyuvm
PY
then
    echo "Python < 3.14 with cocotb and pyuvm is required. Install with: python3 -m pip install -r requirements.txt" >&2
    exit 1
fi

mkdir -p sim_build

if [[ -n "${PYTHONPATH:-}" ]]; then
    export PYTHONPATH="${PROJECT_ROOT}:${PYTHONPATH}"
else
    export PYTHONPATH="${PROJECT_ROOT}"
fi

PYTHON_BIN_DIR="$(cd -- "$(dirname -- "${PYTHON_BIN}")" && pwd)"
export PATH="${PYTHON_BIN_DIR}:${PATH}"

WAVES_VALUE=1
if [[ "${NO_WAVES}" -eq 1 ]]; then
    WAVES_VALUE=0
fi

VERILOG_SOURCES_VALUE="${PROJECT_ROOT}/rtl/simple_cpu.sv ${PROJECT_ROOT}/rtl/simple_cpu_mmio.sv ${PROJECT_ROOT}/rtl/simple_cpu_mmio_wait.sv"

make -f Makefile \
    SIM=icarus \
    PYTHON_BIN="${PYTHON_BIN}" \
    TOPLEVEL=simple_cpu_mmio_wait \
    VERILOG_SOURCES="${VERILOG_SOURCES_VALUE}" \
    COCOTB_TEST_MODULES=tb.test_simple_cpu_mmio_pyuvm \
    WAVES="${WAVES_VALUE}" \
    SIM_BUILD=sim_build/mmio_wait_pyuvm \
    COCOTB_RESULTS_FILE=sim_build/mmio_wait_uvm_results.xml

echo "MMIO wait-state pyuvm run complete."
echo "Results XML: sim_build/mmio_wait_uvm_results.xml"
