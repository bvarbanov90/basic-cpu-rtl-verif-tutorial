#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

bash scripts/run.sh --no-waves
bash scripts/run-mmio.sh --no-waves
bash scripts/run-mmio-wait.sh --no-waves
bash scripts/run-apb.sh --no-waves
bash scripts/run-wishbone.sh --no-waves
bash scripts/run-apb-fault.sh --no-waves
bash scripts/show-coverage.sh
bash scripts/show-apb-coverage.sh
bash scripts/show-wishbone-coverage.sh
bash scripts/show-apb-fault-coverage.sh
bash scripts/show-mmio-wait-coverage.sh
bash scripts/check-coverage-delta.sh
bash scripts/run-asm-corpus.sh --no-simulate
bash scripts/run-asm-corpus.sh --runner apb
bash scripts/run-asm-corpus.sh --runner wishbone
bash scripts/run-asm-corpus.sh --runner mmio_wait

echo "Native simulation checks passed."
