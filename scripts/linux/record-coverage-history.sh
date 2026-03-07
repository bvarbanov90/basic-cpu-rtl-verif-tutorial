#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to record coverage history." >&2
    exit 1
fi

CORE_COVERAGE="${1:-sim_build/coverage.json}"
MMIO_COVERAGE="${2:-sim_build/mmio_coverage.json}"
HISTORY_FILE="${3:-docs/coverage-history.json}"
MARKDOWN_FILE="${4:-docs/coverage-history.md}"
LABEL="${5:-tutorial-regression}"
LIMIT="${6:-12}"
MAX_ENTRIES="${7:-64}"

python3 scripts/coverage_history.py snapshot \
    --core "${CORE_COVERAGE}" \
    --mmio "${MMIO_COVERAGE}" \
    --history "${HISTORY_FILE}" \
    --markdown "${MARKDOWN_FILE}" \
    --label "${LABEL}" \
    --limit "${LIMIT}" \
    --max-entries "${MAX_ENTRIES}"
