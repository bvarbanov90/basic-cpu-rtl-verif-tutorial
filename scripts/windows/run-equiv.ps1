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

$wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
if ($wslCmd) {
    $wslProjectRoot = Convert-WindowsPathToWslPath -WindowsPath (Resolve-Path ".").Path
    Write-Host "Routing equivalence check through WSL/Linux for EQY stability."
    & $wslCmd.Source bash -lc "cd '$wslProjectRoot' && bash scripts/run-equiv.sh"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    return
}

if (-not (Get-Command eqy -ErrorAction SilentlyContinue)) {
    throw "eqy is required for equivalence checks. Install OSS CAD Suite or WSL Ubuntu tooling and ensure it is on PATH."
}

& eqy -f -d equiv/simple_cpu_eqy equiv/simple_cpu.eqy
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Equivalence run complete. Artifacts are in equiv/simple_cpu_eqy/"
