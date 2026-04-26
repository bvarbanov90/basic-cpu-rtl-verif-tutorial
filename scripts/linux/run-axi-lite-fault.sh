#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/run-axi-lite-fault.sh [--no-waves]
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
    -o sim_build/simple_cpu_axi_lite_fault_tb.vvp
    rtl/simple_cpu.sv
    rtl/simple_cpu_mmio.sv
    rtl/simple_cpu_axi_lite.sv
    tb/simple_cpu_axi_lite_assertions.sv
    tb/simple_cpu_axi_lite_fault_tb.sv
)

iverilog "${IVERILOG_ARGS[@]}"

vvp sim_build/simple_cpu_axi_lite_fault_tb.vvp

if [[ -f sim_build/simple_cpu_axi_lite_fault_tb.vcd && "${NO_WAVES}" -eq 0 ]]; then
    echo "Waveform written to sim_build/simple_cpu_axi_lite_fault_tb.vcd"
fi

if [[ -f sim_build/axi_lite_fault_coverage.json ]]; then
    echo "AXI-Lite fault coverage JSON: sim_build/axi_lite_fault_coverage.json"
fi

if [[ -f sim_build/axi_lite_fault_coverage.csv ]]; then
    echo "AXI-Lite fault coverage CSV:  sim_build/axi_lite_fault_coverage.csv"
fi

echo "AXI-Lite fault simulation complete."


