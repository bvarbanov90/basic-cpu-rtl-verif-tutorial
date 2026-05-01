param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonExe = "py"
    $pythonArgs = @("-3.13")
    try {
        & $pythonExe @pythonArgs -c "import sys; sys.exit(0 if sys.version_info < (3, 14) else 1)" *> $null
    } catch {
        $LASTEXITCODE = 1
    }
    if ($LASTEXITCODE -ne 0) {
        $pythonArgs = @("-3.12")
        try {
            & $pythonExe @pythonArgs -c "import sys; sys.exit(0 if sys.version_info < (3, 14) else 1)" *> $null
        } catch {
            $LASTEXITCODE = 1
        }
    }
    if ($LASTEXITCODE -ne 0) {
        $pythonArgs = @("-3")
    }
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonExe = (Get-Command python).Source
    $pythonArgs = @()
} else {
    throw "Python is required to trace the reference model."
}

$args = @()
$args += $pythonArgs
$args += @("scripts/model_trace.py")
$args += $Arguments

& $pythonExe @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
