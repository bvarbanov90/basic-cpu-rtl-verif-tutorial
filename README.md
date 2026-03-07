# Basic CPU RTL Verification Tutorial (Open Source Only)

This project is a from-scratch tutorial for verifying a tiny CPU using only open-source tooling.

## What you will build

1. A tiny 8-bit CPU in SystemVerilog.
2. A simulator-native self-checking testbench (`tb/simple_cpu_tb.sv`).
3. Directed tests plus dataflow and branch-stress randomized regressions with reference-model comparison.
4. Waveform debug flow with open-source tools.
5. Assembler-corpus regressions with expected machine code, final state, and coverage signatures.
6. An MMIO wrapper flow that verifies interface-level programming and observability on top of the core.
7. Optional cocotb/pyuvm Python verification extensions.
8. A mutation campaign that proves the regressions kill representative RTL bugs.
9. A repo-tracked verification status export with Markdown, JSON, and badge-ready endpoints.

## Core tooling (all open source)

1. Icarus Verilog (`iverilog` + `vvp`)
2. GTKWave (optional waveform viewer)
3. Verilator (optional lint)

## Optional tooling (advanced step)

1. Python + cocotb + pyuvm
2. GNU Make (or WSL Ubuntu for the pyuvm flow)

Use Python 3.13 for the cocotb flow in this tutorial setup. On Windows, `.\scripts\run-uvm.ps1` falls back to WSL automatically if native `make` is not installed.

## Project layout

```text
basic-cpu-rlt--verif-tutorial/
|- rtl/
|  |- simple_cpu.sv
|  |- simple_cpu_mmio.sv
|- .github/
|  |- workflows/
|     |- ci.yml
|- formal/
|  |- simple_cpu.sby
|  |- simple_cpu_formal.sv
|  |- simple_cpu_mmio.sby
|  |- simple_cpu_mmio_formal.sv
|- programs/
|  |- branch_taken.asm
|  |- counter_loop.asm
|  |- logic_flags.asm
|  |- memory_roundtrip.asm
|  |- raw_illegal.asm
|  |- sparse_jump.asm
|- tb/
|  |- coverage_utils.py
|  |- cpu_lib.py
|  |- simple_cpu_mmio_tb.sv
|  |- simple_cpu_tb.sv
|  |- test_simple_cpu.py
|  |- test_simple_cpu_pyuvm.py
|- scripts/
|  |- asm.py
|  |- README.md
|  |- check_asm_corpus.py
|  |- export_status.py
|  |- run_mutation_campaign.py
|  |- show_formal_status.py
|  |- status_lib.py
|  |- windows/
|  |  |- install-tools.ps1
|  |  |- run.ps1
|  |  |- run-asm.ps1
|  |  |- run-asm-corpus.ps1
|  |  |- run-mmio.ps1
|  |  |- run-mutations.ps1
|  |  |- run-uvm.ps1
|  |  |- check-all.ps1
|  |  |- lint.ps1
|  |  |- run-formal.ps1
|  |  |- export-status.ps1
|  |  |- open-waves.ps1
|  |  |- open-waves.cmd
|  |  |- show-coverage.ps1
|  |  |- show-formal-status.ps1
|  |- linux/
|  |  |- install-tools-ubuntu.sh
|  |  |- run.sh
|  |  |- run-asm.sh
|  |  |- run-asm-corpus.sh
|  |  |- run-mmio.sh
|  |  |- run-mutations.sh
|  |  |- run-uvm.sh
|  |  |- check-all.sh
|  |  |- lint.sh
|  |  |- run-formal.sh
|  |  |- export-status.sh
|  |  |- open-waves.sh
|  |  |- show-coverage.sh
|  |  |- show-formal-status.sh
|  |- run.ps1 (wrapper)
|  |- run.sh (wrapper)
|  |- run-asm-corpus.ps1 / run-asm-corpus.sh (wrappers)
|  |- check-native.ps1 / check-native.sh (wrappers)
|  |- run-mmio.ps1 / run-mmio.sh (wrappers)
|  |- run-mutations.ps1 / run-mutations.sh (wrappers)
|  |- run-uvm.ps1 / run-uvm.sh (wrappers)
|  |- check-coverage-delta.ps1 / check-coverage-delta.sh (wrappers)
|  |- update-coverage-baseline.ps1 / update-coverage-baseline.sh (wrappers)
|  |- check-all.ps1 / check-all.sh (wrappers)
|  |- export-status.ps1 / export-status.sh (wrappers)
|  |- show-formal-status.ps1 / show-formal-status.sh (wrappers)
|  |- ... (compat wrappers for old paths)
|- docs/
|  |- assembler-regressions.json
|  |- coverage-baseline.json
|  |- status/
|  |  |- status.json
|  |  |- status.md
|  |  |- badges/*.json
|  |- verification-plan.md
|- Makefile
|- requirements.txt
|- README.md
```

Script organization note:

1. `scripts/windows/*` and `scripts/linux/*` are the platform-specific implementations.
2. `scripts/*.ps1` and `scripts/*.sh` at the top level are compatibility wrappers.
3. Existing commands from earlier tutorial steps continue to work.

## CPU summary

1. `imem[16]`: 16-byte instruction memory.
2. `dmem[16]`: 16-byte data memory.
3. Registers: `ACC` (8-bit accumulator), `PC` (4-bit), flags `ZERO/CARRY/NEG/OVERFLOW`, `HALTED`.
4. Instruction format: `[7:4] opcode`, `[3:0] operand`.

### ISA

| Opcode | Mnemonic | Behavior |
|---|---|---|
| `0x0` | `NOP` | no operation |
| `0x1` | `LDI imm4` | `ACC = imm4` |
| `0x2` | `ADD addr4` | `ACC = ACC + DMEM[addr4]` |
| `0x3` | `SUB addr4` | `ACC = ACC - DMEM[addr4]` |
| `0x4` | `STA addr4` | `DMEM[addr4] = ACC` |
| `0x5` | `LDA addr4` | `ACC = DMEM[addr4]` |
| `0x6` | `JMP addr4` | `PC = addr4` |
| `0x7` | `JZ addr4` | if `ZERO`, `PC = addr4` |
| `0x8` | `HLT` | halt execution |
| `0x9` | `AND addr4` | `ACC = ACC & DMEM[addr4]` |
| `0xA` | `OR addr4` | `ACC = ACC \| DMEM[addr4]` |
| `0xB` | `XOR addr4` | `ACC = ACC ^ DMEM[addr4]` |
| `0xC` | `SHL` | `ACC = ACC << 1` |
| `0xD` | `SHR` | `ACC = ACC >> 1` |
| `0xE` | `CMP addr4` | update flags from `ACC - DMEM[addr4]` (no write to `ACC`) |
| `0xF` | `ILLEGAL` | default trap-to-halt behavior |

## Quick start (recommended path)

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\run.ps1
```

To run without dumping waveforms:

```powershell
.\scripts\run.ps1 -NoWaves
```

To run with an external assembled program:

```powershell
.\scripts\run.ps1 -ProgramHex sim_build\program.hex
```

To assemble and run in one step:

```powershell
.\scripts\run-asm.ps1 -Source programs\logic_flags.asm
```

To run the MMIO wrapper regression:

```powershell
.\scripts\run-mmio.ps1 -NoWaves
```

To summarize the wrapper coverage report:

```powershell
.\scripts\show-mmio-coverage.ps1
```

To run the tracked assembler corpus:

```powershell
.\scripts\run-asm-corpus.ps1
```

To replay the tracked assembler corpus through the MMIO wrapper:

```powershell
.\scripts\run-asm-corpus.ps1 -Runner mmio
```

To summarize the formal targets:

```powershell
.\scripts\show-formal-status.ps1
```

To export a repo-tracked status snapshot:

```powershell
.\scripts\export-status.ps1 -Label tutorial-regression
```

To open the generated waveform:

```powershell
.\scripts\open-waves.ps1
```

Alternative (cmd wrapper):

```cmd
scripts\open-waves.cmd
```

## WSL Ubuntu (bash)

Install Linux tools once:

```bash
cd /mnt/c/Users/bvarb/vscode_ws/basic-cpu-rlt--verif-tutorial
bash scripts/install-tools-ubuntu.sh
```

Run simulation:

```bash
bash scripts/run.sh --no-waves
```

Run with an assembled program:

```bash
bash scripts/run-asm.sh --source programs/logic_flags.asm --no-waves
```

Run lint:

```bash
bash scripts/lint.sh
```

Run formal:

```bash
bash scripts/run-formal.sh
```

Run minimal pyuvm tests:

```bash
bash scripts/run-uvm.sh --no-waves
```

Run the assembler regression corpus:

```bash
bash scripts/run-asm-corpus.sh
```

Run the MMIO wrapper regression:

```bash
bash scripts/run-mmio.sh --no-waves
```

Show the wrapper coverage report:

```bash
bash scripts/show-mmio-coverage.sh
```

Show the formal target summary:

```bash
bash scripts/show-formal-status.sh
```

Export the repo-tracked status snapshot:

```bash
bash scripts/export-status.sh --label tutorial-regression
```

Notes:

1. `scripts/run-formal.sh` auto-selects `cvc5` first, then `z3`, then `boolector`.
2. `.\scripts\run-formal.ps1` follows the same rule and accepts `-Solver cvc5`, `-Solver z3`, or `-Solver boolector`.
3. Open waves in WSLg with: `bash scripts/open-waves.sh`.
4. Use `bash scripts/run-asm-corpus.sh --no-simulate` when you want manifest checking without overwriting the main regression coverage report.
5. Use `bash scripts/run-asm-corpus.sh --runner mmio` to replay the corpus through the wrapper instead of the direct core testbench.
6. If you want WSL formal timings closer to GitHub Actions, keep the repo under the Linux filesystem (for example `~/basic-cpu-rlt--verif-tutorial`) instead of `/mnt/c/...`.

If you saw `libcairo-2.dll` or GTK `libpixbufloader-svg.dll` errors before, these launcher scripts apply a compatibility workaround automatically.

Direct implementation paths (optional):

1. Windows PowerShell: `.\scripts\windows\run.ps1`
2. Linux bash: `bash scripts/linux/run.sh`

## Lint

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\lint.ps1
```

## Formal checks

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\run-formal.ps1
```

Override the solver on Windows if needed:

```powershell
.\scripts\run-formal.ps1 -Solver cvc5
```

Show the target-level formal summary:

```powershell
.\scripts\show-formal-status.ps1
```

The formal flow now runs both:

1. `formal/simple_cpu.sby`
2. `formal/simple_cpu_mmio.sby`

Current formal properties cover:

1. core halted-state stickiness and programming-interface execution stalling,
2. MMIO `bus_ready` always-ready behavior,
3. MMIO address-map readback for status, `ACC`, `PC`, control, and boundary shadow slots,
4. MMIO `HOLD/LOAD/RUN` state transitions and loader sequencing,
5. representative shadow-image update/stability rules during hold, load, and run phases.

The MMIO formal target uses an abstract debug-core stub instead of the full CPU implementation. Core behavior is already proved separately in `formal/simple_cpu.sby`; the wrapper proof focuses on MMIO loader/control/address-map logic so the CI formal step stays short.

## Full project sanity check

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\check-all.ps1
```

WSL/bash equivalent:

```bash
cd /mnt/c/Users/bvarb/vscode_ws/basic-cpu-rlt--verif-tutorial
bash scripts/check-all.sh
```

Native simulation only, without formal:

```powershell
.\scripts\check-native.ps1
```

```bash
bash scripts/check-native.sh
```

## CI

GitHub Actions workflow `main`/PR checks are defined in `.github/workflows/ci.yml` and are split into focused jobs:

1. `native-sim`: `bash scripts/check-native.sh` plus MMIO corpus replay
2. `lint`: `bash scripts/lint.sh`
3. `formal`: `bash scripts/run-formal.sh`
4. `pyuvm`: `bash scripts/run-uvm.sh --no-waves`
5. `mutations`: `bash scripts/run-mutations.sh`
6. `summary`: workflow-level pass/fail table in the GitHub Actions summary page

Uploaded artifacts include:

1. `sim_build/coverage.json`
2. `sim_build/coverage.csv`
3. `sim_build/mmio_coverage.json`
4. `sim_build/mmio_coverage.csv`
5. `sim_build/pyuvm_coverage.json`
6. `sim_build/uvm_results.xml`
7. `sim_build/asm_corpus/`
8. `sim_build/mutations/`

## If tools are not installed yet

Recommended on Windows:

1. Run:

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
.\scripts\install-tools.ps1
```

2. Open a new PowerShell terminal.
3. Re-run `.\scripts\run.ps1`.

## Optional cocotb flow

Use this after the simulator-native flow works.

```powershell
cd C:\Users\bvarb\vscode_ws\basic-cpu-rlt--verif-tutorial
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
make SIM=icarus WAVES=1
```

Run the minimal pyuvm/UVM-style example:

```powershell
.\scripts\run-uvm.ps1 -NoWaves
```

```bash
bash scripts/run-uvm.sh --no-waves
```

The cocotb layer now also includes an assembler-corpus regression in `tb/test_simple_cpu.py`, and the pyuvm example in `tb/test_simple_cpu_pyuvm.py` now includes:

1. sequence-item driven smoke/random/branch tests,
2. deterministic corner-case sequences for `ADD/SUB/SHL/CMP` coverage closure,
3. a subscriber-based coverage collector that writes `sim_build/pyuvm_coverage.json`.

## MMIO wrapper flow

`rtl/simple_cpu_mmio.sv` wraps the core behind a tiny always-ready MMIO interface. It is intentionally simple enough to verify with the same open-source tools as the core.

Address map:

1. `0x00..0x0F`: shadow instruction image read/write window
2. `0x10`: status bits `{HALTED, OVERFLOW, NEG, CARRY, ZERO}`
3. `0x11`: `ACC`
4. `0x12`: `PC`
5. `0x20..0x2F`: data-memory read window
6. `0x30`: control/status register

Wrapper behavior:

1. Writing the instruction window updates a shadow program image.
2. Writing `0x30 = 0x01` resets the core into a 16-cycle loader phase, copies the shadow image into instruction memory, then starts execution.
3. Writing `0x30 = 0x00` returns the wrapper to hold/reset state for reprogramming.

The native wrapper testbench in `tb/simple_cpu_mmio_tb.sv` checks:

1. MMIO programming and instruction-shadow readback
2. reset/reprogram/run sequencing
3. a focused `SUB/CMP/JMP` sequence to close the wrapper mutation gap
4. status/data readback against the same reference-model semantics
5. external `.hex` program replay, so the tracked assembler corpus can run through the wrapper unchanged

It also writes wrapper-specific coverage artifacts:

1. `sim_build/mmio_coverage.json`
2. `sim_build/mmio_coverage.csv`

Quick summary commands:

```powershell
.\scripts\show-mmio-coverage.ps1
```

```bash
bash scripts/show-mmio-coverage.sh
```

Current MMIO coverage goals:

1. at least 4 wrapper program runs
2. shadow writes/reads cover the full 16-byte image on every run
3. data-memory reads cover the full 16-byte window on every run
4. status, `ACC`, and `PC` reads occur on every run
5. start/stop control writes occur on every run
6. `HOLD`, `LOAD`, and `RUN` wrapper states are all observed

## Assembler regression corpus

The project includes a small tracked corpus of assembly programs with expected outputs in `docs/assembler-regressions.json`.

Run it from PowerShell:

```powershell
.\scripts\run-asm-corpus.ps1
```

Run it from bash/WSL:

```bash
bash scripts/run-asm-corpus.sh
```

Use `.\scripts\run-asm-corpus.ps1 -NoSimulate` or `bash scripts/run-asm-corpus.sh --no-simulate` when you want manifest checks without overwriting the main native-regression coverage report.

What it checks:

1. assembler output bytes match the manifest,
2. reference-model final state matches the manifest,
3. reference-model coverage signature subset matches the manifest,
4. optional RTL replay per corpus program.

The replay target can be either:

1. the direct core testbench (`direct`, default)
2. the MMIO wrapper testbench (`mmio`)

Artifacts:

1. `sim_build/asm_corpus/*.hex`

## Mutation campaign

The project includes an optional mutation campaign that compiles temporary broken RTL variants and confirms the regressions fail.

Run it from PowerShell:

```powershell
.\scripts\run-mutations.ps1
```

Run it from bash/WSL:

```bash
bash scripts/run-mutations.sh
```

Readable summary commands:

```powershell
.\scripts\show-mutations.ps1
```

```bash
bash scripts/show-mutations.sh
```

Current mutants:

1. inverted `JZ` branch condition
2. disabled `STA` writes
3. broken `SHL` carry-out
4. illegal-opcode path that no longer halts
5. `ADD` driven from the subtraction datapath
6. `SUB` driven from the addition datapath
7. `JMP` forced to fall through
8. `CMP` incorrectly clobbers `ACC`
9. `HLT` no longer stops execution

Artifacts:

1. `sim_build/mutations/mutation_summary.json`
2. `sim_build/mutations/mutation_summary.md`
3. `sim_build/mutations/<mutant>/*_compile.log`
4. `sim_build/mutations/<mutant>/*_run.log`

The current campaign is expected to be killed by both the direct-core and MMIO wrapper benches.

## Suggested learning path

1. Run `.\scripts\run.ps1`.
2. Read `rtl/simple_cpu.sv` and trace opcode decode logic.
3. Read `tb/simple_cpu_tb.sv` and follow helper tasks (`reset_dut`, `load_program`, `run_until_halt`).
4. Study directed tests for branch-taken, branch-not-taken, jump loops, wraparound arithmetic, and illegal opcode handling.
5. Study how `test_randomized_suite` and `test_branch_randomized_suite` compare DUT state to a reference model over multiple seeds.
6. Review `report_and_check_coverage` and the generated `sim_build/coverage.json` cross-bins.
7. Break the RTL intentionally (for example, change `ADD` or `JZ`) and confirm tests/coverage gates fail.

## Functional coverage (simple model)

The SystemVerilog testbench includes sampled functional coverage implemented in portable SV tasks (compatible with Icarus/Verilator in this setup):

1. Opcode hit bitmap (`NOP..CMP`).
2. Illegal opcode path hit.
3. `JZ` taken and not-taken counters.
4. `ZERO` transition bins (`00`, `01`, `10`, `11`).
5. Cross bins: `opcode x post-instruction ZERO/CARRY/NEG/OVERFLOW`.
6. Flag bins (`CARRY/NEG/OVERFLOW` each observed as 0 and 1).
7. Reachability annotations for ISA-impossible opcode/flag bins.
8. Specific closure bins mirrored from the native checker (`JZ x ZERO`, `ADD/SUB x CARRY`, `SUB/CMP x NEG`, `SHL x OVERFLOW`).
9. Program-run and total-cycle counters.

Coverage thresholds are checked at end-of-run; unmet goals fail the simulation.

Coverage artifacts written on each run:

1. `sim_build/coverage.json`
2. `sim_build/coverage.csv`

The coverage reports label ISA-unreachable bins explicitly so a zero count does not look like a verification gap when the combination cannot occur by construction.
The repo also tracks a non-regression baseline in `docs/coverage-baseline.json`.

Coverage delta commands:

```powershell
.\scripts\check-coverage-delta.ps1
```

```bash
bash scripts/check-coverage-delta.sh
```

If you intentionally change the regression mix or improve coverage, regenerate the baseline after a clean passing run:

```powershell
.\scripts\update-coverage-baseline.ps1
```

```bash
bash scripts/update-coverage-baseline.sh
```

Quick summary command:

```powershell
.\scripts\show-coverage.ps1
```

```bash
bash scripts/show-coverage.sh
```

## Coverage history and trends

Snapshot the latest core/MMIO coverage into repo-tracked history files:

```powershell
.\scripts\record-coverage-history.ps1 -Label tutorial-regression
```

```bash
bash scripts/record-coverage-history.sh
```

Show the tracked ASCII trend report:

```powershell
.\scripts\show-coverage-trend.ps1
```

```bash
bash scripts/show-coverage-trend.sh
```

Tracked history files:

1. `docs/coverage-history.json`
2. `docs/coverage-history.md`

## Verification status export

After a passing run, export a repo-tracked verification snapshot:

```powershell
.\scripts\export-status.ps1 -Label tutorial-regression
```

```bash
bash scripts/export-status.sh --label tutorial-regression
```

Inspect the formal status without opening `formal/*` manually:

```powershell
.\scripts\show-formal-status.ps1
```

```bash
bash scripts/show-formal-status.sh
```

Generated status files:

1. `docs/status/status.json`
2. `docs/status/status.md`
3. `docs/status/badges/*.json`

The badge JSON files are compatible with shields.io endpoint badges when served from GitHub raw or GitHub Pages.

## Known benign warnings

1. Icarus can print `constant selects in always_* processes are not fully supported`.
2. SymbiYosys/Yosys can print warnings around `$global_clock` in the formal harness.
3. Yosys can print memory lowering notes (`Replacing memory ... with list of registers`).
4. The MMIO formal target uses an abstract core stub so the portable `cvc5` flow stays fast enough for CI without weakening the wrapper-level properties.
5. If WSL itself reports `Bash/Service/E_UNEXPECTED` during a long-running command, restart WSL or rerun from PowerShell; that is a host-side shell-service failure, not a proof result.
6. WSL runs from `/mnt/c/...` can be materially slower than native Linux or GitHub Actions due to mounted-filesystem I/O overhead.

These warnings are expected for this toolchain/tutorial and are non-fatal when all checks pass.

## Next extensions

1. Publish `docs/status/badges/*.json` via GitHub Pages or raw endpoints and wire them into the README.
2. Strengthen the MMIO formal harness from representative boundary checks to wider symbolic coverage of the 16-byte shadow image and read windows.
3. Auto-generate larger mutation sets from operator/control-flow templates instead of hand-authored snippet replacements.
4. Add a bus-functional Python driver layer that can replay the assembler corpus over future wrappers or buses.

## Publish To GitHub

1. Run both sanity flows before first push:

```powershell
.\scripts\check-all.ps1
```

```bash
bash scripts/check-all.sh
```

2. Initialize and push:

```powershell
git init
git checkout -b main
git add .
git commit -m "Initial commit: basic CPU RTL verification tutorial"
git remote add origin git@github.com:<user-or-org>/<repo-name>.git
git push -u origin main
```
