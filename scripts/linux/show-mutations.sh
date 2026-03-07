#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to show mutation summaries." >&2
    exit 1
fi

SUMMARY_FILE="${1:-sim_build/mutations/mutation_summary.json}"

python3 scripts/show_mutation_summary.py "${SUMMARY_FILE}"
