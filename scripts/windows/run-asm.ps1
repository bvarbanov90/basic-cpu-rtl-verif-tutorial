param(
    [string]$Source = "programs/logic_flags.asm",
    [switch]$NoWaves
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    throw "python is required to run the assembler."
}

New-Item -ItemType Directory -Force -Path sim_build | Out-Null

$outputHex = "sim_build/program.hex"
python scripts/asm.py $Source -o $outputHex --list

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$runArgs = @{
    ProgramHex = (Resolve-Path $outputHex).Path
}
if ($NoWaves) {
    $runArgs["NoWaves"] = $true
}

.\scripts\run.ps1 @runArgs
