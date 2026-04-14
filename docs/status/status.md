# Verification Status

Generated UTC: `2026-04-14T17:35:14Z`

| Field | Value |
|---|---|
| Label | tutorial-regression |
| Git branch | `main` |
| Git commit | `b66c6f2` |
| Git dirty | `1` |
| Overall required-suite status | `PASS` |

Required suites are `core_coverage`, `mmio_coverage`, `formal`, and `equivalence`. Optional suites are reported separately.

## Suite Summary

| Suite | Required | Status | Details | Source |
|---|---|---|---|---|
| core_coverage | yes | `PASS` | program_runs=40, total_cycles=676, opcode_hits=15 | `sim_build/coverage.json` |
| mmio_coverage | yes | `PASS` | program_runs=7, shadow_writes=113, status_reads=189 | `sim_build/mmio_coverage.json` |
| mmio_wait_coverage | no | `PASS` | program_runs=8, wait_transactions=498, wait_cycles=498, max_wait=1 | `sim_build/mmio_wait_coverage.json` |
| apb_coverage | no | `PASS` | program_runs=8, shadow_writes=129, setup_phases=514, access_phases=514 | `sim_build/apb_coverage.json` |
| wishbone_coverage | no | `PASS` | program_runs=8, shadow_writes=129, setup_phases=514, access_phases=514 | `sim_build/wishbone_coverage.json` |
| apb_fault_coverage | no | `PASS` | fault_cases=4, deferred_updates=1, reload_updates=1, readbacks=39 | `sim_build/apb_fault_coverage.json` |
| formal | yes | `PASS` | simple_cpu:PASS solver=cvc5 elapsed=0:00:03; simple_cpu_mmio:PASS solver=cvc5 elapsed=0:01:12; simple_cpu_mmio_wait:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_mmio_wait_faults:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_apb:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_wishbone:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_apb_faults:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_cover:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_mmio_cover:PASS solver=cvc5 elapsed=0:00:02; simple_cpu_mmio_wait_cover:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_apb_cover:PASS solver=cvc5 elapsed=0:00:00; simple_cpu_wishbone_cover:PASS solver=cvc5 elapsed=0:00:00 | `-` |
| equivalence | yes | `PASS` | partitions=93, elapsed=0:00:12 | `equiv/simple_cpu_eqy` |
| static_analysis | no | `PASS` | tools=4/4 | `sim_build/static_analysis/summary.json` |
| pyuvm_coverage | no | `PASS` | program_runs=11, total_cycles=131, opcode_hits=15 | `sim_build/pyuvm_coverage.json` |
| cocotb_verilator | no | `PASS` | tests=6, failures=0, errors=0, skipped=0 | `sim_build/verilator_results.xml` |
| mmio_cocotb | no | `PASS` | tests=4, failures=0, errors=0, skipped=0 | `sim_build/mmio_cocotb_results.xml` |
| mmio_pyuvm | no | `PASS` | tests=4, failures=0, errors=0, skipped=0 | `sim_build/mmio_uvm_results.xml` |
| mmio_wait_cocotb | no | `PASS` | tests=4, failures=0, errors=0, skipped=0 | `sim_build/mmio_wait_cocotb_results.xml` |
| mmio_wait_pyuvm | no | `PASS` | tests=4, failures=0, errors=0, skipped=0 | `sim_build/mmio_wait_uvm_results.xml` |
| apb_cocotb | no | `PASS` | tests=5, failures=0, errors=0, skipped=0 | `sim_build/apb_cocotb_results.xml` |
| apb_pyuvm | no | `PASS` | tests=4, failures=0, errors=0, skipped=0 | `sim_build/apb_uvm_results.xml` |
| wishbone_cocotb | no | `PASS` | tests=5, failures=0, errors=0, skipped=0 | `sim_build/wishbone_cocotb_results.xml` |
| wishbone_pyuvm | no | `PASS` | tests=4, failures=0, errors=0, skipped=0 | `sim_build/wishbone_uvm_results.xml` |
| verilator_coverage | no | `PASS` | overall=61.76%, line=100.0%, toggle=55.92%, expr=62.5% | `sim_build/verilator_coverage/summary.json` |
| mutations | no | `PASS` | killed_mutations=17/17 | `sim_build/mutations/mutation_summary.json` |

## Formal Targets

| Target | Status | Solver | Elapsed | Path |
|---|---|---|---|---|
| simple_cpu | `PASS` | `cvc5` | `0:00:03` | `formal/simple_cpu` |
| simple_cpu_mmio | `PASS` | `cvc5` | `0:01:12` | `formal/simple_cpu_mmio` |
| simple_cpu_mmio_wait | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_mmio_wait` |
| simple_cpu_mmio_wait_faults | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_mmio_wait_faults` |
| simple_cpu_apb | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_apb` |
| simple_cpu_wishbone | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_wishbone` |
| simple_cpu_apb_faults | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_apb_faults` |
| simple_cpu_cover | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_cover` |
| simple_cpu_mmio_cover | `PASS` | `cvc5` | `0:00:02` | `formal/simple_cpu_mmio_cover` |
| simple_cpu_mmio_wait_cover | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_mmio_wait_cover` |
| simple_cpu_apb_cover | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_apb_cover` |
| simple_cpu_wishbone_cover | `PASS` | `cvc5` | `0:00:00` | `formal/simple_cpu_wishbone_cover` |

## Latest Coverage History Snapshot

| Field | Value |
|---|---|
| Timestamp UTC | `2026-04-14T09:40:26Z` |
| Label | tutorial-regression |
| Commit | `719fcbf` |
| Dirty | `0` |

## Badge Endpoints

Generated shields-compatible endpoint JSON files:

1. `docs/status/badges/apb-cocotb.json`
1. `docs/status/badges/apb-coverage.json`
1. `docs/status/badges/apb-fault-coverage.json`
1. `docs/status/badges/apb-pyuvm.json`
1. `docs/status/badges/cocotb-verilator.json`
1. `docs/status/badges/core-coverage.json`
1. `docs/status/badges/equivalence.json`
1. `docs/status/badges/formal.json`
1. `docs/status/badges/formal-simple_cpu.json`
1. `docs/status/badges/formal-simple_cpu_apb.json`
1. `docs/status/badges/formal-simple_cpu_apb_cover.json`
1. `docs/status/badges/formal-simple_cpu_apb_faults.json`
1. `docs/status/badges/formal-simple_cpu_cover.json`
1. `docs/status/badges/formal-simple_cpu_mmio.json`
1. `docs/status/badges/formal-simple_cpu_mmio_cover.json`
1. `docs/status/badges/formal-simple_cpu_mmio_wait.json`
1. `docs/status/badges/formal-simple_cpu_mmio_wait_cover.json`
1. `docs/status/badges/formal-simple_cpu_mmio_wait_faults.json`
1. `docs/status/badges/formal-simple_cpu_wishbone.json`
1. `docs/status/badges/formal-simple_cpu_wishbone_cover.json`
1. `docs/status/badges/mmio-cocotb.json`
1. `docs/status/badges/mmio-coverage.json`
1. `docs/status/badges/mmio-pyuvm.json`
1. `docs/status/badges/mmio-wait-cocotb.json`
1. `docs/status/badges/mmio-wait-coverage.json`
1. `docs/status/badges/mmio-wait-pyuvm.json`
1. `docs/status/badges/mutations.json`
1. `docs/status/badges/overall.json`
1. `docs/status/badges/pyuvm.json`
1. `docs/status/badges/static-analysis.json`
1. `docs/status/badges/verilator-coverage.json`
1. `docs/status/badges/wishbone-cocotb.json`
1. `docs/status/badges/wishbone-coverage.json`
1. `docs/status/badges/wishbone-pyuvm.json`
