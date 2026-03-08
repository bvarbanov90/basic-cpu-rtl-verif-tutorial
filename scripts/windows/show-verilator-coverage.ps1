$ErrorActionPreference = "Stop"

$pythonBin = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $py313 = & py -3.13 -c "import sys; print(sys.executable)" 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($py313)) {
        $pythonBin = $py313.Trim()
    }
}
if (-not $pythonBin -and (Get-Command python -ErrorAction SilentlyContinue)) {
    $pythonBin = (Get-Command python).Source
}
if (-not $pythonBin) {
    throw "Python is required to display the Verilator coverage summary."
}

& $pythonBin scripts/verilator_coverage_report.py show @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
