param(
    [switch]$NoSimulate,
    [ValidateSet("direct", "mmio", "mmio_wait", "apb", "wishbone", "axi_lite")]
    [string]$Runner = "direct"
)

$ErrorActionPreference = "Stop"

$pythonCmd = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
    $pythonCmd = @{
        Executable = "py"
        Arguments = @("-3")
    }
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $pythonCmd = @{
        Executable = (Get-Command python).Source
        Arguments = @()
    }
} else {
    throw "Python is required for the assembler corpus runner."
}

$args = @()
$args += $pythonCmd.Arguments
$args += @("scripts/check_asm_corpus.py")
if ($NoSimulate) {
    $args += "--no-simulate"
}
$args += @("--runner", $Runner)

& $pythonCmd.Executable @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
