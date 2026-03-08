#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

OSS_SUITE_ROOT="${OSS_CAD_SUITE_ROOT:-$HOME/tools/oss-cad-suite/oss-cad-suite}"

ensure_linux_oss_suite() {
    local tmpdir
    local archive
    local asset_url
    local asset_name

    if [[ -x "${OSS_SUITE_ROOT}/bin/eqy" ]]; then
        export PATH="${OSS_SUITE_ROOT}/bin:${OSS_SUITE_ROOT}/lib:${PATH}"
        return
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

    echo "Installing Linux OSS CAD Suite because eqy is not available."
    python3 - "${asset_url}" "${archive}" <<'PY'
import sys
import urllib.request

urllib.request.urlretrieve(sys.argv[1], sys.argv[2])
PY

    mkdir -p "$(dirname "${OSS_SUITE_ROOT}")"
    rm -rf "${OSS_SUITE_ROOT}"
    tar -C "$(dirname "${OSS_SUITE_ROOT}")" -xf "${archive}"
    export PATH="${OSS_SUITE_ROOT}/bin:${OSS_SUITE_ROOT}/lib:${PATH}"
}

if ! command -v eqy >/dev/null 2>&1; then
    ensure_linux_oss_suite
fi

if ! command -v eqy >/dev/null 2>&1; then
    echo "eqy is required for equivalence checks. Install EQY and retry." >&2
    exit 1
fi

eqy -f -d equiv/simple_cpu_eqy equiv/simple_cpu.eqy

echo "Equivalence run complete. Artifacts are in equiv/simple_cpu_eqy/"
