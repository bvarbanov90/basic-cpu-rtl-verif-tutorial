#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if command -v python3 >/dev/null 2>&1; then
    python3 scripts/coverage_goals.py "$@"
else
    echo "python3 is required to generate the coverage goals catalog." >&2
    exit 1
fi
