# Verification Plan (Basic CPU Tutorial)

## Verification goals

1. Confirm each opcode behaves per spec.
2. Confirm status flags (`ZERO`, `CARRY`, `NEG`, `OVERFLOW`, `HALTED`) update correctly.
3. Confirm control-flow behavior (`JMP`, `JZ`) works.
4. Confirm memory side effects (`STA`, `LDA`) are correct.
5. Confirm end-to-end state matches a reference model.
6. Confirm external assembled programs match the reference model.

## Current status (April 11, 2026)

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
11. `.\scripts\show-apb-coverage.ps1`: PASS
12. `.\scripts\record-coverage-history.ps1`: PASS
13. `.\scripts\show-coverage-trend.ps1`: PASS
14. `.\scripts\run-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
15. `.\scripts\run-mmio-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
16. `.\scripts\run-cocotb-mmio.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
17. `.\scripts\run-cocotb-mmio-wait.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
18. `.\scripts\run-mmio-wait-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
19. `.\scripts\run-cocotb-apb.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
20. `.\scripts\run-apb-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
21. `.\scripts\check-coverage-delta.ps1`: PASS
22. `.\scripts\run-mmio.ps1 -NoWaves`: PASS
23. `.\scripts\run-apb.ps1 -NoWaves`: PASS
24. `.\scripts\check-native.ps1`: PASS
25. `.\scripts\run-asm-corpus.ps1 -NoSimulate`: PASS
26. `.\scripts\run-asm-corpus.ps1 -Runner apb`: PASS
27. `.\scripts\run-mutations.ps1`: PASS
28. `.\scripts\show-mutations.ps1`: PASS
29. `bash scripts/run.sh --no-waves` (WSL Ubuntu): PASS
30. `bash scripts/run-mmio.sh --no-waves` (WSL Ubuntu): PASS
31. `bash scripts/run-apb.sh --no-waves` (WSL Ubuntu): PASS
32. `bash scripts/show-mmio-coverage.sh` (WSL Ubuntu): PASS
33. `bash scripts/show-apb-coverage.sh` (WSL Ubuntu): PASS
34. `bash scripts/check-native.sh`: PASS
35. `bash scripts/lint.sh` (WSL Ubuntu): PASS
36. `bash scripts/show-static-analysis.sh` (WSL Ubuntu): PASS
37. `bash scripts/run-formal.sh --mode all` (WSL Ubuntu, `cvc5`): PASS
38. `bash scripts/run-cocotb-verilator.sh --no-waves --coverage` (WSL Ubuntu): PASS
39. `bash scripts/run-cocotb-mmio.sh --no-waves` (WSL Ubuntu): PASS
40. `bash scripts/run-cocotb-mmio-wait.sh --no-waves` (WSL Ubuntu): PASS
41. `bash scripts/run-equiv.sh` (WSL Ubuntu): PASS
42. `bash scripts/run-uvm.sh --no-waves` (WSL Ubuntu): PASS
43. `bash scripts/run-mmio-uvm.sh --no-waves` (WSL Ubuntu): PASS
44. `bash scripts/run-mmio-wait-uvm.sh --no-waves` (WSL Ubuntu): PASS
45. `bash scripts/check-coverage-delta.sh` (WSL Ubuntu): PASS
46. `bash scripts/show-coverage-trend.sh` (WSL Ubuntu): PASS
47. `bash scripts/run-asm-corpus.sh --no-simulate` (WSL Ubuntu): PASS
48. `bash scripts/run-asm-corpus.sh --runner mmio` (WSL Ubuntu): PASS
49. `bash scripts/run-asm-corpus.sh --runner apb` (WSL Ubuntu): PASS
50. `bash scripts/run-mutations.sh` (WSL Ubuntu): PASS
51. `bash scripts/show-mutations.sh` (WSL Ubuntu): PASS
52. `.\scripts\show-formal-status.ps1`: PASS
53. `.\scripts\export-status.ps1 -Label tutorial-regression`: PASS
54. `bash scripts/show-formal-status.sh` (WSL Ubuntu): PASS
55. `bash scripts/export-status.sh --label tutorial-regression`: PASS

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
| `test_apb_smoke` | `tb/simple_cpu_apb_tb.sv` | APB programming, shadow readback, loader start, and end-state comparison. |
| `test_apb_reprogram_sequence` | `tb/simple_cpu_apb_tb.sv` | Reset/reprogram/run sequencing plus APB control/status readback checks. |
| `test_apb_illegal_opcode` | `tb/simple_cpu_apb_tb.sv` | APB replay of illegal-opcode handling and safe halt behavior. |
| `test_apb_jump_sub_cmp_sequence` | `tb/simple_cpu_apb_tb.sv` | Wrapper-level `SUB/CMP/JMP` replay that closes the APB native control-flow gap. |
| `test_apb_shadow_fault_injection` | `tb/simple_cpu_apb_tb.sv` | Writes a modified shadow image while the wrapper is already running, then proves the current run stays on the original program and only the next reload observes the injected change. |
| `test_external_program` | `tb/simple_cpu_apb_tb.sv` | Optional `.hex` replay through the APB wrapper against the reference model. |
| `report_and_check_apb_coverage` | `tb/simple_cpu_apb_tb.sv` | APB protocol/transaction coverage thresholds and artifact emission. |
| `simple_cpu_apb_assertions` | `tb/simple_cpu_apb_assertions.sv` | Assertion-based checker for APB setup/access sequencing, `PREADY` gating, and control/readback alignment. |
| `directed_arithmetic_and_branch` | `tb/test_simple_cpu.py` | Optional cocotb directed test mirroring simulator-native checks. |
| `randomized_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb randomized/reference-model check. |
| `branch_stress_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb bounded-loop branch-stress/reference-model check. |
| `assembler_corpus_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb replay of the tracked assembler corpus against the DUT and reference model. |
| `program_write_stalls_and_retargets_execution` | `tb/test_simple_cpu.py` | Holds `prog_we` across consecutive cycles, proves architectural state stalls, and confirms a future instruction patch is honored once execution resumes. |
| `mmio_program_matches_reference_model` | `tb/test_simple_cpu_mmio.py` | Optional cocotb MMIO wrapper replay against the same `ReferenceCPU` used by the native bench. |
| `mmio_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_mmio.py` | Python-side bus-level check that shadow writes during `RUN` do not perturb the current run and only take effect after reload. |
| `mmio_control_status_readback` | `tb/test_simple_cpu_mmio.py` | Reads `CONTROL`, `STATUS`, `ACC`, and DMEM through MMIO across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `run-cocotb-verilator` | `scripts/run-cocotb-verilator.*` | Runs the cocotb core regression on Verilator and emits structural coverage artifacts. |
| `run-cocotb-mmio` | `scripts/run-cocotb-mmio.*` | Runs the dedicated MMIO cocotb regression on Icarus with bus-level programming/readback checks. |
| `run-cocotb-mmio-wait` | `scripts/run-cocotb-mmio-wait.*` | Replays the same MMIO cocotb suite against the wait-state wrapper variant and proves the Python bus helper tolerates delayed `bus_ready`. |
| `apb_program_matches_reference_model` | `tb/test_simple_cpu_apb.py` | Optional cocotb APB-wrapper replay against the same `ReferenceCPU` used by the MMIO and native benches. |
| `apb_shadow_fault_injection_requires_reload` | `tb/test_simple_cpu_apb.py` | APB-side shadow-image change check proving the current run is isolated until reload. |
| `apb_control_status_readback` | `tb/test_simple_cpu_apb.py` | Reads APB-exposed `CONTROL`, `STATUS`, `ACC`, and DMEM through the APB shell across `HOLD`, `LOAD`, `RUN`, and `HALT`. |
| `apb_setup_phase_requires_penable` | `tb/test_simple_cpu_apb.py` | Protocol-focused APB check that `PREADY` stays low during setup until `PENABLE` is asserted. |
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
11. `sim_build/apb_coverage.json` / `sim_build/apb_coverage.csv` (APB wrapper transaction coverage)
12. `sim_build/verilator_coverage/summary.json` / `sim_build/verilator_coverage/summary.md` (Verilator structural coverage summary)
13. `sim_build/verilator_coverage/annotated/` (annotated source view for uncovered points)
14. `sim_build/static_analysis/summary.json` / `sim_build/static_analysis/summary.md` (static-analysis aggregate summary)
15. `sim_build/mmio_cocotb_results.xml` (MMIO cocotb regression results)
16. `sim_build/mmio_uvm_results.xml` (MMIO pyuvm regression results)
17. `sim_build/mmio_wait_cocotb_results.xml` (MMIO wait-state cocotb regression results)
18. `sim_build/mmio_wait_uvm_results.xml` (MMIO wait-state pyuvm regression results)
19. `sim_build/verilator_results.xml` (core cocotb-Verilator JUnit results)
20. `sim_build/apb_cocotb_results.xml` (APB cocotb regression results)
21. `sim_build/apb_uvm_results.xml` (APB pyuvm regression results)
22. `equiv/simple_cpu_eqy/` (EQY workdir and proof partitions)

Additional outputs:

1. `sim_build/program.hex` (from assembler flow)

Implementation note:

1. Native `covergroup` syntax is not supported by the open-source simulator combo used here, so coverage is modeled with explicit sampled bins/cross-bins in SV tasks.
2. Formal properties are checked with SymbiYosys (`formal/simple_cpu.sby`, `formal/simple_cpu_mmio.sby`, and `formal/simple_cpu_apb.sby`) in bounded mode.
3. Automation scripts are organized by platform under `scripts/windows` and `scripts/linux`, with top-level wrappers in `scripts/`.
4. The Python `CoverageModel` mirrors the native SV coverage pass/fail conditions, including reachability checks for impossible bins.
5. `rtl/simple_cpu_mmio.sv` adds a tiny wrapper state machine that loads a shadow program image into the core over the existing programming interface before releasing execution.
6. The assembler corpus can replay through the direct core testbench, the MMIO wrapper testbench, or the APB wrapper testbench.
7. `tb/simple_cpu_mmio_assertions.sv` adds reusable interface assertions around `bus_ready`, control readback, and loader/reset signal alignment.
8. `tb/simple_cpu_apb_assertions.sv` is the parallel APB checker for setup/access sequencing, `PREADY` gating, and control/readback alignment.
9. `scripts/show-mmio-coverage.ps1` / `scripts/show-mmio-coverage.sh` summarize the MMIO wrapper coverage report without opening JSON manually.
10. `scripts/show-apb-coverage.ps1` / `scripts/show-apb-coverage.sh` summarize the APB wrapper coverage report without opening JSON manually.
11. `scripts/coverage_history.py` plus wrapper commands track core/MMIO/APB coverage snapshots in `docs/coverage-history.json` and render ASCII trend output.
12. CI workflow is in `.github/workflows/ci.yml` and is split into native-sim, lint, formal, cocotb-verilator, equivalence, pyuvm, mutations, and summary jobs; the `pyuvm` job now runs the direct pyuvm, MMIO pyuvm, MMIO cocotb, MMIO wait-state cocotb, MMIO wait-state pyuvm, APB cocotb, and APB pyuvm regressions.
13. Baseline comparisons are run through `scripts/check-coverage-delta.ps1` and `scripts/check-coverage-delta.sh`.
14. `scripts/show-formal-status.ps1` / `scripts/show-formal-status.sh` summarize formal target health and solver/runtime metadata across core, MMIO, and APB prove/cover targets.
15. `scripts/export-status.ps1` / `scripts/export-status.sh` export repo-tracked verification status Markdown/JSON plus badge endpoint payloads, including optional suite summaries such as `pyuvm_coverage`, `cocotb_verilator`, `mmio_cocotb`, `mmio_pyuvm`, `mmio_wait_cocotb`, `mmio_wait_pyuvm`, `apb_coverage`, `apb_cocotb`, and `apb_pyuvm`.
16. `formal/simple_cpu_mmio.sby` swaps in an abstract `simple_cpu` stub so the wrapper proof focuses on MMIO control/address behavior instead of re-proving CPU internals.
17. `formal/simple_cpu_apb.sby` swaps in an abstract `simple_cpu_mmio` stub so the APB proof focuses on setup/access handshake behavior and MMIO read-data pass-through instead of re-proving MMIO internals.
18. The dedicated `formal/*cover_formal.sv` harnesses keep `sby cover` focused on one witness goal per target so trace generation stays fast.
19. `scripts/run-cocotb-verilator.sh` auto-uses a cached Linux OSS CAD Suite Verilator when the distro package is too old for cocotb.
20. `scripts/static_analysis.py` is the single entry point behind `lint`, `show-static-analysis`, and `format-sv`.
21. `equiv/simple_cpu_golden.sv` is the tracked golden snapshot; refresh it intentionally with `scripts/update-equivalence-golden.*` only when the new RTL behavior is meant to become the baseline.
22. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, and `rtl/simple_cpu_apb.sv`; those files remain covered by Verilator lint and svlint.
23. `tb/mmio_bus.py` factors the cocotb MMIO reset/read/write/control helpers into a reusable Python bus-functional layer and now waits for delayed `bus_ready`, so the same helper can drive both the always-ready and wait-state wrappers.
24. `tb/apb_bus.py` is the parallel reusable Python bus-functional layer for the APB shell, keeping the higher-level control/status semantics aligned with MMIO while checking a real setup/access handshake.

Formal properties currently checked:

1. Core halted state is sticky (`HALTED` stays high and `PC` stops advancing once halted).
2. Core programming interface stalls execution state updates while `prog_we` is asserted.
3. MMIO `bus_ready` stays asserted for every request.
4. MMIO status, `ACC`, `PC`, control, and representative shadow-window reads return the expected encoded values.
5. MMIO `HOLD`, `LOAD`, and `RUN` transitions follow the intended control-register protocol.
6. MMIO loader signals (`core_rst_n`, `prog_we`, `prog_addr`) stay aligned with wrapper state.
7. Representative shadow-image slots update only on addressed writes and otherwise remain stable across hold/load/run operation.
8. APB `PREADY` stays low outside setup/access completion and matches the translated MMIO handshake during access.
9. APB status, `ACC`, `PC`, control, DMEM-window, and representative shadow-window reads match the abstract MMIO model.
10. APB-side `core_rst_n`, `prog_we`, `prog_addr`, and `prog_data` stay aligned with the translated MMIO programming path.
11. Cover mode produces one core witness showing program-write then execute-to-halt, one MMIO witness showing start-to-run-to-halt, and one APB witness showing setup-to-access-to-start-to-halt behavior.

Known toolchain notes (non-fatal when runs pass):

1. Icarus may emit `always_*` constant-select warnings.
2. Yosys may emit `$global_clock` and memory-lowering warnings during formal prep.
3. The MMIO formal target uses an abstract core stub so the portable `cvc5` flow remains fast enough for CI without weakening the wrapper-level claims.
4. The Windows equivalence wrapper intentionally routes through WSL because some packaged `eqy.exe` builds are unstable.
5. `scripts/run-cocotb-verilator.sh` may download Linux OSS CAD Suite into `~/tools/oss-cad-suite/oss-cad-suite` when the system Verilator is older than the cocotb minimum.
6. If WSL reports `Bash/Service/E_UNEXPECTED` during a long-running bash command, restart WSL or rerun from PowerShell; that is a host-shell failure rather than a DUT/proof failure.
7. WSL formal runs from `/mnt/c/...` can be much slower than GitHub Actions or native Linux because of mounted-filesystem I/O overhead.
8. Verible intentionally excludes `rtl/simple_cpu_mmio.sv`, `rtl/simple_cpu_mmio_wait.sv`, and `rtl/simple_cpu_apb.sv`; those files are still covered by Verilator lint and svlint.

## Remaining exercises

1. Strengthen the MMIO formal harness from representative boundary checks to wider symbolic coverage over the full 16-byte shadow image.
2. Add a fourth wrapper protocol beyond the current MMIO always-ready, MMIO wait-state, and APB shells.
3. Extend the mutation set beyond the APB shell, for example with MMIO wait-state or proof-harness regressions.
4. Grow the mutation set further with automatically generated arithmetic/control-flow variants.
5. Extend the reusable Python bus-functional layer beyond this register-mapped interface once the project grows into a distinct protocol family.
