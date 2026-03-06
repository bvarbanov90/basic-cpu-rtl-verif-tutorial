#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/check-coverage-delta.sh [--current <path>] [--baseline <path>]
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

PYTHON_BIN=""
if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_BIN="python"
else
    echo "python3 or python is required for coverage delta checks." >&2
    exit 1
fi

"${PYTHON_BIN}" scripts/check_coverage_delta.py --current "${CURRENT_FILE}" --baseline "${BASELINE_FILE}"
