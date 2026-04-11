# Verification Status

Generated UTC: `2026-04-11T12:01:04Z`

| Field | Value |
|---|---|
| Label | tutorial-regression |
| Git branch | `main` |
| Git commit | `44df4a1` |
| Git dirty | `1` |
| Overall required-suite status | `PASS` |

Required suites are `core_coverage`, `mmio_coverage`, `formal`, and `equivalence`. Optional suites are reported separately.

## Suite Summary

| Suite | Required | Status | Details | Source |
|---|---|---|---|---|
| core_coverage | yes | `PASS` | program_runs=40, total_cycles=676, opcode_hits=15 | `sim_build/coverage.json` |
| mmio_coverage | yes | `PASS` | program_runs=7, shadow_writes=113, status_reads=189 | `sim_build/mmio_coverage.json` |
| formal | yes | `PASS` | simple_cpu:PASS solver=cvc5 elapsed=0:00:03; simple_cpu_mmio:PASS solver=cvc5 elapsed=0:00:57; simple_cpu_cover:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_mmio_cover:PASS solver=cvc5 elapsed=0:00:02 | `-` |
| equivalence | yes | `PASS` | partitions=93, elapsed=0:00:13 | `equiv/simple_cpu_eqy` |
| static_analysis | no | `PASS` | tools=4/4 | `sim_build/static_analysis/summary.json` |
| pyuvm_coverage | no | `PASS` | program_runs=11, total_cycles=131, opcode_hits=15 | `sim_build/pyuvm_coverage.json` |
| mmio_cocotb | no | `PASS` | tests=3, failures=0, errors=0, skipped=0 | `sim_build/mmio_cocotb_results.xml` |
| verilator_coverage | no | `PASS` | overall=61.76%, line=100.0%, toggle=55.92%, expr=62.5% | `sim_build/verilator_coverage/summary.json` |
| mutations | no | `PASS` | killed_mutations=9/9 | `sim_build/mutations/mutation_summary.json` |

## Formal Targets

| Target | Status | Solver | Elapsed | Path |
|---|---|---|---|---|
| simple_cpu | `PASS` | `cvc5` | `0:00:03` | `formal/simple_cpu` |
| simple_cpu_mmio | `PASS` | `cvc5` | `0:00:57` | `formal/simple_cpu_mmio` |
| simple_cpu_cover | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_cover` |
| simple_cpu_mmio_cover | `PASS` | `cvc5` | `0:00:02` | `formal/simple_cpu_mmio_cover` |

## Latest Coverage History Snapshot

| Field | Value |
|---|---|
| Timestamp UTC | `2026-04-11T12:00:59Z` |
| Label | tutorial-regression |
| Commit | `44df4a1` |
| Dirty | `1` |

## Badge Endpoints

Generated shields-compatible endpoint JSON files:

1. `docs/status/badges/core-coverage.json`
1. `docs/status/badges/equivalence.json`
1. `docs/status/badges/formal.json`
1. `docs/status/badges/formal-simple_cpu.json`
1. `docs/status/badges/formal-simple_cpu_cover.json`
1. `docs/status/badges/formal-simple_cpu_mmio.json`
1. `docs/status/badges/formal-simple_cpu_mmio_cover.json`
1. `docs/status/badges/mmio-cocotb.json`
1. `docs/status/badges/mmio-coverage.json`
1. `docs/status/badges/mutations.json`
1. `docs/status/badges/overall.json`
1. `docs/status/badges/pyuvm.json`
1. `docs/status/badges/static-analysis.json`
1. `docs/status/badges/verilator-coverage.json`
