$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$impl = Join-Path $PSScriptRoot "windows\\check-all.ps1"

Push-Location $projectRoot
try {
    & $impl @args
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
