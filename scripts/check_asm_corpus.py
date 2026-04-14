from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.asm import assemble, parse_source
from tb.coverage_utils import coverage_from_program, final_state_dict


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run the assembler regression corpus.")
    parser.add_argument(
        "--manifest",
        default="docs/assembler-regressions.json",
        help="Path to the assembler regression manifest.",
    )
    parser.add_argument(
        "--no-simulate",
        action="store_true",
        help="Skip invoking the RTL simulation after manifest checks.",
    )
    parser.add_argument(
        "--runner",
        choices=("direct", "mmio", "mmio_wait", "apb", "wishbone"),
        default="direct",
        help="Simulation runner to use when replaying programs through RTL.",
    )
    return parser.parse_args()


def compare_subset(expected, observed, prefix: str, failures: list[str]) -> None:
    if isinstance(expected, dict):
        if not isinstance(observed, dict):
            failures.append(f"{prefix}: expected object, got {type(observed).__name__}")
            return
        for key, value in expected.items():
            if key not in observed:
                failures.append(f"{prefix}.{key}: missing from observed data")
                continue
            next_prefix = f"{prefix}.{key}" if prefix else key
            compare_subset(value, observed[key], next_prefix, failures)
        return

    if isinstance(expected, list):
        if observed != expected:
            failures.append(f"{prefix}: expected {expected}, got {observed}")
        return

    if observed != expected:
        failures.append(f"{prefix}: expected {expected}, got {observed}")


def run_simulation(hex_path: Path, runner: str) -> None:
    if runner == "mmio":
        win_script = PROJECT_ROOT / "scripts" / "run-mmio.ps1"
        linux_script = "scripts/run-mmio.sh"
    elif runner == "mmio_wait":
        win_script = PROJECT_ROOT / "scripts" / "run-mmio-wait.ps1"
        linux_script = "scripts/run-mmio-wait.sh"
    elif runner == "apb":
        win_script = PROJECT_ROOT / "scripts" / "run-apb.ps1"
        linux_script = "scripts/run-apb.sh"
    elif runner == "wishbone":
        win_script = PROJECT_ROOT / "scripts" / "run-wishbone.ps1"
        linux_script = "scripts/run-wishbone.sh"
    else:
        win_script = PROJECT_ROOT / "scripts" / "run.ps1"
        linux_script = "scripts/run.sh"

    if os.name == "nt":
        cmd = [
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(win_script),
            "-NoWaves",
            "-ProgramHex",
            str(hex_path),
        ]
    else:
        cmd = [
            "bash",
            linux_script,
            "--no-waves",
            "--program-hex",
            str(hex_path),
        ]

    subprocess.run(cmd, cwd=PROJECT_ROOT, check=True)


def main() -> int:
    args = parse_args()
    manifest_path = PROJECT_ROOT / args.manifest
    with manifest_path.open("r", encoding="utf-8") as fh:
        manifest = json.load(fh)

    programs = manifest.get("programs", [])
    if not programs:
        print("[ASM-CORPUS][FAIL] No programs listed in manifest", file=sys.stderr)
        return 1

    output_dir = PROJECT_ROOT / "sim_build" / "asm_corpus"
    output_dir.mkdir(parents=True, exist_ok=True)

    failures: list[str] = []

    for entry in programs:
        name = entry["name"]
        source_path = PROJECT_ROOT / entry["source"]
        text = source_path.read_text(encoding="utf-8")
        stmts, labels = parse_source(text)
        mem = assemble(stmts, labels)
        observed_hex = [f"{value:02X}" for value in mem]
        entry_failures: list[str] = []

        compare_subset(entry.get("expected_hex", []), observed_hex, f"{name}.expected_hex", entry_failures)

        final_state = final_state_dict(mem, max_cycles=256)
        compare_subset(entry.get("expected_final", {}), final_state, f"{name}.expected_final", entry_failures)

        coverage = coverage_from_program(mem, max_cycles=256)
        compare_subset(entry.get("coverage_signature", {}), coverage, f"{name}.coverage_signature", entry_failures)

        hex_path = output_dir / f"{name}.hex"
        hex_path.write_text("\n".join(observed_hex) + "\n", encoding="utf-8")

        if not args.no_simulate:
            try:
                run_simulation(hex_path, args.runner)
            except subprocess.CalledProcessError as exc:
                entry_failures.append(f"{name}.simulation failed with exit code {exc.returncode}")

        failures.extend(entry_failures)

        if not entry_failures:
            print(f"[ASM-CORPUS][PASS] {name}")
        else:
            print(f"[ASM-CORPUS][FAIL] {name}")

    if failures:
        print("[ASM-CORPUS] regression corpus failed")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"[ASM-CORPUS] all {len(programs)} programs passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
