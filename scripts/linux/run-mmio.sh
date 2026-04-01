#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/run-mmio.sh [--no-waves] [--program-hex <path>]
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

NO_WAVES=0
PROGRAM_HEX=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-waves)
            NO_WAVES=1
            shift
            ;;
        --program-hex)
            if [[ $# -lt 2 ]]; then
                usage
                exit 2
            fi
            PROGRAM_HEX="$2"
            shift 2
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

if ! command -v iverilog >/dev/null 2>&1; then
    echo "iverilog is required. Install Icarus Verilog and retry." >&2
    exit 1
fi

if ! command -v vvp >/dev/null 2>&1; then
    echo "vvp is required. It usually comes with Icarus Verilog." >&2
    exit 1
fi

mkdir -p sim_build

IVERILOG_ARGS=(-g2012)
if [[ "${NO_WAVES}" -eq 1 ]]; then
    IVERILOG_ARGS+=(-DNO_WAVES)
fi
IVERILOG_ARGS+=(
    -o sim_build/simple_cpu_mmio_tb.vvp
    rtl/simple_cpu.sv
    rtl/simple_cpu_mmio.sv
    tb/simple_cpu_mmio_assertions.sv
    tb/simple_cpu_mmio_tb.sv
)

iverilog "${IVERILOG_ARGS[@]}"

VVP_ARGS=(sim_build/simple_cpu_mmio_tb.vvp)
if [[ -n "${PROGRAM_HEX}" ]]; then
    if [[ ! -f "${PROGRAM_HEX}" ]]; then
        echo "Program hex file not found: ${PROGRAM_HEX}" >&2
        exit 1
    fi
    RESOLVED_HEX="$(realpath "${PROGRAM_HEX}")"
    VVP_ARGS+=("+PROGRAM_HEX=${RESOLVED_HEX}")
    echo "Using MMIO external program image: ${RESOLVED_HEX}"
fi

vvp "${VVP_ARGS[@]}"

if [[ -f sim_build/simple_cpu_mmio_tb.vcd && "${NO_WAVES}" -eq 0 ]]; then
    echo "Waveform written to sim_build/simple_cpu_mmio_tb.vcd"
fi

if [[ -f sim_build/mmio_coverage.json ]]; then
    echo "MMIO coverage JSON: sim_build/mmio_coverage.json"
fi

if [[ -f sim_build/mmio_coverage.csv ]]; then
    echo "MMIO coverage CSV:  sim_build/mmio_coverage.csv"
fi

echo "MMIO simulation complete."
