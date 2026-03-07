param(
    [string]$Solver = ""
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

$defaultRoot = Join-Path $HOME "tools\\oss-cad-suite\\oss-cad-suite"
Add-ToolPathIfPresent -Root $env:OSS_CAD_SUITE_ROOT
Add-ToolPathIfPresent -Root $defaultRoot

if (-not (Get-Command sby -ErrorAction SilentlyContinue)) {
    throw "sby is required for formal checks. Install OSS CAD Suite and ensure it is on PATH."
}

if ([string]::IsNullOrWhiteSpace($Solver)) {
    if (Get-Command cvc5 -ErrorAction SilentlyContinue) {
        $Solver = "cvc5"
    } elseif (Get-Command z3 -ErrorAction SilentlyContinue) {
        $Solver = "z3"
    } else {
        throw "No supported SMT solver found. Install cvc5 or z3."
    }
}

if (-not (Get-Command $Solver -ErrorAction SilentlyContinue)) {
    throw "Requested solver '$Solver' is not installed or not on PATH."
}

$targets = @(
    @{ Source = "formal/simple_cpu.sby"; OutputDir = "formal/simple_cpu"; Temp = "formal/simple_cpu.$Solver.tmp.sby" },
    @{ Source = "formal/simple_cpu_mmio.sby"; OutputDir = "formal/simple_cpu_mmio"; Temp = "formal/simple_cpu_mmio.$Solver.tmp.sby" }
)

try {
    foreach ($target in $targets) {
        $sbyText = Get-Content $target.Source -Raw
        $updatedText = [regex]::Replace($sbyText, "^smtbmc z3$", "smtbmc $Solver", "Multiline")
        Set-Content -Path $target.Temp -Value $updatedText -Encoding ascii

        & sby -f -d $target.OutputDir $target.Temp
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
} finally {
    foreach ($target in $targets) {
        if (Test-Path $target.Temp) {
            Remove-Item $target.Temp -Force
        }
    }
}

Write-Host "Formal run complete with solver '$Solver'. Artifacts are in formal/simple_cpu/ and formal/simple_cpu_mmio/"
