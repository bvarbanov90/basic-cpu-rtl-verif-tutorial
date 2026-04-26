param(
    [string]$CoverageFile = "sim_build/axi_lite_fault_coverage.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "AXI-Lite fault coverage file not found: $CoverageFile. Run .\\scripts\\run-axi-lite-fault.ps1 first."
}

$cov = Get-Content -Raw $CoverageFile | ConvertFrom-Json

Write-Host "AXI-Lite Fault Coverage Summary"
Write-Host "  pass:                             $($cov.coverage_pass)"
Write-Host "  aw_only_writes_ignored:           $($cov.aw_only_writes_ignored)"
Write-Host "  w_only_writes_ignored:            $($cov.w_only_writes_ignored)"
Write-Host "  split_write_attempts_ignored:     $($cov.split_write_attempts_ignored)"
Write-Host "  pending_response_blocks_writes:   $($cov.pending_response_blocks_writes)"
Write-Host "  shadow_fault_write_observed:      $($cov.shadow_fault_write_observed)"
Write-Host "  deferred_shadow_updates:          $($cov.deferred_shadow_updates)"
Write-Host "  reload_observed_updates:          $($cov.reload_observed_updates)"
Write-Host "  program_runs:                     $($cov.program_runs)"
Write-Host "  fault_readbacks:                  $($cov.fault_readbacks)"

if ($cov.coverage_goals) {
    Write-Host ""
    Write-Host "Coverage Goals"
    $cov.coverage_goals.PSObject.Properties |
        Sort-Object Name |
        ForEach-Object {
            Write-Host ("  {0}: {1}" -f $_.Name, $_.Value)
        }
}
