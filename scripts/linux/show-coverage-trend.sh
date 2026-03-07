#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to show coverage trends." >&2
    exit 1
fi

HISTORY_FILE="${1:-docs/coverage-history.json}"
LIMIT="${2:-12}"

python3 scripts/coverage_history.py report \
    --history "${HISTORY_FILE}" \
    --limit "${LIMIT}"
