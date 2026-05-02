#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if command -v python3 >/dev/null 2>&1; then
    python3 scripts/isa_report.py "$@"
else
    echo "python3 is required to generate ISA docs." >&2
    exit 1
fi
