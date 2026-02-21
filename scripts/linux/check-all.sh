#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

bash scripts/run.sh --no-waves
bash scripts/lint.sh
bash scripts/run-formal.sh
bash scripts/show-coverage.sh

echo "All checks passed."
