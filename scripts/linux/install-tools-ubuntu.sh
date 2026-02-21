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
    iverilog \
    verilator \
    gtkwave \
    yosys \
    cvc5 \
    z3 \
    make \
    python3 \
    python3-pip \
    git

if ! command -v sby >/dev/null 2>&1; then
    tmpdir="$(mktemp -d)"
    git clone --depth 1 https://github.com/YosysHQ/sby "${tmpdir}/sby"
    ${SUDO} make -C "${tmpdir}/sby" install PREFIX=/usr/local
    rm -rf "${tmpdir}"
fi

echo "Installed tools for Ubuntu/WSL:"
echo "  iverilog, vvp, verilator, gtkwave, yosys, cvc5, z3, sby"
