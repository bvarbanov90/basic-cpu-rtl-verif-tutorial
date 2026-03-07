#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for the mutation campaign." >&2
    exit 1
fi

if ! command -v iverilog >/dev/null 2>&1; then
    echo "iverilog is required for the mutation campaign." >&2
    exit 1
fi

if ! command -v vvp >/dev/null 2>&1; then
    echo "vvp is required for the mutation campaign." >&2
    exit 1
fi

python3 scripts/run_mutation_campaign.py
