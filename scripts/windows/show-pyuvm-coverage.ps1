param(
    [string]$CoverageFile = "sim_build/pyuvm_coverage.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "pyuvm coverage file not found: $CoverageFile. Run .\scripts\run-uvm.ps1 -NoWaves first."
}

$impl = Join-Path $PSScriptRoot "show-coverage.ps1"
& $impl -CoverageFile $CoverageFile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
