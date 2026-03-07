param(
    [string]$CoreCoverage = "sim_build/coverage.json",
    [string]$MmioCoverage = "sim_build/mmio_coverage.json",
    [string]$HistoryFile = "docs/coverage-history.json",
    [string]$MarkdownFile = "docs/coverage-history.md",
    [string]$Label = "tutorial-regression",
    [int]$Limit = 12,
    [int]$MaxEntries = 64
)

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$impl = Join-Path $PSScriptRoot "windows\\record-coverage-history.ps1"

Push-Location $projectRoot
try {
    & $impl @PSBoundParameters
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
