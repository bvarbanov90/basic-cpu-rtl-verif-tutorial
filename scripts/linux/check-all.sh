#!/usr/bin/env bash
set -euo pipefail

bash scripts/check-native.sh
bash scripts/lint.sh
bash scripts/run-formal.sh

echo "All checks passed."
