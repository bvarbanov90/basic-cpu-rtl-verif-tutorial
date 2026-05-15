#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

if command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
else
    echo "python3 is required to check generated docs." >&2
    exit 1
fi

checks=(
    scripts/isa_report.py
    scripts/asm_corpus_report.py
    scripts/mutation_catalog.py
    scripts/formal_catalog.py
    scripts/script_catalog.py
    scripts/ci_catalog.py
    scripts/tooling_catalog.py
    scripts/verification_matrix.py
    scripts/artifact_catalog.py
    scripts/requirements_traceability.py
    scripts/documentation_index.py
    scripts/coverage_goals.py
    scripts/register_map.py
    scripts/protocol_catalog.py
    scripts/adapter_contract.py
    scripts/reference_regression_catalog.py
    scripts/semantic_vectors.py
)

for check in "${checks[@]}"; do
    "${PYTHON_BIN}" "${check}" --check "$@"
done

echo "Generated documentation checks passed."
