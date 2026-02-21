param(
    [string]$CoverageFile = "sim_build/coverage.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "Coverage file not found: $CoverageFile. Run .\\scripts\\run.ps1 first."
}

$cov = Get-Content -Raw $CoverageFile | ConvertFrom-Json

Write-Host "Coverage Summary"
Write-Host "  pass:               $($cov.coverage_pass)"
Write-Host "  opcode_hit_bitmap:  $($cov.opcode_hit_bitmap)"
Write-Host "  illegal_opcode_hit: $($cov.illegal_opcode_hit)"
Write-Host "  jz_taken:           $($cov.jz_taken)"
Write-Host "  jz_not_taken:       $($cov.jz_not_taken)"
Write-Host "  zero_transition_00: $($cov.zero_transition_00)"
Write-Host "  zero_transition_01: $($cov.zero_transition_01)"
Write-Host "  zero_transition_10: $($cov.zero_transition_10)"
Write-Host "  zero_transition_11: $($cov.zero_transition_11)"
Write-Host "  carry_0:           $($cov.carry_0)"
Write-Host "  carry_1:           $($cov.carry_1)"
Write-Host "  neg_0:             $($cov.neg_0)"
Write-Host "  neg_1:             $($cov.neg_1)"
Write-Host "  overflow_0:        $($cov.overflow_0)"
Write-Host "  overflow_1:        $($cov.overflow_1)"
Write-Host "  program_runs:       $($cov.program_runs)"
Write-Host "  total_cycles:       $($cov.total_cycles)"

Write-Host ""
Write-Host "Opcode Hit Details"
$cov.opcode_hits.PSObject.Properties |
    Sort-Object { [int]$_.Name } |
    ForEach-Object {
        Write-Host ("  opcode_{0}: {1}" -f $_.Name, $_.Value)
    }

if ($cov.opcode_counts) {
    Write-Host ""
    Write-Host "Opcode Execution Counts"
    $cov.opcode_counts.PSObject.Properties |
        Sort-Object { [int]$_.Name } |
        ForEach-Object {
            Write-Host ("  opcode_{0}_count: {1}" -f $_.Name, $_.Value)
        }
}

if ($cov.opcode_zero_cross) {
    Write-Host ""
    Write-Host "Opcode x ZERO Cross (post-instruction ZERO)"
    $cov.opcode_zero_cross.PSObject.Properties |
        Sort-Object { [int]$_.Name } |
        ForEach-Object {
            $name = $_.Name
            $zero0 = $_.Value.zero0
            $zero1 = $_.Value.zero1
            Write-Host ("  opcode_{0}: zero0={1} zero1={2}" -f $name, $zero0, $zero1)
        }
}
