param(
    [switch]$NoWaves,
    [string]$ProgramHex
)

$impl = Join-Path $PSScriptRoot "windows\\run-wishbone.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE

