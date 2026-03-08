# Verification Plan (Basic CPU Tutorial)

## Verification goals

1. Confirm each opcode behaves per spec.
2. Confirm status flags (`ZERO`, `CARRY`, `NEG`, `OVERFLOW`, `HALTED`) update correctly.
3. Confirm control-flow behavior (`JMP`, `JZ`) works.
4. Confirm memory side effects (`STA`, `LDA`) are correct.
5. Confirm end-to-end state matches a reference model.
6. Confirm external assembled programs match the reference model.

## Current status (March 8, 2026)

1. `.\scripts\run.ps1 -NoWaves`: PASS
2. `.\scripts\lint.ps1`: PASS
3. `.\scripts\run-formal.ps1`: PASS (auto-selected `cvc5`)
4. `.\scripts\run-formal.ps1 -Mode cover`: PASS
5. `.\scripts\run-cocotb-verilator.ps1 -NoWaves -Coverage`: PASS (falls back to WSL, auto-uses Linux OSS CAD Suite Verilator 5.047)
6. `.\scripts\show-verilator-coverage.ps1`: PASS
7. `.\scripts\run-equiv.ps1`: PASS (routes through WSL EQY)
8. `.\scripts\show-coverage.ps1`: PASS (`opcode_hit_bitmap=111111111111111`)
9. `.\scripts\show-mmio-coverage.ps1`: PASS
10. `.\scripts\record-coverage-history.ps1`: PASS
11. `.\scripts\show-coverage-trend.ps1`: PASS
12. `.\scripts\run-uvm.ps1 -NoWaves`: PASS (falls back to WSL when native `make` is unavailable)
13. `.\scripts\check-coverage-delta.ps1`: PASS
14. `.\scripts\run-mmio.ps1 -NoWaves`: PASS
15. `.\scripts\check-native.ps1`: PASS
16. `.\scripts\run-asm-corpus.ps1 -NoSimulate`: PASS
17. `.\scripts\run-mutations.ps1`: PASS
18. `.\scripts\show-mutations.ps1`: PASS
19. `bash scripts/run.sh --no-waves` (WSL Ubuntu): PASS
20. `bash scripts/run-mmio.sh --no-waves` (WSL Ubuntu): PASS
21. `bash scripts/show-mmio-coverage.sh` (WSL Ubuntu): PASS
22. `bash scripts/check-native.sh`: PASS
23. `bash scripts/lint.sh` (WSL Ubuntu): PASS
24. `bash scripts/run-formal.sh --mode all` (WSL Ubuntu, `cvc5`): PASS
25. `bash scripts/run-cocotb-verilator.sh --no-waves --coverage` (WSL Ubuntu): PASS
26. `bash scripts/run-equiv.sh` (WSL Ubuntu): PASS
27. `bash scripts/run-uvm.sh --no-waves` (WSL Ubuntu): PASS
28. `bash scripts/check-coverage-delta.sh` (WSL Ubuntu): PASS
29. `bash scripts/show-coverage-trend.sh` (WSL Ubuntu): PASS
30. `bash scripts/run-asm-corpus.sh --no-simulate` (WSL Ubuntu): PASS
31. `bash scripts/run-asm-corpus.sh --runner mmio` (WSL Ubuntu): PASS
32. `bash scripts/run-mutations.sh` (WSL Ubuntu): PASS
33. `bash scripts/show-mutations.sh` (WSL Ubuntu): PASS
34. `.\scripts\show-formal-status.ps1`: PASS
35. `.\scripts\export-status.ps1 -Label tutorial-regression`: PASS
36. `bash scripts/show-formal-status.sh` (WSL Ubuntu): PASS
37. `bash scripts/export-status.sh --label tutorial-regression` (WSL Ubuntu): PASS

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
13. CI workflow on GitHub Actions for automated regression on push/PR.

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
| `test_external_program` | `tb/simple_cpu_mmio_tb.sv` | Optional `.hex` replay through the MMIO wrapper against the reference model. |
| `report_and_check_mmio_coverage` | `tb/simple_cpu_mmio_tb.sv` | Wrapper protocol/transaction coverage thresholds and artifact emission. |
| `directed_arithmetic_and_branch` | `tb/test_simple_cpu.py` | Optional cocotb directed test mirroring simulator-native checks. |
| `randomized_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb randomized/reference-model check. |
| `branch_stress_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb bounded-loop branch-stress/reference-model check. |
| `assembler_corpus_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb replay of the tracked assembler corpus against the DUT and reference model. |
| `run-cocotb-verilator` | `scripts/run-cocotb-verilator.*` | Runs the cocotb core regression on Verilator and emits structural coverage artifacts. |
| `SimpleCpuUvmSmokeTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm (UVM-style) sequence/driver/subscriber smoke check. |
| `SimpleCpuUvmRandomizedTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm randomized program check against reference model. |
| `SimpleCpuUvmBranchStressTest` | `tb/test_simple_cpu_pyuvm.py` | Minimal pyuvm branch-stress program check against reference model. |
| `SimpleCpuUvmCoverageRegressionTest` | `tb/test_simple_cpu_pyuvm.py` | Deterministic + randomized pyuvm regression with subscriber-based coverage report emission. |
| `run-asm-corpus` | `scripts/check_asm_corpus.py` + wrappers | Manifest-driven assembler regression corpus; checks bytes, final state, and coverage signatures. |
| `run-mutations` | `scripts/run_mutation_campaign.py` + wrappers | Builds temporary broken RTL variants and confirms the regressions kill them. |
| `run-formal --mode cover` | `scripts/run-formal.*` + `formal/*cover*` | Generates witness traces for representative core/MMIO reachable scenarios. |
| `run-equiv` | `scripts/run-equiv.*` + `equiv/simple_cpu.eqy` | Proves the current core matches the tracked golden RTL snapshot. |

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
11. `sim_build/verilator_coverage/summary.json` / `sim_build/verilator_coverage/summary.md` (Verilator structural coverage summary)
12. `sim_build/verilator_coverage/annotated/` (annotated source view for uncovered points)
13. `equiv/simple_cpu_eqy/` (EQY workdir and proof partitions)

Additional outputs:

1. `sim_build/program.hex` (from assembler flow)

Implementation note:

1. Native `covergroup` syntax is not supported by the open-source simulator combo used here, so coverage is modeled with explicit sampled bins/cross-bins in SV tasks.
2. Formal properties are checked with SymbiYosys (`formal/simple_cpu.sby` and `formal/simple_cpu_mmio.sby`) in bounded mode.
3. Automation scripts are organized by platform under `scripts/windows` and `scripts/linux`, with top-level wrappers in `scripts/`.
4. The Python `CoverageModel` mirrors the native SV coverage pass/fail conditions, including reachability checks for impossible bins.
5. `rtl/simple_cpu_mmio.sv` adds a tiny wrapper state machine that loads a shadow program image into the core over the existing programming interface before releasing execution.
6. The assembler corpus can replay through either the direct core testbench or the MMIO wrapper testbench.
7. `tb/simple_cpu_mmio_tb.sv` now includes protocol assertions (`bus_ready` always high during requests) plus sampled transaction/state coverage.
8. `scripts/show-mmio-coverage.ps1` / `scripts/show-mmio-coverage.sh` summarize the wrapper coverage report without opening JSON manually.
9. `scripts/coverage_history.py` plus wrapper commands track coverage snapshots in `docs/coverage-history.json` and render ASCII trend output.
10. CI workflow is in `.github/workflows/ci.yml` and is split into native-sim, lint, formal, cocotb-verilator, equivalence, pyuvm, mutations, and summary jobs.
11. Baseline comparisons are run through `scripts/check-coverage-delta.ps1` and `scripts/check-coverage-delta.sh`.
12. `scripts/show-formal-status.ps1` / `scripts/show-formal-status.sh` summarize formal target health and solver/runtime metadata.
13. `scripts/export-status.ps1` / `scripts/export-status.sh` export repo-tracked verification status Markdown/JSON plus badge endpoint payloads.
14. `formal/simple_cpu_mmio.sby` swaps in an abstract `simple_cpu` stub so the wrapper proof focuses on MMIO control/address behavior instead of re-proving CPU internals.
15. The dedicated `formal/*cover_formal.sv` harnesses keep `sby cover` focused on one witness goal per target so trace generation stays fast.
16. `scripts/run-cocotb-verilator.sh` auto-uses a cached Linux OSS CAD Suite Verilator when the distro package is too old for cocotb.
17. `equiv/simple_cpu_golden.sv` is the tracked golden snapshot; refresh it intentionally with `scripts/update-equivalence-golden.*` only when the new RTL behavior is meant to become the baseline.

Formal properties currently checked:

1. Core halted state is sticky (`HALTED` stays high and `PC` stops advancing once halted).
2. Core programming interface stalls execution state updates while `prog_we` is asserted.
3. MMIO `bus_ready` stays asserted for every request.
4. MMIO status, `ACC`, `PC`, control, and representative shadow-window reads return the expected encoded values.
5. MMIO `HOLD`, `LOAD`, and `RUN` transitions follow the intended control-register protocol.
6. MMIO loader signals (`core_rst_n`, `prog_we`, `prog_addr`) stay aligned with wrapper state.
7. Representative shadow-image slots update only on addressed writes and otherwise remain stable across hold/load/run operation.
8. Cover mode produces one core witness showing program-write then execute-to-halt, plus one MMIO witness showing start-to-run-to-halt.

Known toolchain notes (non-fatal when runs pass):

1. Icarus may emit `always_*` constant-select warnings.
2. Yosys may emit `$global_clock` and memory-lowering warnings during formal prep.
3. The MMIO formal target uses an abstract core stub so the portable `cvc5` flow remains fast enough for CI without weakening the wrapper-level claims.
4. The Windows equivalence wrapper intentionally routes through WSL because some packaged `eqy.exe` builds are unstable.
5. `scripts/run-cocotb-verilator.sh` may download Linux OSS CAD Suite into `~/tools/oss-cad-suite/oss-cad-suite` when the system Verilator is older than the cocotb minimum.
6. If WSL reports `Bash/Service/E_UNEXPECTED` during a long-running bash command, restart WSL or rerun from PowerShell; that is a host-shell failure rather than a DUT/proof failure.
7. WSL formal runs from `/mnt/c/...` can be much slower than GitHub Actions or native Linux because of mounted-filesystem I/O overhead.

## Remaining exercises

1. Publish `docs/status/badges/*.json` through GitHub Pages or another static endpoint and wire them into the README.
2. Strengthen the MMIO formal harness from representative boundary checks to wider symbolic coverage over the full 16-byte shadow image.
3. Add a second static-analysis lane with Verible or svlint.
4. Grow the mutation set further with automatically generated arithmetic/control-flow variants.
5. Add a bus-functional Python driver layer that can replay the assembler corpus over future wrappers or buses.
