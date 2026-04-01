$ErrorActionPreference = "Stop"

$python = Get-Command py -ErrorAction SilentlyContinue
if ($python) {
    & $python.Source -3 scripts/static_analysis.py show @args
} else {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        throw "Python is required to show the static-analysis summary."
    }
    & $python.Source scripts/static_analysis.py show @args
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
