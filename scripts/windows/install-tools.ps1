param(
    [string]$Tag = "latest",
    [switch]$ForceDownload
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$toolsRoot = Join-Path $HOME "tools"
$extractRoot = Join-Path $toolsRoot "oss-cad-suite"
$finalRoot = Join-Path $extractRoot "oss-cad-suite"

New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null

$releaseApi = if ($Tag -eq "latest") {
    "https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/latest"
} else {
    "https://api.github.com/repos/YosysHQ/oss-cad-suite-build/releases/tags/$Tag"
}

$release = Invoke-RestMethod -Uri $releaseApi
$asset = $release.assets | Where-Object { $_.name -match '^oss-cad-suite-windows-x64-.*\.exe$' } | Select-Object -First 1

if (-not $asset) {
    throw "No Windows x64 OSS CAD Suite asset found for release '$($release.tag_name)'."
}

$downloadPath = Join-Path $toolsRoot $asset.name
if ($ForceDownload -or -not (Test-Path $downloadPath)) {
    Write-Host "Downloading $($asset.name) ..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadPath
}

Write-Host "Extracting to $extractRoot ..."
& $downloadPath x "-o$extractRoot" -y | Out-Null

[Environment]::SetEnvironmentVariable("OSS_CAD_SUITE_ROOT", $finalRoot, "User")

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ([string]::IsNullOrWhiteSpace($userPath)) {
    $parts = @()
} else {
    $parts = $userPath -split ';' | Where-Object { $_ -ne '' }
}

$bin = Join-Path $finalRoot "bin"
$lib = Join-Path $finalRoot "lib"

if ($parts -notcontains $bin) { $parts += $bin }
if ($parts -notcontains $lib) { $parts += $lib }

$newPath = ($parts | Select-Object -Unique) -join ';'
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")

Write-Host "Installed OSS CAD Suite release $($release.tag_name)."
Write-Host "Tools root: $finalRoot"
Write-Host "User PATH updated with:"
Write-Host "  $bin"
Write-Host "  $lib"
Write-Host "For cocotb/pyuvm, also install Python 3.13 and either GNU Make or use WSL Ubuntu."
Write-Host "The Verilator cocotb and EQY flows on Windows prefer WSL Ubuntu for the Linux-side toolchain."
Write-Host "Open a new terminal to pick up updated user environment."
