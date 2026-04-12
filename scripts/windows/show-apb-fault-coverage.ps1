param(
    [string]$CoverageFile = "sim_build/apb_fault_coverage.json"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CoverageFile)) {
    throw "APB fault coverage file not found: $CoverageFile. Run .\\scripts\\run-apb-fault.ps1 first."
}

$cov = Get-Content -Raw $CoverageFile | ConvertFrom-Json

Write-Host "APB Fault Coverage Summary"
Write-Host "  pass:                          $($cov.coverage_pass)"
Write-Host "  setup_only_writes_ignored:     $($cov.setup_only_writes_ignored)"
Write-Host "  aborted_writes_ignored:        $($cov.aborted_writes_ignored)"
Write-Host "  setup_only_starts_ignored:     $($cov.setup_only_starts_ignored)"
Write-Host "  penable_without_select_ignore: $($cov.penable_without_select_ignored)"
Write-Host "  shadow_fault_write_observed:   $($cov.shadow_fault_write_observed)"
Write-Host "  deferred_shadow_updates:       $($cov.deferred_shadow_updates)"
Write-Host "  reload_observed_updates:       $($cov.reload_observed_updates)"
Write-Host "  program_runs:                  $($cov.program_runs)"
Write-Host "  fault_readbacks:               $($cov.fault_readbacks)"

if ($cov.coverage_goals) {
    Write-Host ""
    Write-Host "Coverage Goals"
    $cov.coverage_goals.PSObject.Properties |
        Sort-Object Name |
        ForEach-Object {
            Write-Host ("  {0}: {1}" -f $_.Name, $_.Value)
        }
}
