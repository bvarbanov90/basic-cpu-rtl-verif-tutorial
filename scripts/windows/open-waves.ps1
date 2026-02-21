param(
    [string]$WaveFile = "sim_build/simple_cpu_tb.vcd"
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

function Resolve-OssCadRoot {
    param(
        [string[]]$Candidates
    )

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $bin = Join-Path $candidate "bin"
        $lib = Join-Path $candidate "lib"
        $exe = Join-Path $bin "gtkwave.exe"
        if ((Test-Path $bin) -and (Test-Path $lib) -and (Test-Path $exe)) {
            return $candidate
        }
    }

    return $null
}

function Ensure-GtkwaveIconFallback {
    param(
        [string]$Root
    )

    $svgLoader = Join-Path $Root "lib\\gdk-pixbuf-2.0\\2.10.0\\loaders\\libpixbufloader-svg.dll"
    if (Test-Path $svgLoader) {
        return
    }

    $adwaita = Join-Path $Root "share\\icons\\Adwaita"
    $svgMissing = Join-Path $adwaita "scalable\\status\\image-missing.svg"
    $svgMissingBak = "$svgMissing.bak"
    $svgSymbolic = Join-Path $adwaita "symbolic\\status\\image-missing-symbolic.svg"
    $svgSymbolicBak = "$svgSymbolic.bak"

    if ((Test-Path $svgMissing) -and (-not (Test-Path $svgMissingBak))) {
        Rename-Item $svgMissing (Split-Path $svgMissingBak -Leaf)
    }
    if ((Test-Path $svgSymbolic) -and (-not (Test-Path $svgSymbolicBak))) {
        Rename-Item $svgSymbolic (Split-Path $svgSymbolicBak -Leaf)
    }

    $png16 = Join-Path $adwaita "16x16\\status\\image-missing.png"
    $png16Src = Join-Path $adwaita "16x16\\status\\image-missing-symbolic.symbolic.png"
    if ((-not (Test-Path $png16)) -and (Test-Path $png16Src)) {
        Copy-Item $png16Src $png16
    }

    $png32 = Join-Path $adwaita "32x32\\status\\image-missing.png"
    $png32Src = Join-Path $adwaita "32x32\\status\\image-missing-symbolic.symbolic.png"
    if ((-not (Test-Path $png32)) -and (Test-Path $png32Src)) {
        Copy-Item $png32Src $png32
    }
}

$defaultRoot = Join-Path $HOME "tools\\oss-cad-suite\\oss-cad-suite"
$resolvedRoot = Resolve-OssCadRoot -Candidates @(
    $env:OSS_CAD_SUITE_ROOT,
    $defaultRoot
)

if (-not $resolvedRoot) {
    throw "Could not find OSS CAD Suite root. Run .\\scripts\\install-tools.ps1 first."
}

Add-ToolPathIfPresent -Root $resolvedRoot

$gtkwave = Join-Path $resolvedRoot "bin\\gtkwave.exe"
$libcairo = Join-Path $resolvedRoot "lib\\libcairo-2.dll"
if (-not (Test-Path $gtkwave)) {
    throw "GTKWave executable not found: $gtkwave"
}
if (-not (Test-Path $libcairo)) {
    throw "GTK dependency missing: $libcairo"
}

Ensure-GtkwaveIconFallback -Root $resolvedRoot

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\\..")

# Resolve relative paths from project root so this script works from any CWD.
if (-not [System.IO.Path]::IsPathRooted($WaveFile)) {
    $WaveFile = Join-Path $projectRoot $WaveFile
}

if (-not (Test-Path $WaveFile)) {
    $fallback = Get-ChildItem -Path (Join-Path $projectRoot "sim_build") -Filter *.vcd -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($fallback) {
        $WaveFile = $fallback.FullName
    } else {
        throw "Wave file not found: $WaveFile. Run .\\scripts\\run.ps1 first."
    }
}

$proc = Start-Process -FilePath $gtkwave -ArgumentList $WaveFile -PassThru
Start-Sleep -Milliseconds 600

if ($proc.HasExited) {
    throw "GTKWave exited immediately (code $($proc.ExitCode)). Tried executable: $gtkwave"
}

Write-Host "Opened waveform in GTKWave: $WaveFile"
