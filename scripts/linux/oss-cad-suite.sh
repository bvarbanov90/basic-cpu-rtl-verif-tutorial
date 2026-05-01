#!/usr/bin/env bash

OSS_CAD_SUITE_REPO="${OSS_CAD_SUITE_REPO:-YosysHQ/oss-cad-suite-build}"
OSS_CAD_SUITE_RELEASE_TAG="${OSS_CAD_SUITE_RELEASE_TAG:-latest}"
OSS_CAD_SUITE_DOWNLOAD_RETRIES="${OSS_CAD_SUITE_DOWNLOAD_RETRIES:-5}"
OSS_SUITE_ROOT="${OSS_CAD_SUITE_ROOT:-$HOME/tools/oss-cad-suite/oss-cad-suite}"

oss_cad_suite_prepend_path() {
    export PATH="${OSS_SUITE_ROOT}/bin:${OSS_SUITE_ROOT}/lib:${PATH}"
}

oss_cad_suite_release_label() {
    if [[ "${OSS_CAD_SUITE_RELEASE_TAG}" == "latest" || -z "${OSS_CAD_SUITE_RELEASE_TAG}" ]]; then
        printf 'latest'
    else
        printf '%s' "${OSS_CAD_SUITE_RELEASE_TAG}"
    fi
}

oss_cad_suite_resolve_linux_x64_asset() {
    python3 - "${OSS_CAD_SUITE_REPO}" "$(oss_cad_suite_release_label)" "${OSS_CAD_SUITE_DOWNLOAD_RETRIES}" <<'PY'
import json
import sys
import time
import urllib.error
import urllib.request


repo, release_tag, retries_text = sys.argv[1:4]
retries = max(1, int(retries_text))
if release_tag == "latest":
    api_url = f"https://api.github.com/repos/{repo}/releases/latest"
else:
    api_url = f"https://api.github.com/repos/{repo}/releases/tags/{release_tag}"

last_error = None
for attempt in range(1, retries + 1):
    try:
        request = urllib.request.Request(
            api_url,
            headers={
                "Accept": "application/vnd.github+json",
                "User-Agent": "basic-cpu-rtl-verif-tutorial",
            },
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            release = json.loads(response.read().decode("utf-8"))
        break
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        last_error = exc
        if attempt == retries:
            raise SystemExit(f"Could not query OSS CAD Suite release {release_tag}: {exc}")
        time.sleep(min(2 * attempt, 10))
else:
    raise SystemExit(f"Could not query OSS CAD Suite release {release_tag}: {last_error}")

for asset in release.get("assets", []):
    name = asset.get("name", "")
    if name.startswith("oss-cad-suite-linux-x64-") and (name.endswith(".tgz") or name.endswith(".tar.xz")):
        print(asset["browser_download_url"])
        print(name)
        print(release.get("tag_name", release_tag))
        raise SystemExit(0)

raise SystemExit(f"No linux-x64 OSS CAD Suite asset found in release {release.get('tag_name', release_tag)}.")
PY
}

oss_cad_suite_download() {
    local url="$1"
    local output="$2"

    python3 - "${url}" "${output}" "${OSS_CAD_SUITE_DOWNLOAD_RETRIES}" <<'PY'
import os
import sys
import time
import urllib.error
import urllib.request


url, output, retries_text = sys.argv[1:4]
retries = max(1, int(retries_text))
tmp_output = f"{output}.tmp"

last_error = None
for attempt in range(1, retries + 1):
    try:
        request = urllib.request.Request(
            url,
            headers={"User-Agent": "basic-cpu-rtl-verif-tutorial"},
        )
        with urllib.request.urlopen(request, timeout=120) as response:
            with open(tmp_output, "wb") as target:
                while True:
                    chunk = response.read(1024 * 1024)
                    if not chunk:
                        break
                    target.write(chunk)
        os.replace(tmp_output, output)
        raise SystemExit(0)
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        last_error = exc
        try:
            os.remove(tmp_output)
        except FileNotFoundError:
            pass
        if attempt == retries:
            raise SystemExit(f"Could not download OSS CAD Suite asset after {retries} attempts: {exc}")
        time.sleep(min(2 * attempt, 10))

raise SystemExit(f"Could not download OSS CAD Suite asset: {last_error}")
PY
}

ensure_linux_oss_cad_suite() {
    local required_tool="$1"
    local reason="${2:-${required_tool} is not available}"
    local force_install="${3:-0}"
    local tmpdir
    local archive
    local asset_url
    local asset_name
    local resolved_tag

    if [[ "${force_install}" != "1" && -x "${OSS_SUITE_ROOT}/bin/${required_tool}" ]]; then
        oss_cad_suite_prepend_path
        return
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        echo "python3 is required to install Linux OSS CAD Suite." >&2
        exit 1
    fi

    tmpdir="$(mktemp -d)"
    mapfile -t ASSET_INFO < <(oss_cad_suite_resolve_linux_x64_asset)
    asset_url="${ASSET_INFO[0]}"
    asset_name="${ASSET_INFO[1]}"
    resolved_tag="${ASSET_INFO[2]}"
    archive="${tmpdir}/${asset_name}"

    echo "Installing Linux OSS CAD Suite ${resolved_tag} because ${reason}."
    oss_cad_suite_download "${asset_url}" "${archive}"

    mkdir -p "$(dirname "${OSS_SUITE_ROOT}")"
    rm -rf "${OSS_SUITE_ROOT}"
    tar -C "$(dirname "${OSS_SUITE_ROOT}")" -xf "${archive}"
    rm -rf "${tmpdir}"

    if [[ ! -x "${OSS_SUITE_ROOT}/bin/${required_tool}" ]]; then
        echo "Installed OSS CAD Suite, but ${required_tool} was not found at ${OSS_SUITE_ROOT}/bin/${required_tool}." >&2
        exit 1
    fi

    oss_cad_suite_prepend_path
}
