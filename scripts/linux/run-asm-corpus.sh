#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/run-asm-corpus.sh [--no-simulate] [--runner <direct|mmio|mmio_wait|apb|wishbone>]
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-simulate)
            ARGS+=("--no-simulate")
            shift
            ;;
        --runner)
            if [[ $# -lt 2 ]]; then
                usage
                exit 2
            fi
            ARGS+=("--runner" "$2")
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

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for the assembler corpus runner." >&2
    exit 1
fi

python3 scripts/check_asm_corpus.py "${ARGS[@]}"
