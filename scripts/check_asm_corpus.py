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
from tb.cpu_lib import MEM_SIZE


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
        choices=("direct", "mmio", "mmio_wait", "apb", "wishbone", "axi_lite"),
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


def validate_manifest(manifest: dict, manifest_path: Path) -> list[str]:
    failures: list[str] = []
    programs = manifest.get("programs", [])

    if not isinstance(programs, list) or not programs:
        return ["manifest.programs: expected a non-empty list"]

    seen_names: set[str] = set()
    seen_sources: set[str] = set()
    manifest_dir = manifest_path.parent
    project_root = manifest_dir.parent

    for index, entry in enumerate(programs):
        prefix = f"programs[{index}]"
        name = entry.get("name")
        source = entry.get("source")
        if not isinstance(name, str) or not name:
            failures.append(f"{prefix}.name: expected non-empty string")
        elif name in seen_names:
            failures.append(f"{prefix}.name: duplicate program name '{name}'")
        else:
            seen_names.add(name)

        if not isinstance(source, str) or not source:
            failures.append(f"{prefix}.source: expected non-empty string")
        else:
            source_path = project_root / source
            if source in seen_sources:
                failures.append(f"{prefix}.source: duplicate source '{source}'")
            else:
                seen_sources.add(source)
            if not source_path.exists():
                failures.append(f"{prefix}.source: file not found: {source}")
            elif source_path.suffix != ".asm":
                failures.append(f"{prefix}.source: expected .asm file: {source}")

        expected_hex = entry.get("expected_hex")
        if not isinstance(expected_hex, list) or len(expected_hex) != MEM_SIZE:
            failures.append(f"{prefix}.expected_hex: expected {MEM_SIZE} byte strings")
        else:
            for byte_index, value in enumerate(expected_hex):
                if not isinstance(value, str):
                    failures.append(f"{prefix}.expected_hex[{byte_index}]: expected string byte")
                    continue
                try:
                    parsed = int(value, 16)
                except ValueError:
                    failures.append(f"{prefix}.expected_hex[{byte_index}]: invalid hex byte '{value}'")
                    continue
                if value.upper() != value or len(value) != 2 or not (0 <= parsed <= 0xFF):
                    failures.append(f"{prefix}.expected_hex[{byte_index}]: expected two uppercase hex digits, got '{value}'")

        expected_final = entry.get("expected_final", {})
        dmem = expected_final.get("dmem") if isinstance(expected_final, dict) else None
        if not isinstance(dmem, list) or len(dmem) != MEM_SIZE:
            failures.append(f"{prefix}.expected_final.dmem: expected {MEM_SIZE} entries")

        coverage_signature = entry.get("coverage_signature")
        if not isinstance(coverage_signature, dict) or "opcode_hit_bitmap" not in coverage_signature:
            failures.append(f"{prefix}.coverage_signature: expected opcode_hit_bitmap")

    asm_sources = {
        str(path.relative_to(project_root)).replace("\\", "/")
        for path in sorted((project_root / "programs").glob("*.asm"))
    }
    missing_from_manifest = sorted(asm_sources - seen_sources)
    extra_in_manifest = sorted(seen_sources - asm_sources)
    for source in missing_from_manifest:
        failures.append(f"manifest coverage: source is not listed: {source}")
    for source in extra_in_manifest:
        failures.append(f"manifest coverage: listed source is not under programs/*.asm: {source}")

    return failures


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
    elif runner == "axi_lite":
        win_script = PROJECT_ROOT / "scripts" / "run-axi-lite.ps1"
        linux_script = "scripts/run-axi-lite.sh"
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
    failures: list[str] = validate_manifest(manifest, manifest_path)
    if failures:
        print("[ASM-CORPUS] manifest validation failed")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    output_dir = PROJECT_ROOT / "sim_build" / "asm_corpus"
    output_dir.mkdir(parents=True, exist_ok=True)

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
