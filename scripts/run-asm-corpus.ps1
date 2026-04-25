param(
    [switch]$NoSimulate,
    [ValidateSet("direct", "mmio", "mmio_wait", "apb", "wishbone", "axi_lite")]
    [string]$Runner = "direct"
)

$ErrorActionPreference = "Stop"
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$impl = Join-Path $PSScriptRoot "windows\\run-asm-corpus.ps1"

Push-Location $projectRoot
try {
    & $impl @PSBoundParameters
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}
