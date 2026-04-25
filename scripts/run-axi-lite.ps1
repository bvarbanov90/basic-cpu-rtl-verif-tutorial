param(
    [switch]$NoWaves,
    [string]$ProgramHex
)

$impl = Join-Path $PSScriptRoot "windows\\run-axi-lite.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE


