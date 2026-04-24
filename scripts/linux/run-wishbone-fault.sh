#!/usr/bin/env bash
set -euo pipefail

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
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

mkdir -p sim_build

iverilog_args=(-g2012)
if [[ "${NO_WAVES}" -eq 1 ]]; then
    iverilog_args+=(-DNO_WAVES)
fi
iverilog_args+=(
    -o sim_build/simple_cpu_wishbone_fault_tb.vvp
    rtl/simple_cpu.sv
    rtl/simple_cpu_mmio.sv
    rtl/simple_cpu_wishbone.sv
    tb/simple_cpu_wishbone_assertions.sv
    tb/simple_cpu_wishbone_fault_tb.sv
)

iverilog "${iverilog_args[@]}"
vvp sim_build/simple_cpu_wishbone_fault_tb.vvp

if [[ -f sim_build/simple_cpu_wishbone_fault_tb.vcd && "${NO_WAVES}" -eq 0 ]]; then
    echo "Waveform written to sim_build/simple_cpu_wishbone_fault_tb.vcd"
fi

if [[ -f sim_build/wishbone_fault_coverage.json ]]; then
    echo "Wishbone fault coverage JSON: sim_build/wishbone_fault_coverage.json"
fi

if [[ -f sim_build/wishbone_fault_coverage.csv ]]; then
    echo "Wishbone fault coverage CSV:  sim_build/wishbone_fault_coverage.csv"
fi

echo "Wishbone fault simulation complete."



