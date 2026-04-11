param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-cocotb-mmio-wait.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
