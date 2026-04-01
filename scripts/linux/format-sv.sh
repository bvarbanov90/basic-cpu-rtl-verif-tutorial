#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

VERIBLE_ROOT="${VERIBLE_ROOT:-${HOME}/tools/verible}"
VERIBLE_FORMAT_BIN=""

resolve_verible_format_bin() {
    if [[ -x "${VERIBLE_ROOT}/bin/verible-verilog-format" ]]; then
        printf '%s\n' "${VERIBLE_ROOT}/bin/verible-verilog-format"
        return 0
    fi
    find "${VERIBLE_ROOT}" -maxdepth 3 -type f -name verible-verilog-format -print -quit 2>/dev/null || true
}

resolved_verible_format="$(resolve_verible_format_bin)"

if [[ -n "${resolved_verible_format}" ]]; then
    VERIBLE_FORMAT_BIN="${resolved_verible_format}"
elif [[ -x "${VERIBLE_ROOT}/bin/verible-verilog-format" ]]; then
    VERIBLE_FORMAT_BIN="${VERIBLE_ROOT}/bin/verible-verilog-format"
elif command -v verible-verilog-format >/dev/null 2>&1; then
    VERIBLE_FORMAT_BIN="$(command -v verible-verilog-format)"
else
    echo "verible-verilog-format is required. Run bash scripts/install-tools-ubuntu.sh." >&2
    exit 1
fi

python3 scripts/static_analysis.py format --verible-format "${VERIBLE_FORMAT_BIN}"
