param(
    [switch]$NoWaves
)

$impl = Join-Path $PSScriptRoot "windows\\run-wishbone-fault.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE



