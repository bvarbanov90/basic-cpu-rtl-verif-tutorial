#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: bash scripts/run-cocotb-verilator.sh [--no-waves] [--coverage]
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

MIN_VERILATOR_VERSION="5.036"
OSS_SUITE_ROOT="${OSS_CAD_SUITE_ROOT:-$HOME/tools/oss-cad-suite/oss-cad-suite}"

NO_WAVES=0
ENABLE_COVERAGE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-waves)
            NO_WAVES=1
            shift
            ;;
        --coverage)
            ENABLE_COVERAGE=1
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

version_at_least() {
    local actual="$1"
    local minimum="$2"

    python3 - "$actual" "$minimum" <<'PY'
import sys


def parse(version: str) -> list[int]:
    return [int(part) for part in version.split(".")]


actual = parse(sys.argv[1])
minimum = parse(sys.argv[2])
width = max(len(actual), len(minimum))
actual += [0] * (width - len(actual))
minimum += [0] * (width - len(minimum))
raise SystemExit(0 if tuple(actual) >= tuple(minimum) else 1)
PY
}

verilator_version() {
    local tool="$1"
    "${tool}" --version | awk '{print $2}'
}

ensure_linux_oss_suite_verilator() {
    local suite_bin
    local suite_verilator
    local suite_version
    local tmpdir
    local archive
    local asset_url
    local asset_name

    suite_bin="${OSS_SUITE_ROOT}/bin"
    suite_verilator="${suite_bin}/verilator"

    if [[ -x "${suite_verilator}" ]]; then
        suite_version="$(verilator_version "${suite_verilator}")"
        if version_at_least "${suite_version}" "${MIN_VERILATOR_VERSION}"; then
            export PATH="${suite_bin}:${OSS_SUITE_ROOT}/lib:${PATH}"
            return
        fi
    fi

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"' RETURN

    mapfile -t ASSET_INFO < <(python3 - <<'PY'
import json
import urllib.request

release = json.load(urllib.request.urlopen("https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest"))
for asset in release["assets"]:
    name = asset["name"]
    if name.startswith("oss-cad-suite-linux-x64-") and (name.endswith(".tgz") or name.endswith(".tar.xz")):
        print(asset["browser_download_url"])
        print(name)
        break
else:
    raise SystemExit("No linux-x64 OSS CAD Suite asset found in the latest release.")
PY
)

    asset_url="${ASSET_INFO[0]}"
    asset_name="${ASSET_INFO[1]}"
    archive="${tmpdir}/${asset_name}"

    echo "Installing Linux OSS CAD Suite because system Verilator is older than ${MIN_VERILATOR_VERSION}."
    python3 - "${asset_url}" "${archive}" <<'PY'
import sys
import urllib.request

urllib.request.urlretrieve(sys.argv[1], sys.argv[2])
PY

    mkdir -p "$(dirname "${OSS_SUITE_ROOT}")"
    rm -rf "${OSS_SUITE_ROOT}"
    tar -C "$(dirname "${OSS_SUITE_ROOT}")" -xf "${archive}"

    export PATH="${suite_bin}:${OSS_SUITE_ROOT}/lib:${PATH}"
}

if ! command -v make >/dev/null 2>&1; then
    echo "make is required for cocotb/Verilator runs." >&2
    exit 1
fi

if command -v verilator >/dev/null 2>&1; then
    SYSTEM_VERILATOR_VERSION="$(verilator_version "$(command -v verilator)")"
    if ! version_at_least "${SYSTEM_VERILATOR_VERSION}" "${MIN_VERILATOR_VERSION}"; then
        ensure_linux_oss_suite_verilator
    fi
else
    ensure_linux_oss_suite_verilator
fi

if ! command -v verilator >/dev/null 2>&1; then
    echo "verilator is required for cocotb/Verilator runs." >&2
    exit 1
fi

ACTIVE_VERILATOR_VERSION="$(verilator_version "$(command -v verilator)")"
if ! version_at_least "${ACTIVE_VERILATOR_VERSION}" "${MIN_VERILATOR_VERSION}"; then
    echo "cocotb requires Verilator ${MIN_VERILATOR_VERSION} or later, but found ${ACTIVE_VERILATOR_VERSION}." >&2
    exit 1
fi

if ! command -v g++ >/dev/null 2>&1; then
    echo "g++ is required for cocotb/Verilator runs." >&2
    exit 1
fi

PYTHON_BIN=""
if [[ -x ".venv/bin/python" ]]; then
    PYTHON_BIN=".venv/bin/python"
elif [[ -x ".venv_pyuvm_probe/bin/python" ]]; then
    PYTHON_BIN=".venv_pyuvm_probe/bin/python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
else
    echo "python3 is required for cocotb/Verilator runs." >&2
    exit 1
fi

if ! "${PYTHON_BIN}" - <<'PY' >/dev/null 2>&1
import sys
assert sys.version_info < (3, 14)
import cocotb
PY
then
    echo "Python < 3.14 with cocotb is required. Install with: python3 -m pip install -r requirements.txt" >&2
    exit 1
fi

mkdir -p sim_build

if [[ -n "${PYTHONPATH:-}" ]]; then
    export PYTHONPATH="${PROJECT_ROOT}:${PYTHONPATH}"
else
    export PYTHONPATH="${PROJECT_ROOT}"
fi

PYTHON_BIN_DIR="$(cd -- "$(dirname -- "${PYTHON_BIN}")" && pwd)"
export PATH="${PYTHON_BIN_DIR}:${PATH}"

WAVES_VALUE=1
if [[ "${NO_WAVES}" -eq 1 ]]; then
    WAVES_VALUE=0
fi

EXTRA_ARGS_VALUE=""
SIM_ARGS_VALUE=""
if [[ "${ENABLE_COVERAGE}" -eq 1 ]]; then
    EXTRA_ARGS_VALUE="--coverage"
    SIM_ARGS_VALUE="+verilator+coverage+file+sim_build/verilator_cocotb/coverage.dat"
fi

make -f Makefile \
    SIM=verilator \
    PYTHON_BIN="${PYTHON_BIN}" \
    COCOTB_TEST_MODULES=tb.test_simple_cpu \
    WAVES="${WAVES_VALUE}" \
    EXTRA_ARGS="${EXTRA_ARGS_VALUE}" \
    SIM_ARGS="${SIM_ARGS_VALUE}" \
    SIM_BUILD=sim_build/verilator_cocotb \
    COCOTB_RESULTS_FILE=sim_build/verilator_results.xml

echo "cocotb + Verilator run complete."
echo "Results XML: sim_build/verilator_results.xml"

if [[ "${ENABLE_COVERAGE}" -eq 1 ]]; then
    if ! command -v verilator_coverage >/dev/null 2>&1; then
        echo "verilator_coverage is required to post-process Verilator coverage." >&2
        exit 1
    fi

    mapfile -t DATAFILES < <(find sim_build/verilator_cocotb -name coverage.dat -type f | sort)
    if [[ "${#DATAFILES[@]}" -eq 0 ]]; then
        echo "No Verilator coverage.dat files were produced under sim_build/verilator_cocotb." >&2
        exit 1
    fi

    OUTPUT_DIR="sim_build/verilator_coverage"
    ANNOTATED_DIR="${OUTPUT_DIR}/annotated"
    MERGED_DAT="${OUTPUT_DIR}/merged.dat"
    OVERALL_INFO="${OUTPUT_DIR}/overall.info"
    LINE_INFO="${OUTPUT_DIR}/line.info"
    TOGGLE_INFO="${OUTPUT_DIR}/toggle.info"
    EXPR_INFO="${OUTPUT_DIR}/expr.info"
    SUMMARY_JSON="${OUTPUT_DIR}/summary.json"
    SUMMARY_MD="${OUTPUT_DIR}/summary.md"

    rm -rf "${OUTPUT_DIR}"
    mkdir -p "${ANNOTATED_DIR}"

    verilator_coverage --write "${MERGED_DAT}" "${DATAFILES[@]}"
    verilator_coverage --write-info "${OVERALL_INFO}" "${MERGED_DAT}"
    verilator_coverage --filter-type line --write-info "${LINE_INFO}" "${MERGED_DAT}"
    verilator_coverage --filter-type toggle --write-info "${TOGGLE_INFO}" "${MERGED_DAT}"
    verilator_coverage --filter-type expr --write-info "${EXPR_INFO}" "${MERGED_DAT}"
    verilator_coverage --annotate "${ANNOTATED_DIR}" "${MERGED_DAT}"

    "${PYTHON_BIN}" scripts/verilator_coverage_report.py build \
        --overall "${OVERALL_INFO}" \
        --line "${LINE_INFO}" \
        --toggle "${TOGGLE_INFO}" \
        --expr "${EXPR_INFO}" \
        --merged-dat "${MERGED_DAT}" \
        --annotated-dir "${ANNOTATED_DIR}" \
        --summary-json "${SUMMARY_JSON}" \
        --summary-markdown "${SUMMARY_MD}"
fi
