# Verification Plan (Basic CPU Tutorial)

## Verification goals

1. Confirm each opcode behaves per spec.
2. Confirm status flags (`ZERO`, `CARRY`, `NEG`, `OVERFLOW`, `HALTED`) update correctly.
3. Confirm control-flow behavior (`JMP`, `JZ`) works.
4. Confirm memory side effects (`STA`, `LDA`) are correct.
5. Confirm end-to-end state matches a reference model.
6. Confirm external assembled programs match the reference model.

## Current status (February 21, 2026)

1. `.\scripts\run.ps1 -NoWaves`: PASS
2. `.\scripts\lint.ps1`: PASS
3. `.\scripts\run-formal.ps1`: PASS
4. `.\scripts\show-coverage.ps1`: PASS (`opcode_hit_bitmap=111111111111111`)
5. `bash scripts/run.sh --no-waves` (WSL Ubuntu): PASS
6. `bash scripts/lint.sh` (WSL Ubuntu): PASS
7. `bash scripts/run-formal.sh` (WSL Ubuntu, `cvc5`): PASS

## Test strategy

1. Directed tests for fast, readable intent checks.
2. Multi-seed randomized dataflow programs for broader state exploration.
3. Reference-model comparison for robust end-state checking.
4. Lightweight functional coverage counters with threshold checks.

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
| `test_external_program` | `tb/simple_cpu_tb.sv` | Optional plusarg-driven external `.hex` program check vs model. |
| `report_and_check_coverage` | `tb/simple_cpu_tb.sv` | Coverage thresholds for opcode hits, branch outcomes, and flag transitions. |
| `directed_arithmetic_and_branch` | `tb/test_simple_cpu.py` | Optional cocotb directed test mirroring simulator-native checks. |
| `randomized_program_matches_reference_model` | `tb/test_simple_cpu.py` | Optional cocotb randomized/reference-model check. |

## Coverage model (simple functional coverage)

1. Opcode hit bitmap for `NOP..CMP`.
2. Illegal opcode path hit.
3. `JZ` taken and not-taken counters.
4. `ZERO` transition bins (`00`, `01`, `10`, `11`).
5. Cross bins: `opcode x post-instruction ZERO`.
6. Flag bins for `CARRY`, `NEG`, `OVERFLOW` (0 and 1 observed).
7. Program-run and executed-cycle counters.

Coverage artifacts:

1. `sim_build/coverage.json` (machine-readable summary + goals)
2. `sim_build/coverage.csv` (flat metrics for spreadsheets/CI parsing)

Additional outputs:

1. `sim_build/program.hex` (from assembler flow)

Implementation note:

1. Native `covergroup` syntax is not supported by the open-source simulator combo used here, so coverage is modeled with explicit sampled bins/cross-bins in SV tasks.
2. Formal properties are checked with SymbiYosys (`formal/simple_cpu.sby`) in bounded mode.
3. Automation scripts are organized by platform under `scripts/windows` and `scripts/linux`, with top-level wrappers in `scripts/`.

Formal properties currently checked:

1. Halted state is sticky (`HALTED` stays high and `PC` stops advancing once halted).
2. Programming interface stalls execution state updates while `prog_we` is asserted.

Known toolchain notes (non-fatal when runs pass):

1. Icarus may emit `always_*` constant-select warnings.
2. Yosys may emit `$global_clock` and memory-lowering warnings during formal prep.
3. On some WSL setups, formal with `z3` can be unstable; the bash flow defaults to `cvc5`.

## Remaining exercises

1. Add full opcode x (`ZERO`,`CARRY`,`NEG`,`OVERFLOW`) cross coverage.
2. Add branch-heavy random generator with loop bounds and jump constraints.
3. Add CI thresholds on coverage deltas and formal pass/fail.
