# Verification Plan (Basic CPU Tutorial)

## Verification goals

1. Confirm each opcode behaves per spec.
2. Confirm status flags (`ZERO`, `CARRY`, `NEG`, `OVERFLOW`, `HALTED`) update correctly.
3. Confirm control-flow behavior (`JMP`, `JZ`) works.
4. Confirm memory side effects (`STA`, `LDA`) are correct.
5. Confirm end-to-end state matches a reference model.
6. Confirm external assembled programs match the reference model.

## Current status (April 14, 2026)

1. `.\scripts\run.ps1 -NoWaves`: PASS
2. `.\scripts\lint.ps1`: PASS
3. `.\scripts\show-static-analysis.ps1`: PASS
4. `.\scripts\run-formal.ps1`: PASS (auto-selected `cvc5`)
5. `.\scripts\run-formal.ps1 -Mode cover`: PASS
6. `.\scripts\run-cocotb-verilator.ps1 -NoWaves -Coverage`: PASS (falls back to WSL, auto-uses Linux OSS CAD Suite Verilator 5.047)
7. `.\scripts\show-verilator-coverage.ps1`: PASS
8. `.\scripts\run-equiv.ps1`: PASS (routes through WSL EQY)
9. `.\scripts\show-coverage.ps1`: PASS (`opcode_hit_bitmap=111111111111111`)
10. `.\scripts\show-mmio-coverage.ps1`: PASS
11. `.\scripts\show-mmio-wait-coverage.ps1`: PASS
12. `.\scripts\show-apb-coverage.ps1`: PASS
13. `.\scripts\show-apb-fault-coverage.ps1`: PASS
14. `.\scripts\record-coverage-history.ps1`: PASS
14. `.\scripts\show-coverage-trend.ps1`: PASS
14. `.\scripts\run-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
15. `.\scripts\run-mmio-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
16. `.\scripts\run-cocotb-mmio.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
17. `.\scripts\run-cocotb-mmio-wait.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
18. `.\scripts\run-mmio-wait-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
19. `.\scripts\run-cocotb-apb.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
20. `.\scripts\run-apb-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
21. `.\scripts\run-cocotb-wishbone.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
22. `.\scripts\run-wishbone-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
23. `.\scripts\check-coverage-delta.ps1`: PASS
24. `.\scripts\run-mmio.ps1 -NoWaves`: PASS
25. `.\scripts\run-mmio-wait.ps1 -NoWaves`: PASS
26. `.\scripts\run-apb.ps1 -NoWaves`: PASS
27. `.\scripts\run-wishbone.ps1 -NoWaves`: PASS
28. `.\scripts\run-apb-fault.ps1 -NoWaves`: PASS
29. `.\scripts\check-native.ps1`: PASS
30. `.\scripts\run-asm-corpus.ps1 -NoSimulate`: PASS
31. `.\scripts\run-asm-corpus.ps1 -Runner mmio_wait`: PASS
32. `.\scripts\run-asm-corpus.ps1 -Runner apb`: PASS
33. `.\scripts\run-asm-corpus.ps1 -Runner wishbone`: PASS
34. `.\scripts\run-mutations.ps1`: PASS
35. `.\scripts\show-mutations.ps1`: PASS
36. `bash scripts/run.sh --no-waves` (WSL Ubuntu): PASS
37. `bash scripts/run-mmio.sh --no-waves` (WSL Ubuntu): PASS
38. `bash scripts/run-mmio-wait.sh --no-waves` (WSL Ubuntu): PASS
39. `bash scripts/run-apb.sh --no-waves` (WSL Ubuntu): PASS
40. `bash scripts/run-wishbone.sh --no-waves` (WSL Ubuntu): PASS
41. `bash scripts/show-mmio-coverage.sh` (WSL Ubuntu): PASS
42. `bash scripts/show-mmio-wait-coverage.sh` (WSL Ubuntu): PASS
43. `bash scripts/show-apb-coverage.sh` (WSL Ubuntu): PASS
44. `bash scripts/show-wishbone-coverage.sh` (WSL Ubuntu): PASS
45. `bash scripts/show-apb-fault-coverage.sh` (WSL Ubuntu): PASS
46. `bash scripts/check-native.sh`: PASS
47. `bash scripts/lint.sh` (WSL Ubuntu): PASS
48. `bash scripts/show-static-analysis.sh` (WSL Ubuntu): PASS
49. `bash scripts/run-formal.sh --mode all` (WSL Ubuntu, `cvc5`): PASS
50. `bash scripts/run-cocotb-verilator.sh --no-waves --coverage` (WSL Ubuntu): PASS
51. `bash scripts/run-cocotb-mmio.sh --no-waves` (WSL Ubuntu): PASS
52. `bash scripts/run-cocotb-mmio-wait.sh --no-waves` (WSL Ubuntu): PASS
53. `bash scripts/run-cocotb-wishbone.sh --no-waves` (WSL Ubuntu): PASS
54. `bash scripts/run-equiv.sh` (WSL Ubuntu): PASS
55. `bash scripts/run-uvm.sh --no-waves` (WSL Ubuntu): PASS
56. `bash scripts/run-mmio-uvm.sh --no-waves` (WSL Ubuntu): PASS
57. `bash scripts/run-mmio-wait-uvm.sh --no-waves` (WSL Ubuntu): PASS
58. `bash scripts/run-wishbone-uvm.sh --no-waves` (WSL Ubuntu): PASS
59. `bash scripts/check-coverage-delta.sh` (WSL Ubuntu): PASS
60. `bash scripts/show-coverage-trend.sh` (WSL Ubuntu): PASS
61. `bash scripts/run-asm-corpus.sh --no-simulate` (WSL Ubuntu): PASS
62. `bash scripts/run-asm-corpus.sh --runner mmio` (WSL Ubuntu): PASS
63. `bash scripts/run-asm-corpus.sh --runner mmio_wait` (WSL Ubuntu): PASS
64. `bash scripts/run-asm-corpus.sh --runner apb` (WSL Ubuntu): PASS
65. `bash scripts/run-asm-corpus.sh --runner wishbone` (WSL Ubuntu): PASS
66. `bash scripts/run-mutations.sh` (WSL Ubuntu): PASS
67. `bash scripts/show-mutations.sh` (WSL Ubuntu): PASS
68. `.\scripts\show-formal-status.ps1`: PASS
69. `.\scripts\export-status.ps1 -Label tutorial-regression`: PASS
70. `bash scripts/show-formal-status.sh` (WSL Ubuntu): PASS
71. `bash scripts/export-status.sh --label tutorial-regression`: PASS

## Test strategy

1. Directed tests for fast, readable intent checks.
2. Multi-seed randomized dataflow and branch-stress programs for broader state exploration.
3. Reference-model comparison for robust end-state checking.
4. Lightweight functional coverage counters with threshold checks.
5. Repo-tracked coverage baseline with delta checks for non-regression.
6. Assembler corpus manifest checks for stable machine-code and end-state regression.
7. Interface-level wrapper verification using the same programs/reference model.
8. Mutation testing that confirms representative RTL bugs are detected by the regressions.
9. Wrapper-specific protocol/transaction coverage for the MMIO shell.
10. Simulator cross-checking with the same cocotb tests on Verilator.
11. Formal cover witness generation for tutorial-quality traces.
12. EQY equivalence checks for refactor-safe RTL cleanup.
13. Multi-tool static analysis with Verilator, Verible lint/format, and svlint.
14. CI workflow on GitHub Actions for automated regression on push/PR.

## Current tests

| Test name | Location | Intent |
|---|---|---|
| `test_directed` | `tb/simple_cpu_tb.sv` | Exercises arithmetic, stores, `ZERO`, `JZ`, and `HLT`. |
| `test_branch_not_taken` | `tb/simple_cpu_tb.sv` | Explicit `JZ` not-taken behavior and `NOP` execution. |
| `test_jump_loop` | `tb/simple_cpu_tb.sv` | `JMP` + `JZ` loop behavior and loop exit via `ZERO`. |
| `test_wraparound_zero` | `tb/simple_cpu_tb.sv` | 8-bit arithmetic wraparound and `ZERO` flag transition checks. |
| `test_logic_and_cmp` | `tb/simple_cpu_tb.sv` | `AND/OR/XOR/SHL/SHR/CMP` behavior and flag checks. |
| `test_shift_carry_and_overflow` | `tb/simple_cpu_tb.sv` | Shift carry-out and overflow behavior checks. |
| `test_cmp_negative` | `tb/simple_cpu_tb.sv` | Negative compare result flag checks (`NEG`, `CARRY`). |
| `test_illegal_opcode` | `tb/simple_cpu_tb.sv` | Illegal opcode handling path should halt safely. |
| `test_randomized_suite` | `tb/simple_cpu_tb.sv` | 20 deterministic randomized programs, full DUT vs model state compare. |
| `test_branch_randomized_suite` | `tb/simple_cpu_tb.sv` | Bounded-loop branch-heavy randomized programs stressing `JZ/JMP` control flow. |
| `test_external_program` | `tb/simple_cpu_tb.sv` | Optional plusarg-driven external `.hex` program check vs model. |
| `report_and_check_coverage` | `tb/simple_cpu_tb.sv` | Coverage thresholds for opcode hits, branch outcomes, and flag transitions. |
| `test_mmio_smoke` | `tb/simple_cpu_mmio_tb.sv` | MMIO programming, shadow readback, loader start, and end-state comparison. |
| `test_mmio_reprogram_sequence` | `tb/simple_cpu_mmio_tb.sv` | Reset/reprogram/run sequencing plus shift carry/overflow status checking. |
| `test_mmio_illegal_opcode` | `tb/simple_cpu_mmio_tb.sv` | MMIO replay of illegal-opcode handling and safe halt behavior. |
| `test_mmio_jump_sub_cmp_sequence` | `tb/simple_cpu_mmio_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay that closes the MMIO mutation gap for ALU/control flow. |
| `test_mmio_shadow_fault_injection` | `tb/simple_cpu_mmio_tb.sv` | Writes a modified shadow image while the wrapper is already running, then proves the current run stays on the original program and only the next reload observes the injected change. |
| `test_external_program` | `tb/simple_cpu_mmio_tb.sv` | Optional `.hex` replay through the MMIO wrapper against the reference model. |
| `report_and_check_mmio_coverage` | `tb/simple_cpu_mmio_tb.sv` | Wrapper protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_mmio_assertions` | `tb/simple_cpu_mmio_assertions.sv` | Assertion-based checker for `bus_ready`, control-state encoding, and loader/reset signal alignment. |
| `test_mmio_smoke` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state MMIO programming, shadow readback, delayed bus handshake, and end-state comparison. |
| `test_mmio_reprogram_sequence` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state reset/reprogram/run sequencing plus delayed control/status visibility checks. |
| `test_mmio_illegal_opcode` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state replay of illegal-opcode handling and safe halt behavior. |
| `test_mmio_jump_sub_cmp_sequence` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state wrapper replay of `SUB/CMP/JMP` control flow against the reference model. |
| `test_mmio_shadow_fault_injection` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state proof that shadow writes during `RUN` only affect the next explicit reload. |
| `test_external_program` | `tb/simple_cpu_mmio_wait_tb.sv` | Optional `.hex` replay through the wait-state MMIO wrapper against the reference model. |
| `report_and_check_mmio_wait_coverage` | `tb/simple_cpu_mmio_wait_tb.sv` | Wait-state wrapper transaction coverage thresholds and artifact emission. |
| `simple_cpu_mmio_wait_assertions` | `tb/simple_cpu_mmio_wait_assertions.sv` | Assertion-based checker for request capture, delayed `bus_ready`, stable pending request fields, and inner-wrapper alignment. |
| `test_apb_smoke` | `tb/simple_cpu_apb_tb.sv` | APB programming, shadow readback, loader start, and end-state comparison. |
| `test_apb_reprogram_sequence` | `tb/simple_cpu_apb_tb.sv` | Reset/reprogram/run sequencing plus APB control/status readback checks. |
| `test_apb_illegal_opcode` | `tb/simple_cpu_apb_tb.sv` | APB replay of illegal-opcode handling and safe halt behavior. |
| `test_apb_jump_sub_cmp_sequence` | `tb/simple_cpu_apb_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay that closes the APB native control-flow gap. |
| `test_apb_shadow_fault_injection` | `tb/simple_cpu_apb_tb.sv` | Writes a modified shadow image while the wrapper is already running, then proves the current run stays on the original program and only the next reload observes the injected change. |
| `test_external_program` | `tb/simple_cpu_apb_tb.sv` | Optional `.hex` replay through the APB wrapper against the reference model. |
| `report_and_check_apb_coverage` | `tb/simple_cpu_apb_tb.sv` | APB protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_apb_assertions` | `tb/simple_cpu_apb_assertions.sv` | Assertion-based checker for APB setup/access sequencing, `PREADY` gating, and control/readback alignment. |
| `test_wishbone_smoke` | `tb/simple_cpu_wishbone_tb.sv` | Wishbone programming, shadow readback, loader start, and end-state comparison. |
| `test_wishbone_reprogram_sequence` | `tb/simple_cpu_wishbone_tb.sv` | Reset/reprogram/run sequencing plus Wishbone control/status readback checks. |
| `test_wishbone_illegal_opcode` | `tb/simple_cpu_wishbone_tb.sv` | Wishbone replay of illegal-opcode handling and safe halt behavior. |
| `test_wishbone_jump_sub_cmp_sequence` | `tb/simple_cpu_wishbone_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay that closes the Wishbone native control-flow gap. |
| `test_wishbone_shadow_fault_injection` | `tb/simple_cpu_wishbone_tb.sv` | Writes a modified shadow image while the wrapper is already running, then proves the current run stays on the original program and only the next reload observes the injected change. |
| `test_external_program` | `tb/simple_cpu_wishbone_tb.sv` | Optional `.hex` replay through the Wishbone wrapper against the reference model. |
| `report_and_check_wishbone_coverage` | `tb/simple_cpu_wishbone_tb.sv` | Wishbone protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_wishbone_assertions` | `tb/simple_cpu_wishbone_assertions.sv` | Assertion-based checker for Wishbone `CYC/STB/ACK` gating and control/readback alignment. |
| `test_setup_only_shadow_write_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves setup-only shadow writes do not update the APB wrapper shadow image. |
| `test_aborted_shadow_write_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves setup then abort traffic does not update the APB wrapper shadow image. |
| `test_setup_only_control_start_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves setup-only `CONTROL=1` writes do not start the loader. |
| `test_penable_without_select_ignored` | `tb/simple_cpu_apb_fault_tb.sv` | Proves `PENABLE` glitches without `PSEL` do not create hidden APB side effects. |
| `test_run_phase_shadow_update_requires_reload` | `tb/simple_cpu_apb_fault_tb.sv` | Proves APB shadow updates during `RUN` are visible in shadow readback immediately but only affect execution after the next explicit reload. |
| `report_and_check_apb_fault_coverage` | `tb/simple_cpu_apb_fault_tb.sv` | APB fault-injection coverage thresholds and artifact emission. |
| `directed_arithmetic_and_branch` | `tb/test_simple_cpu.py` | Optional cocotb directed test mirroring simulator-native checks. |
| `randomized_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb randomized/reference-model check. |
| `branch_stress_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb bounded-loop branch-stress/reference-model check. |
| `assembler_corpus_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb replay of the tracked assembler corpus against the DUT and reference model. |
| `protocol_conformance_matches_reference_suite` | `tb/test_simple_cpu.py` | Shared conformance-suite replay over the direct programming interface using the same scenario set as the wrapper buses. |
| `program_write_stalls_and_retargets_execution` | `tb/test_simple_cpu.py` | Holds `prog_we` across consecutive cycles, proves architectural state stalls, and confirms a future instruction patch is honored once execution resumes. |
| `mmio_program_matches_reference_model` | `tb/test_simple_cpu_mmio.py` | Optional cocotb MMIO wrapper replay against the same `ReferenceCPU` used by the native bench. |
| `mmio_protocol_conformance_suite` | `tb/test_simple_cpu_mmio.py` | Replays the shared conformance-suite scenarios through the MMIO wrapper and checks end state against `ReferenceCPU`. |
| `mmio_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_mmio.py` | Python-side bus-level check that shadow writes during `RUN` do not perturb the current run and only take effect after reload. |
| `mmio_control_status_readback` | `tb/test_simple_cpu_mmio.py` | Reads `CONTROL`, `STATUS`, `ACC`, and DMEM through MMIO across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `run-cocotb-verilator` | `scripts/run-cocotb-verilator.*` | Runs the cocotb core regression on Verilator and emits structural coverage artifacts. |
| `run-cocotb-mmio` | `scripts/run-cocotb-mmio.*` | Runs the dedicated MMIO cocotb regression on Icarus with bus-level programming/readback checks. |
| `run-cocotb-mmio-wait` | `scripts/run-cocotb-mmio-wait.*` | Replays the same MMIO cocotb suite against the wait-state wrapper variant and proves the Python bus helper tolerates delayed `bus_ready`. |
| `apb_program_matches_reference_model` | `tb/test_simple_cpu_apb.py` | Optional cocotb APB-wrapper replay against the same `ReferenceCPU` used by the MMIO and native benches. |
| `apb_protocol_conformance_suite` | `tb/test_simple_cpu_apb.py` | Replays the shared conformance-suite scenarios through the APB wrapper and checks end state against `ReferenceCPU`. |
| `apb_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_apb.py` | APB-side shadow-image change check proving the current run is isolated until reload. |
| `apb_control_status_readback` | `tb/test_simple_cpu_apb.py` | Reads APB-exposed `CONTROL`, `STATUS`, `ACC`, and DMEM through the APB shell across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `apb_setup_phase_requires_penable` | `tb/test_simple_cpu_apb.py` | Protocol-focused APB check that `PREADY` stays low during setup until `PENABLE` is asserted. |
| `wishbone_program_matches_reference_model` | `tb/test_simple_cpu_wishbone.py` | Optional cocotb Wishbone-wrapper replay against the same `ReferenceCPU` used by the MMIO/APB/native benches. |
| `wishbone_protocol_conformance_suite` | `tb/test_simple_cpu_wishbone.py` | Replays the shared conformance-suite scenarios through the Wishbone wrapper and checks end state against `ReferenceCPU`. |
| `wishbone_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_wishbone.py` | Wishbone-side shadow-image change check proving the current run is isolated until reload. |
| `wishbone_control_status_readback` | `tb/test_simple_cpu_wishbone.py` | Reads Wishbone-exposed `CONTROL`, `STATUS`, `ACC`, and DMEM through the Wishbone shell across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `wishbone_cycle_without_strobe_keeps_ack_low` | `tb/test_simple_cpu_wishbone.py` | Protocol-focused Wishbone check that `ACK` stays low when `CYC` is asserted without `STB`. |
| `SimpleCpuMmioUvmSmokeTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | Minimal pyuvm wrapper smoke/reference-model check over the MMIO shell. |
| `SimpleCpuMmioUvmRandomizedTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | Minimal pyuvm randomized wrapper replay against the same `ReferenceCPU`. |
| `SimpleCpuMmioUvmControlStatusTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | pyuvm wrapper sequence that explicitly observes `LOAD` then `RUN` through the MMIO control register. |
| `SimpleCpuMmioUvmShadowFaultInjectionTest` | `tb/test_simple_cpu_mmio_pyuvm.py` | pyuvm direct-bus proof that shadow writes during `RUN` only affect the next reload. |
| `run-mmio-uvm` | `scripts/run-mmio-uvm.*` | Runs the dedicated MMIO pyuvm regression on Icarus using the reusable Python MMIO bus helper. |
| `run-mmio-wait-uvm` | `scripts/run-mmio-wait-uvm.*` | Runs the same MMIO pyuvm suite against the wait-state wrapper variant with delayed handshakes. |
| `SimpleCpuApbUvmSmokeTest` | `tb/test_simple_cpu_apb_pyuvm.py` | Minimal pyuvm APB-wrapper smoke/reference-model check over the APB shell. |
| `SimpleCpuApbUvmRandomizedTest` | `tb/test_simple_cpu_apb_pyuvm.py` | Minimal pyuvm randomized APB-wrapper replay against the same `ReferenceCPU`. |
| `SimpleCpuApbUvmControlStatusTest` | `tb/test_simple_cpu_apb_pyuvm.py` | pyuvm APB-wrapper sequence that explicitly observes `LOAD` then `RUN` through the APB control register. |
| `SimpleCpuApbUvmShadowFaultInjectionTest` | `tb/test_simple_cpu_apb_pyuvm.py` | pyuvm APB proof that shadow writes during `RUN` only affect the next reload. |
| `run-cocotb-apb` | `scripts/run-cocotb-apb.*` | Runs the dedicated APB cocotb regression on Icarus with setup/access handshake checks. |
| `run-apb-uvm` | `scripts/run-apb-uvm.*` | Runs the dedicated APB pyuvm regression on Icarus using the reusable Python APB bus helper. |
| `SimpleCpuWishboneUvmSmokeTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | Minimal pyuvm Wishbone-wrapper smoke/reference-model check over the Wishbone shell. |
| `SimpleCpuWishboneUvmRandomizedTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | Minimal pyuvm randomized Wishbone-wrapper replay against the same `ReferenceCPU`. |
| `SimpleCpuWishboneUvmControlStatusTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | pyuvm Wishbone-wrapper sequence that explicitly observes `LOAD` then `RUN` through the Wishbone control register. |
| `SimpleCpuWishboneUvmShadowFaultInjectionTest` | `tb/test_simple_cpu_wishbone_pyuvm.py` | pyuvm Wishbone proof that shadow writes during `RUN` only affect the next reload. |
| `run-cocotb-wishbone` | `scripts/run-cocotb-wishbone.*` | Runs the dedicated Wishbone cocotb regression on Icarus with `CYC/STB/ACK` handshake checks. |
| `run-wishbone-uvm` | `scripts/run-wishbone-uvm.*` | Runs the dedicated Wishbone pyuvm regression on Icarus using the reusable Python Wishbone bus helper. |
| `SimpleCpuUvmSmokeTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm (UVM-style) sequence/driver/subscriber smoke check. |
| `SimpleCpuUvmRandomizedTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm randomized program check against reference model. |
| `SimpleCpuUvmBranchStressTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm branch-stress program check against reference model. |
| `SimpleCpuUvmCoverageRegressionTest` | `tb/test_simple_cpu_pyuvm.py` | Deterministic + randomized pyuvm regression with subscriber-based coverage report emission. |
| `SimpleCpuUvmProgramWriteStallTest` | `tb/test_simple_cpu_pyuvm.py` | pyuvm BFM-level proof that asserted `prog_we` stalls architectural state while a future instruction patch is staged. |
| `run-asm-corpus` | `scripts/check_asm_corpus.py` + wrappers | Manifest-driven assembler regression corpus; checks bytes, final state, and coverage signatures. |
| `run-mutations` | `scripts/run_mutation_campaign.py` + wrappers | Builds temporary broken RTL variants across the core and APB shell, then confirms the direct, MMIO, and APB native benches kill them. |
| `run-formal --mode cover` | `scripts/run-formal.*` + `formal/*cover*` | Generates witness traces for representative core/MMIO reachable scenarios. |
| `run-equiv` | `scripts/run-equiv.*` + `equiv/simple_cpu.eqy` | Proves the current core matches the tracked golden RTL snapshot. |
| `lint` / `show-static-analysis` | `scripts/static_analysis.py` + wrappers | Aggregates Verilator, Verible lint, Verible format verification, and svlint into repo-friendly logs plus JSON/Markdown summaries. |

## Coverage model (simple functional coverage)

1. Opcode hit bitmap for `NOP..CMP`.
2. Illegal opcode path hit.
3. `JZ` taken and not-taken counters.
4. `ZERO` transition bins (`00`, `01`, `10`, `11`).
5. Cross bins: `opcode x post-instruction ZERO/CARRY/NEG/OVERFLOW`.
6. Reachability metadata for ISA-impossible cross bins.
7. Flag bins for `CARRY`, `NEG`, `OVERFLOW` (0 and 1 observed).
8. Explicit closure bins mirrored from the native checker (`JZ x ZERO`, `ADD/SUB x CARRY`, `SUB/CMP x NEG`, `SHL x OVERFLOW`).
9. Program-run and executed-cycle counters.

Coverage artifacts:

1. `sim_build/coverage.json` (machine-readable summary + goals + reachability metadata)
2. `sim_build/coverage.csv` (flat metrics for spreadsheets/CI parsing)
3. `docs/coverage-baseline.json` (repo-tracked lower-bound baseline for regression checks)
4. `docs/coverage-history.json` / `docs/coverage-history.md` (tracked history and rendered trend report)
5. `docs/status/status.json` / `docs/status/status.md` (repo-tracked verification snapshot)
6. `docs/status/badges/*.json` (shields-compatible endpoint payloads)
7. `sim_build/pyuvm_coverage.json` (pyuvm coverage subscriber output)
8. `sim_build/asm_corpus/*.hex` (assembler corpus outputs)
9. `sim_build/mutations/mutation_summary.json` / `sim_build/mutations/mutation_summary.md` (mutation-campaign summaries)
10. `sim_build/mmio_coverage.json` / `sim_build/mmio_coverage.csv` (wrapper transaction coverage)
11. `sim_build/mmio_wait_coverage.json` / `sim_build/mmio_wait_coverage.csv` (wait-state MMIO wrapper transaction coverage)
12. `sim_build/apb_coverage.json` / `sim_build/apb_coverage.csv` (APB wrapper transaction coverage)
13. `sim_build/wishbone_coverage.json` / `sim_build/wishbone_coverage.csv` (Wishbone wrapper transaction coverage)
14. `sim_build/apb_fault_coverage.json` / `sim_build/apb_fault_coverage.csv` (APB fault-injection coverage)
14. `sim_build/verilator_coverage/summary.json` / `sim_build/verilator_coverage/summary.md` (Verilator structural coverage summary)
15. `sim_build/verilator_coverage/annotated/` (annotated source view for uncovered points)
16. `sim_build/static_analysis/summary.json` / `sim_build/static_analysis/summary.md` (static-analysis aggregate summary)
17. `sim_build/mmio_cocotb_results.xml` (MMIO cocotb regression results)
18. `sim_build/mmio_uvm_results.xml` (MMIO pyuvm regression results)
19. `sim_build/mmio_wait_cocotb_results.xml` (MMIO wait-state cocotb regression results)
20. `sim_build/mmio_wait_uvm_results.xml` (MMIO wait-state pyuvm regression results)
21. `sim_build/verilator_results.xml` (core cocotb-Verilator JUnit results)
22. `sim_build/apb_cocotb_results.xml` (APB cocotb regression results)
23. `sim_build/apb_uvm_results.xml` (APB pyuvm regression results)
24. `sim_build/wishbone_cocotb_results.xml` (Wishbone cocotb regression results)
25. `sim_build/wishbone_uvm_results.xml` (Wishbone pyuvm regression results)
24. `equiv/simple_cpu_eqy/` (EQY workdir and proof partitions)

Additional outputs:

1. `sim_build/program.hex` (from assembler flow)

Implementation note:

1. Native `covergroup` syntax is not supported by the open-source simulator combo used here, so coverage is modeled with explicit sampled bins/cross-bins in SV tasks.
2. Formal properties are checked with SymbiYosys (`formal/simple_cpu.sby`, `formal/simple_cpu_mmio.sby`, `formal/simple_cpu_mmio_wait.sby`, `formal/simple_cpu_mmio_wait_faults.sby`, `formal/simple_cpu_apb.sby`, `formal/simple_cpu_apb_faults.sby`, and `formal/simple_cpu_wishbone.sby`) in bounded mode.
3. Automation scripts are organized by platform under `scripts/windows` and `scripts/linux`, with top-level wrappers in `scripts/`.
4. The Python `CoverageModel` mirrors the native SV coverage pass/fail conditions, including reachability checks for impossible bins.
5. `rtl/simple_cpu_mmio.sv` adds a tiny wrapper state machine that loads a shadow program image into the core over the existing programming interface before releasing execution.
6. The assembler corpus can replay through the direct core testbench, the MMIO wrapper testbench, the wait-state MMIO wrapper testbench, the APB wrapper testbench, or the Wishbone wrapper testbench.
7. `tb/simple_cpu_wrapper_common_assertions.svh` centralizes the hold/load/run, loader-signal, and control-readback invariants that every wrapper must satisfy.
8. `tb/simple_cpu_mmio_assertions.sv` adds reusable interface assertions around `bus_ready` and instantiates the common checker library.
9. `tb/simple_cpu_mmio_wait_assertions.sv` is the parallel wait-state checker for delayed `bus_ready`, request capture, stable pending transaction fields, and the shared wrapper invariants from the common checker library.
10. `tb/simple_cpu_apb_assertions.sv` is the parallel APB checker for setup/access sequencing, `PREADY` gating, and the shared wrapper invariants from the common checker library.
11. `scripts/show-mmio-coverage.ps1` / `scripts/show-mmio-coverage.sh` summarize the MMIO wrapper coverage report without opening JSON manually.
12. `scripts/show-mmio-wait-coverage.ps1` / `scripts/show-mmio-wait-coverage.sh` summarize the wait-state MMIO wrapper coverage report without opening JSON manually.
13. `scripts/show-apb-coverage.ps1` / `scripts/show-apb-coverage.sh` summarize the APB wrapper coverage report without opening JSON manually.
14. `scripts/show-apb-fault-coverage.ps1` / `scripts/show-apb-fault-coverage.sh` summarize the APB fault-injection coverage report without opening JSON manually.
15. `scripts/coverage_history.py` plus wrapper commands track core/MMIO/MMIO-wait/APB coverage snapshots in `docs/coverage-history.json` and render ASCII trend output.
16. CI workflow is in `.github/workflows/ci.yml` and is split into native-sim, lint, formal, cocotb-verilator, equivalence, pyuvm, mutations, and summary jobs; the `native-sim` job now runs the direct core, MMIO, MMIO wait-state, APB, Wishbone, and APB fault native lanes plus corpus replay through APB, Wishbone, and MMIO wait-state, while the `pyuvm` job runs the direct pyuvm, MMIO pyuvm, MMIO cocotb, MMIO wait-state cocotb, MMIO wait-state pyuvm, APB cocotb, APB pyuvm, Wishbone cocotb, and Wishbone pyuvm regressions.
17. Baseline comparisons are run through `scripts/check-coverage-delta.ps1` and `scripts/check-coverage-delta.sh`.
18. `scripts/show-formal-status.ps1` / `scripts/show-formal-status.sh` summarize formal target health and solver/runtime metadata across core, MMIO, MMIO wait-state, MMIO wait-state fault, APB, APB-fault, and Wishbone prove/cover targets.
19. `scripts/export-status.ps1` / `scripts/export-status.sh` export repo-tracked verification status Markdown/JSON plus badge endpoint payloads, including optional suite summaries such as `mmio_wait_coverage`, `pyuvm_coverage`, `cocotb_verilator`, `mmio_cocotb`, `mmio_pyuvm`, `mmio_wait_cocotb`, `mmio_wait_pyuvm`, `apb_coverage`, `apb_fault_coverage`, `apb_cocotb`, `apb_pyuvm`, `wishbone_coverage`, `wishbone_cocotb`, and `wishbone_pyuvm`.
20. `tb/protocol_conformance.py` is the shared scenario library that replays the same smoke, logic, loop, branch-stress, and randomized programs across the direct core, MMIO, APB, and Wishbone buses.
21. `tb/core_bus.py`, `tb/mmio_bus.py`, `tb/apb_bus.py`, and `tb/wishbone_bus.py` expose the same high-level load/start/sample interface so the shared conformance suite can verify wrapper parity instead of only per-wrapper local tests.
22. `formal/simple_cpu_mmio.sby` swaps in an abstract `simple_cpu` stub so the wrapper proof focuses on MMIO control/address behavior instead of re-proving CPU internals.
23. `formal/simple_cpu_mmio_wait.sby` swaps in an abstract `simple_cpu_mmio` stub so the wait-state proof focuses on request latching, fixed-cycle delay, and delayed read-data pass-through instead of re-proving MMIO internals.
24. `formal/simple_cpu_mmio_wait_faults.sby` keeps a separate wait-state fault proof focused on captured-request integrity under later external bus glitches and on forbidding early `bus_ready` responses.
25. `formal/simple_cpu_apb.sby` swaps in an abstract `simple_cpu_mmio` stub so the APB proof focuses on setup/access handshake behavior and MMIO read-data pass-through instead of re-proving MMIO internals.
26. `formal/simple_cpu_apb_faults.sby` keeps APB fault proofs separate from the baseline APB shell contract by driving deterministic setup/glitch/reload sequences through a small stateful MMIO stub.
27. The dedicated `formal/*cover_formal.sv` harnesses keep `sby cover` focused on one witness goal per target so trace generation stays fast.
28. `scripts/run-cocotb-verilator.sh` auto-uses a cached Linux OSS CAD Suite Verilator when the distro package is too old for cocotb.
29. `scripts/static_analysis.py` is the single entry point behind `lint`, `show-static-analysis`, and `format-sv`.
30. `equiv/simple_cpu_golden.sv` is the tracked golden snapshot; refresh it intentionally with `scripts/update-equivalence-golden.*` only when the new RTL behavior is meant to become the baseline.
31. `formal/simple_cpu_wishbone.sby` swaps in an abstract `simple_cpu_mmio` stub so the Wishbone proof focuses on `CYC/STB/ACK` translation and MMIO read-data pass-through instead of re-proving MMIO internals.
32. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, `rtl/simple_cpu_apb.sv`, and `rtl/simple_cpu_wishbone.sv`; those files remain covered by Verilator lint and svlint.
33. `tb/mmio_bus.py` factors the cocotb MMIO reset/read/write/control helpers into a reusable Python bus-functional layer and now waits for delayed `bus_ready`, so the same helper can drive both the always-ready and wait-state wrappers.
34. `tb/apb_bus.py` is the parallel reusable Python bus-functional layer for the APB shell, keeping the higher-level control/status semantics aligned with MMIO while checking a real setup/access handshake.
35. `tb/wishbone_bus.py` is the parallel reusable Python bus-functional layer for the Wishbone shell, keeping the higher-level control/status semantics aligned with MMIO while checking a real `CYC/STB/ACK` handshake.

Formal properties currently checked:

1. Core halted state is sticky (`HALTED` stays high and `PC` stops advancing once halted).
2. Core programming interface stalls execution state updates while `prog_we` is asserted.
3. MMIO `bus_ready` stays asserted for every request.
4. MMIO status, `ACC`, `PC`, control, and representative shadow-window reads return the expected encoded values.
5. MMIO `HOLD`, `LOAD`, and `RUN` transitions follow the intended control-register protocol.
6. MMIO loader signals (`core_rst_n`, `prog_we`, `prog_addr`) stay aligned with wrapper state.
7. Representative shadow-image slots update only on addressed writes and otherwise remain stable across hold/load/run operation.
8. MMIO wait-state `bus_ready` stays low until the fixed wait expires, then mirrors the inner MMIO ready signal.
9. MMIO wait-state request fields (`write`, `addr`, `wdata`) are captured once and stay stable until service.
10. MMIO wait-state read data is exactly the delayed inner MMIO read data.
11. MMIO wait-state fault proofs show a captured read request cannot be replaced by later external bus activity and cannot return ready/data before the configured delay expires.
12. APB `PREADY` stays low outside setup/access completion and matches the translated MMIO handshake during access.
13. APB status, `ACC`, `PC`, control, DMEM-window, and representative shadow-window reads match the abstract MMIO model.
14. APB-side `core_rst_n`, `prog_we`, `prog_addr`, and `prog_data` stay aligned with the translated MMIO programming path.
15. APB fault proofs show setup-only writes are ignored, `PENABLE` glitches without `PSEL` are ignored, and a shadow update made during `RUN` is only reloaded after an explicit stop/start sequence.
16. Wishbone `ACK` stays low when `CYC` is low or when `CYC` is high without `STB`, and matches the translated MMIO ready signal on active Wishbone transfers.
17. Wishbone status, `ACC`, `PC`, control, DMEM-window, and representative shadow-window reads match the abstract MMIO model.
18. Cover mode produces one core witness showing program-write then execute-to-halt, one MMIO witness showing start-to-run-to-halt, one MMIO wait-state witness showing request-to-delay-to-service, one APB witness showing setup-to-access-to-start-to-halt behavior, and one Wishbone witness showing cycle-to-strobe-to-run-to-halt behavior.

Known toolchain notes (non-fatal when runs pass):

1. Icarus may emit `always_*` constant-select warnings.
2. Yosys may emit `$global_clock` and memory-lowering warnings during formal prep.
3. The MMIO formal target uses an abstract core stub so the portable `cvc5` flow remains fast enough for CI without weakening the wrapper-level claims.
4. The Windows equivalence wrapper intentionally routes through WSL because some packaged `eqy.exe` builds are unstable.
5. `scripts/run-cocotb-verilator.sh` may download Linux OSS CAD Suite into `~/tools/oss-cad-suite/oss-cad-suite` when the system Verilator is older than the cocotb minimum.
6. If WSL reports `Bash/Service/E_UNEXPECTED` during a long-running bash command, restart WSL or rerun from PowerShell; that is a host-shell failure rather than a DUT/proof failure.
7. WSL formal runs from `/mnt/c/...` can be much slower than GitHub Actions or native Linux because of mounted-filesystem I/O overhead.
8. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, `rtl/simple_cpu_apb.sv`, and `rtl/simple_cpu_wishbone.sv`; those files are still covered by Verilator lint and svlint.

## Remaining exercises

1. Strengthen the MMIO formal harness from representative boundary checks to wider symbolic coverage over the full 16-byte shadow image.
2. Add a fifth wrapper protocol beyond the current MMIO always-ready, MMIO wait-state, APB, and Wishbone shells.
3. Extend the mutation set beyond the current MMIO wait-state and APB shell set, for example with proof-harness or Python-lane regressions.
4. Grow the mutation set further with automatically generated arithmetic/control-flow variants.
5. Extend the reusable Python bus-functional layer beyond this register-mapped interface once the project grows into a distinct protocol family.
