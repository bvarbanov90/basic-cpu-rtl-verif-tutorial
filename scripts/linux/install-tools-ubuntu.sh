#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "This script needs root privileges. Install sudo or run as root." >&2
        exit 1
    fi
    SUDO="sudo"
fi

${SUDO} apt-get update
${SUDO} apt-get install -y \
    curl \
    g++ \
    iverilog \
    verilator \
    gtkwave \
    yosys \
    cvc5 \
    z3 \
    make \
    python3 \
    python3-pip \
    python3-click \
    python3-venv \
    git \
    tar \
    unzip

TOOLS_ROOT="${HOME}/tools"
VERIBLE_ROOT="${TOOLS_ROOT}/verible"
SVLINT_ROOT="${TOOLS_ROOT}/svlint"

mkdir -p "${TOOLS_ROOT}"

install_latest_release_asset() {
    local repo="$1"
    local asset_regex="$2"
    local target_dir="$3"
    local archive_ext="$4"
    local archive_path
    local release_json
    local download_url

    release_json="$(mktemp)"
    archive_path="$(mktemp)"
    trap 'rm -f "${release_json}" "${archive_path}"' RETURN

    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" -o "${release_json}"
    download_url="$(python3 - "${release_json}" "${asset_regex}" <<'PY'
import json
import re
import sys
from pathlib import Path

release = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
pattern = re.compile(sys.argv[2])
for asset in release.get("assets", []):
    name = asset.get("name", "")
    if pattern.search(name):
        print(asset["browser_download_url"])
        raise SystemExit(0)
raise SystemExit(1)
PY
)"

    rm -rf "${target_dir}"
    mkdir -p "${target_dir}"
    curl -fsSL "${download_url}" -o "${archive_path}"

    case "${archive_ext}" in
        tar.gz)
            tar -xzf "${archive_path}" -C "${target_dir}"
            ;;
        zip)
            unzip -q "${archive_path}" -d "${target_dir}"
            ;;
        *)
            echo "Unsupported archive type: ${archive_ext}" >&2
            exit 1
            ;;
    esac

    rm -f "${release_json}" "${archive_path}"
    trap - RETURN
}

find_verible_lint() {
    if [[ -x "${VERIBLE_ROOT}/bin/verible-verilog-lint" ]]; then
        printf '%s\n' "${VERIBLE_ROOT}/bin/verible-verilog-lint"
        return 0
    fi
    find "${VERIBLE_ROOT}" -maxdepth 3 -type f -name verible-verilog-lint -print -quit 2>/dev/null || true
}

if ! command -v sby >/dev/null 2>&1; then
    tmpdir="$(mktemp -d)"
    git clone --depth 1 https://github.com/YosysHQ/sby "${tmpdir}/sby"
    ${SUDO} make -C "${tmpdir}/sby" install PREFIX=/usr/local
    rm -rf "${tmpdir}"
fi

if [[ -z "$(find_verible_lint)" ]]; then
    install_latest_release_asset \
        "chipsalliance/verible" \
        "linux-static-x86_64\\.tar\\.gz$" \
        "${VERIBLE_ROOT}" \
        "tar.gz"
fi

if [[ ! -x "${SVLINT_ROOT}/bin/svlint" ]]; then
    install_latest_release_asset \
        "dalance/svlint" \
        "x86_64-lnx\\.zip$" \
        "${SVLINT_ROOT}" \
        "zip"
fi

echo "Installed tools for Ubuntu/WSL:"
echo "  g++, iverilog, vvp, verilator, gtkwave, yosys, cvc5, z3, sby"
echo "  verible: ${VERIBLE_ROOT}"
echo "  svlint:  ${SVLINT_ROOT}"
echo "  eqy is resolved by scripts/run-equiv.sh via system PATH or Linux OSS CAD Suite."
