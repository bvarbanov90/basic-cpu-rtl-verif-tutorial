param(
    [string]$Tag = "latest",
    [switch]$ForceDownload
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$toolsRoot = Join-Path $HOME "tools"
$extractRoot = Join-Path $toolsRoot "oss-cad-suite"
$finalRoot = Join-Path $extractRoot "oss-cad-suite"
$veribleRoot = Join-Path $toolsRoot "verible"
$svlintRoot = Join-Path $toolsRoot "svlint"

New-Item -ItemType Directory -Force -Path $toolsRoot | Out-Null
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null
New-Item -ItemType Directory -Force -Path $veribleRoot | Out-Null
New-Item -ItemType Directory -Force -Path $svlintRoot | Out-Null

function Add-UserPathEntry {
    param(
        [string]$Entry
    )

    if ([string]::IsNullOrWhiteSpace($Entry)) {
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $parts = @()
    } else {
        $parts = $userPath -split ';' | Where-Object { $_ -ne '' }
    }

    if ($parts -notcontains $Entry) {
        $parts += $Entry
        [Environment]::SetEnvironmentVariable("Path", (($parts | Select-Object -Unique) -join ';'), "User")
    }
}

function Install-LatestGitHubReleaseAsset {
    param(
        [string]$Repo,
        [string]$AssetRegex,
        [string]$DestinationRoot
    )

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
    $asset = $release.assets | Where-Object { $_.name -match $AssetRegex } | Select-Object -First 1
    if (-not $asset) {
        throw "No asset matching '$AssetRegex' found for $Repo release '$($release.tag_name)'."
    }

    $archivePath = Join-Path $toolsRoot $asset.name
    if ($ForceDownload -or -not (Test-Path $archivePath)) {
        Write-Host "Downloading $($asset.name) ..."
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archivePath
    }

    if (Test-Path $DestinationRoot) {
        Remove-Item -Recurse -Force $DestinationRoot
    }

    if ($asset.name -match '\.zip$') {
        Expand-Archive -Path $archivePath -DestinationPath $DestinationRoot -Force
    } else {
        throw "Unsupported asset archive for $Repo: $($asset.name)"
    }
}

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

$bin = Join-Path $finalRoot "bin"
$lib = Join-Path $finalRoot "lib"
Install-LatestGitHubReleaseAsset -Repo "chipsalliance/verible" -AssetRegex 'win64\.zip$' -DestinationRoot $veribleRoot
Install-LatestGitHubReleaseAsset -Repo "dalance/svlint" -AssetRegex 'x86_64-win\.zip$' -DestinationRoot $svlintRoot

Add-UserPathEntry -Entry $bin
Add-UserPathEntry -Entry $lib
Add-UserPathEntry -Entry $veribleRoot
Add-UserPathEntry -Entry (Join-Path $svlintRoot "bin")
[Environment]::SetEnvironmentVariable("VERIBLE_ROOT", $veribleRoot, "User")
[Environment]::SetEnvironmentVariable("SVLINT_ROOT", $svlintRoot, "User")

Write-Host "Installed OSS CAD Suite release $($release.tag_name)."
Write-Host "Tools root: $finalRoot"
Write-Host "Verible root: $veribleRoot"
Write-Host "svlint root:  $svlintRoot"
Write-Host "User PATH updated with:"
Write-Host "  $bin"
Write-Host "  $lib"
Write-Host "  $veribleRoot"
Write-Host "  $(Join-Path $svlintRoot 'bin')"
Write-Host "For cocotb/pyuvm, also install Python 3.13 and either GNU Make or use WSL Ubuntu."
Write-Host "The Verilator cocotb and EQY flows on Windows prefer WSL Ubuntu for the Linux-side toolchain."
Write-Host "Open a new terminal to pick up updated user environment."
