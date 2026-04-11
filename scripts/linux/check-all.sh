#!/usr/bin/env bash
set -euo pipefail

bash scripts/check-native.sh
bash scripts/lint.sh
bash scripts/show-static-analysis.sh
bash scripts/run-cocotb-verilator.sh --no-waves --coverage
bash scripts/run-cocotb-mmio.sh --no-waves
bash scripts/run-uvm.sh --no-waves
bash scripts/show-verilator-coverage.sh
bash scripts/run-formal.sh --mode all
bash scripts/run-equiv.sh

echo "All checks passed."
