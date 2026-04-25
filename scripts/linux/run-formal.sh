#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if ! command -v sby >/dev/null 2>&1; then
    echo "sby is required for formal checks. Install SymbiYosys and retry." >&2
    exit 1
fi

usage() {
    cat <<'EOF'
Usage: bash scripts/run-formal.sh [--solver <cvc5|z3|boolector|...>] [--mode <prove|cover|all>]
EOF
}

SOLVER=""
MODE="prove"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --solver)
            if [[ $# -lt 2 ]]; then
                usage
                exit 2
            fi
            SOLVER="$2"
            shift 2
            ;;
        --mode)
            if [[ $# -lt 2 ]]; then
                usage
                exit 2
            fi
            MODE="$2"
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

case "${MODE}" in
    prove|cover|all)
        ;;
    *)
        echo "Unsupported mode '${MODE}'. Use prove, cover, or all." >&2
        exit 2
        ;;
esac

if [[ -z "${SOLVER}" ]]; then
    # cvc5 is the most reliable default across Ubuntu/WSL setups for this tutorial.
    if command -v cvc5 >/dev/null 2>&1; then
        SOLVER="cvc5"
    elif command -v z3 >/dev/null 2>&1; then
        SOLVER="z3"
    elif command -v boolector >/dev/null 2>&1; then
        SOLVER="boolector"
    else
        echo "No supported SMT solver found. Install boolector, cvc5, or z3." >&2
        exit 1
    fi
fi

if ! command -v "${SOLVER}" >/dev/null 2>&1; then
    echo "Requested solver '${SOLVER}' is not installed or not on PATH." >&2
    exit 1
fi

TEMP_FILES=()
cleanup() {
    if [[ "${#TEMP_FILES[@]}" -gt 0 ]]; then
        rm -f "${TEMP_FILES[@]}"
    fi
}
trap cleanup EXIT

run_sby() {
    local source_sby="$1"
    local output_dir="$2"
    local base_name
    local tmp_sby

    base_name="$(basename "${source_sby%.sby}")"
    tmp_sby="formal/${base_name}.${SOLVER}.tmp.sby"
    TEMP_FILES+=("${tmp_sby}")

    sed "s/^smtbmc z3$/smtbmc ${SOLVER}/" "${source_sby}" > "${tmp_sby}"
    rm -rf "${output_dir}"
    sby -f -d "${output_dir}" "${tmp_sby}"
}

if [[ "${MODE}" == "prove" || "${MODE}" == "all" ]]; then
    run_sby formal/simple_cpu.sby formal/simple_cpu
    run_sby formal/simple_cpu_mmio.sby formal/simple_cpu_mmio
    run_sby formal/simple_cpu_mmio_wait.sby formal/simple_cpu_mmio_wait
    run_sby formal/simple_cpu_mmio_wait_faults.sby formal/simple_cpu_mmio_wait_faults
    run_sby formal/simple_cpu_apb.sby formal/simple_cpu_apb
    run_sby formal/simple_cpu_wishbone.sby formal/simple_cpu_wishbone
    run_sby formal/simple_cpu_axi_lite.sby formal/simple_cpu_axi_lite
    run_sby formal/simple_cpu_apb_faults.sby formal/simple_cpu_apb_faults
    run_sby formal/simple_cpu_wishbone_faults.sby formal/simple_cpu_wishbone_faults
fi

if [[ "${MODE}" == "cover" || "${MODE}" == "all" ]]; then
    run_sby formal/simple_cpu_cover.sby formal/simple_cpu_cover
    run_sby formal/simple_cpu_mmio_cover.sby formal/simple_cpu_mmio_cover
    run_sby formal/simple_cpu_mmio_wait_cover.sby formal/simple_cpu_mmio_wait_cover
    run_sby formal/simple_cpu_apb_cover.sby formal/simple_cpu_apb_cover
    run_sby formal/simple_cpu_wishbone_cover.sby formal/simple_cpu_wishbone_cover
    run_sby formal/simple_cpu_axi_lite_cover.sby formal/simple_cpu_axi_lite_cover
fi

echo "Formal run complete with solver '${SOLVER}' in mode '${MODE}'."
