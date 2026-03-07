# Verification Status

Generated UTC: `2026-03-07T11:44:40Z`

| Field | Value |
|---|---|
| Label | tutorial-regression |
| Git branch | `main` |
| Git commit | `a8eda27` |
| Git dirty | `0` |
| Overall required-suite status | `PASS` |

Required suites are `core_coverage`, `mmio_coverage`, and `formal`. Optional suites are reported separately.

## Suite Summary

| Suite | Required | Status | Details | Source |
|---|---|---|---|---|
| core_coverage | yes | `PASS` | program_runs=40, total_cycles=676, opcode_hits=15 | `sim_build/coverage.json` |
| mmio_coverage | yes | `PASS` | program_runs=5, shadow_writes=80, status_reads=116 | `sim_build/mmio_coverage.json` |
| formal | yes | `PASS` | simple_cpu:PASS solver=cvc5 elapsed=0:00:03; simple_cpu_mmio:PASS solver=cvc5 elapsed=0:01:22 | `-` |
| pyuvm_coverage | no | `PASS` | program_runs=11, total_cycles=131, opcode_hits=15 | `sim_build/pyuvm_coverage.json` |
| mutations | no | `PASS` | killed_mutations=9/9 | `sim_build/mutations/mutation_summary.json` |

## Formal Targets

| Target | Status | Solver | Elapsed | Path |
|---|---|---|---|---|
| simple_cpu | `PASS` | `cvc5` | `0:00:03` | `formal/simple_cpu` |
| simple_cpu_mmio | `PASS` | `cvc5` | `0:01:22` | `formal/simple_cpu_mmio` |

## Latest Coverage History Snapshot

| Field | Value |
|---|---|
| Timestamp UTC | `2026-03-07T11:43:24Z` |
| Label | tutorial-regression |
| Commit | `b30fe1e` |
| Dirty | `0` |

## Badge Endpoints

Generated shields-compatible endpoint JSON files:

1. `docs/status/badges/core-coverage.json`
1. `docs/status/badges/formal.json`
1. `docs/status/badges/formal-simple_cpu.json`
1. `docs/status/badges/formal-simple_cpu_mmio.json`
1. `docs/status/badges/mmio-coverage.json`
1. `docs/status/badges/mutations.json`
1. `docs/status/badges/overall.json`
1. `docs/status/badges/pyuvm.json`
