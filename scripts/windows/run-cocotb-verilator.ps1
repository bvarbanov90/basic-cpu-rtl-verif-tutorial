param(
    [switch]$NoWaves,
    [switch]$Coverage
)

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

function Convert-WindowsPathToWslPath {
    param(
        [string]$WindowsPath
    )

    if ($WindowsPath -match '^([A-Za-z]):\\(.*)$') {
        $drive = $matches[1].ToLowerInvariant()
        $rest = $matches[2] -replace '\\', '/'
        return "/mnt/$drive/$rest"
    }

    throw "Could not convert Windows path to WSL path: $WindowsPath"
}

$defaultRoot = Join-Path $HOME "tools\\oss-cad-suite\\oss-cad-suite"
Add-ToolPathIfPresent -Root $env:OSS_CAD_SUITE_ROOT
Add-ToolPathIfPresent -Root $defaultRoot

$makeCmd = Get-Command make -ErrorAction SilentlyContinue
$gppCmd = Get-Command g++ -ErrorAction SilentlyContinue
if (-not $makeCmd -or -not $gppCmd) {
    $wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslCmd) {
        $wslProjectRoot = Convert-WindowsPathToWslPath -WindowsPath (Resolve-Path ".").Path
        $argsList = @()
        if ($NoWaves) {
            $argsList += "--no-waves"
        }
        if ($Coverage) {
            $argsList += "--coverage"
        }
        $joinedArgs = $argsList -join " "
        Write-Host "Native make/g++ was not found. Falling back to WSL for the cocotb + Verilator run."
        & $wslCmd.Source bash -lc "cd '$wslProjectRoot' && bash scripts/run-cocotb-verilator.sh $joinedArgs"
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        return
    }

    throw "make and g++ are required for native cocotb + Verilator runs. Install them or use WSL."
}

if (-not (Get-Command verilator -ErrorAction SilentlyContinue)) {
    throw "verilator is required for cocotb + Verilator runs."
}

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
    throw "Python is required for cocotb + Verilator runs. Install Python 3.13 and retry."
}

$pythonDir = Split-Path -Parent $pythonBin
$pythonScriptsDir = Join-Path $pythonDir "Scripts"
if (Test-Path $pythonScriptsDir) {
    if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $pythonScriptsDir })) {
        $env:PATH = "$pythonScriptsDir;$env:PATH"
    }
}

& $pythonBin -c "import sys; assert sys.version_info < (3,14); import cocotb" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Python < 3.14 with cocotb is required. Install with: py -3.13 -m pip install -r requirements.txt"
}

New-Item -ItemType Directory -Force -Path sim_build | Out-Null

$projectRoot = (Resolve-Path ".").Path
if ([string]::IsNullOrWhiteSpace($env:PYTHONPATH)) {
    $env:PYTHONPATH = $projectRoot
} else {
    $env:PYTHONPATH = "$projectRoot;$env:PYTHONPATH"
}

$env:COCOTB_TEST_MODULES = "tb.test_simple_cpu"
$env:SIM = "verilator"
$env:SIM_BUILD = "sim_build/verilator_cocotb"
$env:COCOTB_RESULTS_FILE = "sim_build/verilator_results.xml"
$env:WAVES = if ($NoWaves) { "0" } else { "1" }
$env:EXTRA_ARGS = if ($Coverage) { "--coverage" } else { "" }
$env:SIM_ARGS = if ($Coverage) { "+verilator+coverage+file+sim_build/verilator_cocotb/coverage.dat" } else { "" }
$env:PYTHON_BIN = $pythonBin

& $makeCmd.Source -f Makefile
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "cocotb + Verilator run complete."
Write-Host "Results XML: sim_build/verilator_results.xml"

if ($Coverage) {
    $verilatorCoverage = Get-Command verilator_coverage -ErrorAction SilentlyContinue
    if (-not $verilatorCoverage) {
        throw "verilator_coverage is required to post-process Verilator coverage."
    }

    $dataFiles = Get-ChildItem -Path sim_build/verilator_cocotb -Recurse -Filter coverage.dat | Sort-Object FullName
    if (-not $dataFiles) {
        throw "No Verilator coverage.dat files were produced under sim_build/verilator_cocotb."
    }

    $outputDir = "sim_build/verilator_coverage"
    $annotatedDir = Join-Path $outputDir "annotated"
    $mergedDat = Join-Path $outputDir "merged.dat"
    $overallInfo = Join-Path $outputDir "overall.info"
    $lineInfo = Join-Path $outputDir "line.info"
    $toggleInfo = Join-Path $outputDir "toggle.info"
    $exprInfo = Join-Path $outputDir "expr.info"
    $summaryJson = Join-Path $outputDir "summary.json"
    $summaryMarkdown = Join-Path $outputDir "summary.md"

    if (Test-Path $outputDir) {
        Remove-Item -Recurse -Force $outputDir
    }
    New-Item -ItemType Directory -Force -Path $annotatedDir | Out-Null

    & $verilatorCoverage.Source --write $mergedDat ($dataFiles | ForEach-Object { $_.FullName })
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $verilatorCoverage.Source --write-info $overallInfo $mergedDat
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $verilatorCoverage.Source --filter-type line --write-info $lineInfo $mergedDat
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $verilatorCoverage.Source --filter-type toggle --write-info $toggleInfo $mergedDat
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $verilatorCoverage.Source --filter-type expr --write-info $exprInfo $mergedDat
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $verilatorCoverage.Source --annotate $annotatedDir $mergedDat
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & $pythonBin scripts/verilator_coverage_report.py build `
        --overall $overallInfo `
        --line $lineInfo `
        --toggle $toggleInfo `
        --expr $exprInfo `
        --merged-dat $mergedDat `
        --annotated-dir $annotatedDir `
        --summary-json $summaryJson `
        --summary-markdown $summaryMarkdown
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
