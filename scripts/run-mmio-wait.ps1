param(
    [switch]$NoWaves,
    [string]$ProgramHex
)

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$impl = Join-Path $PSScriptRoot "windows\\run-mmio-wait.ps1"

Push-Location $projectRoot
try {
    & $impl @PSBoundParameters
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
