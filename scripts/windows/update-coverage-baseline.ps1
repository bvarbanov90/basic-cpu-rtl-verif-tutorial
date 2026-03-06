param(
    [string]$CoverageFile = "sim_build/coverage.json",
    [string]$BaselineFile = "docs/coverage-baseline.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "Current coverage file not found: $CoverageFile"
}

$baselineDir = Split-Path -Parent $BaselineFile
if (-not [string]::IsNullOrWhiteSpace($baselineDir)) {
    New-Item -ItemType Directory -Force -Path $baselineDir | Out-Null
}

Copy-Item -Path $CoverageFile -Destination $BaselineFile -Force
Write-Host "Updated coverage baseline: $BaselineFile"
