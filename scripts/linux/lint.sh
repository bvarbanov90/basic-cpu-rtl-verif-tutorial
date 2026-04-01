#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

VERILATOR_BIN="$(command -v verilator || true)"
VERIBLE_ROOT="${VERIBLE_ROOT:-${HOME}/tools/verible}"
SVLINT_ROOT="${SVLINT_ROOT:-${HOME}/tools/svlint}"
VERIBLE_LINT_BIN=""
VERIBLE_FORMAT_BIN=""
SVLINT_BIN=""

resolve_verible_bin() {
    local tool_name="$1"
    if [[ -x "${VERIBLE_ROOT}/bin/${tool_name}" ]]; then
        printf '%s\n' "${VERIBLE_ROOT}/bin/${tool_name}"
        return 0
    fi
    find "${VERIBLE_ROOT}" -maxdepth 3 -type f -name "${tool_name}" -print -quit 2>/dev/null || true
}

resolved_verible_lint="$(resolve_verible_bin verible-verilog-lint)"
resolved_verible_format="$(resolve_verible_bin verible-verilog-format)"

if [[ -n "${resolved_verible_lint}" && -n "${resolved_verible_format}" ]]; then
    VERIBLE_LINT_BIN="${resolved_verible_lint}"
    VERIBLE_FORMAT_BIN="${resolved_verible_format}"
elif [[ -x "${VERIBLE_ROOT}/bin/verible-verilog-lint" ]]; then
    VERIBLE_LINT_BIN="${VERIBLE_ROOT}/bin/verible-verilog-lint"
    VERIBLE_FORMAT_BIN="${VERIBLE_ROOT}/bin/verible-verilog-format"
elif command -v verible-verilog-lint >/dev/null 2>&1 && command -v verible-verilog-format >/dev/null 2>&1; then
    VERIBLE_LINT_BIN="$(command -v verible-verilog-lint)"
    VERIBLE_FORMAT_BIN="$(command -v verible-verilog-format)"
fi

if [[ -x "${SVLINT_ROOT}/bin/svlint" ]]; then
    SVLINT_BIN="${SVLINT_ROOT}/bin/svlint"
elif command -v svlint >/dev/null 2>&1; then
    SVLINT_BIN="$(command -v svlint)"
fi

if [[ -z "${VERILATOR_BIN}" ]]; then
    echo "verilator is required for linting." >&2
    exit 1
fi

if [[ -z "${VERIBLE_LINT_BIN}" || -z "${VERIBLE_FORMAT_BIN}" ]]; then
    echo "verible-verilog-lint and verible-verilog-format are required. Run bash scripts/install-tools-ubuntu.sh." >&2
    exit 1
fi

if [[ -z "${SVLINT_BIN}" ]]; then
    echo "svlint is required. Run bash scripts/install-tools-ubuntu.sh." >&2
    exit 1
fi

python3 scripts/static_analysis.py run \
    --verilator "${VERILATOR_BIN}" \
    --verible-lint "${VERIBLE_LINT_BIN}" \
    --verible-format "${VERIBLE_FORMAT_BIN}" \
    --svlint "${SVLINT_BIN}"
