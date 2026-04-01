$ErrorActionPreference = "Stop"

function Add-ToolPathIfPresent {
    param(
        [string]$Root
    )

    if ([string]::IsNullOrWhiteSpace($Root)) {
        return
    }

    $bin = Join-Path $Root "bin"
    $lib = Join-Path $Root "lib"
    if ((Test-Path $bin) -and (Test-Path $lib)) {
        if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $bin })) {
            $env:PATH = "$bin;$env:PATH"
        }
        if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $lib })) {
            $env:PATH = "$lib;$env:PATH"
        }
    }
}

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

$defaultRoot = Join-Path $HOME "tools\\oss-cad-suite\\oss-cad-suite"
Add-ToolPathIfPresent -Root $env:OSS_CAD_SUITE_ROOT
Add-ToolPathIfPresent -Root $defaultRoot

$veribleRoot = if ($env:VERIBLE_ROOT) { $env:VERIBLE_ROOT } else { Join-Path $HOME "tools\\verible" }
$svlintRoot = if ($env:SVLINT_ROOT) { $env:SVLINT_ROOT } else { Join-Path $HOME "tools\\svlint" }
$verilatorBin = Resolve-ToolPath @(
    (Join-Path $defaultRoot "bin\\verilator_bin.exe"),
    "verilator_bin.exe",
    "verilator"
)

if (-not $verilatorBin) {
    throw "verilator is required for linting."
}

$veribleLint = Resolve-ToolPath @(
    (Join-Path $veribleRoot "verible-verilog-lint.exe"),
    "verible-verilog-lint.exe",
    "verible-verilog-lint"
)
$veribleFormat = Resolve-ToolPath @(
    (Join-Path $veribleRoot "verible-verilog-format.exe"),
    "verible-verilog-format.exe",
    "verible-verilog-format"
)
$svlint = Resolve-ToolPath @(
    (Join-Path $svlintRoot "bin\\svlint.exe"),
    "svlint.exe",
    "svlint"
)

if (-not $veribleLint -or -not $veribleFormat) {
    throw "verible-verilog-lint and verible-verilog-format are required. Run .\\scripts\\install-tools.ps1."
}

if (-not $svlint) {
    throw "svlint is required. Run .\\scripts\\install-tools.ps1."
}

$python = Get-Command py -ErrorAction SilentlyContinue
if ($python) {
    & $python.Source -3 scripts/static_analysis.py run `
        --verilator $verilatorBin `
        --verible-lint $veribleLint `
        --verible-format $veribleFormat `
        --svlint $svlint
} else {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        throw "Python is required to run the static-analysis summary."
    }
    & $python.Source scripts/static_analysis.py run `
        --verilator $verilatorBin `
        --verible-lint $veribleLint `
        --verible-format $veribleFormat `
        --svlint $svlint
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
