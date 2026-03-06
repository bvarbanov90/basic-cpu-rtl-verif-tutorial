#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/update-coverage-baseline.sh [--current <path>] [--baseline <path>]
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

CURRENT_FILE="sim_build/coverage.json"
BASELINE_FILE="docs/coverage-baseline.json"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --current)
            if [[ $# -lt 2 ]]; then
                usage
                exit 2
            fi
            CURRENT_FILE="$2"
            shift 2
            ;;
        --baseline)
            if [[ $# -lt 2 ]]; then
                usage
                exit 2
            fi
            BASELINE_FILE="$2"
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

if [[ ! -f "${CURRENT_FILE}" ]]; then
    echo "Current coverage file not found: ${CURRENT_FILE}" >&2
    exit 1
fi

mkdir -p "$(dirname -- "${BASELINE_FILE}")"
cp "${CURRENT_FILE}" "${BASELINE_FILE}"
echo "Updated coverage baseline: ${BASELINE_FILE}"
