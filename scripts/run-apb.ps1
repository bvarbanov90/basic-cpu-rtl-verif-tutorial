param(
    [switch]$NoWaves,
    [string]$ProgramHex
)

$impl = Join-Path $PSScriptRoot "windows\\run-apb.ps1"
& $impl @PSBoundParameters
exit $LASTEXITCODE
