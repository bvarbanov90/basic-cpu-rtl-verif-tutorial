#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if ! command -v gtkwave >/dev/null 2>&1; then
    echo "gtkwave is required. Install GTKWave and retry." >&2
    exit 1
fi

WAVE_FILE="${1:-sim_build/simple_cpu_tb.vcd}"
if [[ ! -f "${WAVE_FILE}" ]]; then
    FALLBACK="$(ls -1t sim_build/*.vcd 2>/dev/null | head -n 1 || true)"
    if [[ -n "${FALLBACK}" ]]; then
        WAVE_FILE="${FALLBACK}"
    else
        echo "Wave file not found: ${WAVE_FILE}. Run bash scripts/run.sh first." >&2
        exit 1
    fi
fi

gtkwave "${WAVE_FILE}" >/dev/null 2>&1 &
echo "Opened waveform in GTKWave: ${WAVE_FILE}"
