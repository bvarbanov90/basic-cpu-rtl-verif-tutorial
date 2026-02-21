param(
    [string]$CoverageFile = "sim_build/coverage.json"
)

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$impl = Join-Path $PSScriptRoot "windows\\show-coverage.ps1"

Push-Location $projectRoot
try {
    & $impl @PSBoundParameters
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
