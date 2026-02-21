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
Usage: bash scripts/run-formal.sh [--solver <cvc5|z3|boolector|...>]
EOF
}

SOLVER=""
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

if [[ -z "${SOLVER}" ]]; then
    # cvc5 is the most reliable default in Ubuntu/WSL for this tutorial setup.
    if command -v cvc5 >/dev/null 2>&1; then
        SOLVER="cvc5"
    elif command -v z3 >/dev/null 2>&1; then
        SOLVER="z3"
    else
        echo "No supported SMT solver found. Install cvc5 or z3." >&2
        exit 1
    fi
fi

if ! command -v "${SOLVER}" >/dev/null 2>&1; then
    echo "Requested solver '${SOLVER}' is not installed or not on PATH." >&2
    exit 1
fi

TMP_SBY="formal/simple_cpu.${SOLVER}.tmp.sby"
trap 'rm -f "${TMP_SBY}"' EXIT

sed "s/^smtbmc z3$/smtbmc ${SOLVER}/" formal/simple_cpu.sby > "${TMP_SBY}"
sby -f -d formal/simple_cpu "${TMP_SBY}"

echo "Formal run complete. Artifacts are in formal/simple_cpu/"
