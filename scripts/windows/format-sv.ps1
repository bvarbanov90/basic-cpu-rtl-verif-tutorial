$ErrorActionPreference = "Stop"

function Resolve-ToolPath {
    param(
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }
    }

    return $null
}

$veribleRoot = if ($env:VERIBLE_ROOT) { $env:VERIBLE_ROOT } else { Join-Path $HOME "tools\\verible" }
$veribleFormat = Resolve-ToolPath @(
    (Join-Path $veribleRoot "verible-verilog-format.exe"),
    "verible-verilog-format.exe",
    "verible-verilog-format"
)

if (-not $veribleFormat) {
    throw "verible-verilog-format is required. Run .\\scripts\\install-tools.ps1."
}

$python = Get-Command py -ErrorAction SilentlyContinue
if ($python) {
    & $python.Source -3 scripts/static_analysis.py format --verible-format $veribleFormat
} else {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        throw "Python is required to format the SystemVerilog sources."
    }
    & $python.Source scripts/static_analysis.py format --verible-format $veribleFormat
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
