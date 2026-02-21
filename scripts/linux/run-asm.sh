#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/run-asm.sh [--source <asm-file>] [--no-waves]
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

SOURCE="programs/logic_flags.asm"
NO_WAVES=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            if [[ $# -lt 2 ]]; then
                usage
                exit 2
            fi
            SOURCE="$2"
            shift 2
            ;;
        --no-waves)
            NO_WAVES=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to run the assembler." >&2
    exit 1
fi

mkdir -p sim_build

OUTPUT_HEX="sim_build/program.hex"
python3 scripts/asm.py "${SOURCE}" -o "${OUTPUT_HEX}" --list

RUN_ARGS=(--program-hex "${OUTPUT_HEX}")
if [[ "${NO_WAVES}" -eq 1 ]]; then
    RUN_ARGS+=(--no-waves)
fi

bash scripts/run.sh "${RUN_ARGS[@]}"
