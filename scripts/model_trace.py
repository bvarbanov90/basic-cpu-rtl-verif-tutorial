from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.asm import assemble, parse_source
from tb.cpu_lib import (
    MEM_SIZE,
    ReferenceCPU,
    build_branch_stress_program,
    build_illegal_opcode_program,
    build_jump_loop_program,
    build_logic_ops_program,
    build_random_dataflow_program,
    build_smoke_program,
    disassemble_program,
)


def parse_hex_bytes(tokens: list[str]) -> list[int]:
    words: list[int] = []
    for token in tokens:
        for part in token.replace(",", " ").split():
            value = int(part, 0)
            if not (0 <= value <= 0xFF):
                raise ValueError(f"program byte out of range: {part}")
            words.append(value)
    if len(words) > MEM_SIZE:
        raise ValueError(f"program has {len(words)} bytes, but instruction memory has {MEM_SIZE}")
    return words


def builtin_program(name: str, seed: int) -> list[int]:
    if name == "smoke":
        return build_smoke_program()
    if name == "logic":
        return build_logic_ops_program()
    if name == "loop":
        return build_jump_loop_program()
    if name == "branch":
        return build_branch_stress_program(seed=seed)
    if name == "random":
        return build_random_dataflow_program(seed=seed, length=12)
    if name == "illegal":
        return build_illegal_opcode_program()
    raise ValueError(f"unknown built-in program: {name}")


def pad_program(program: list[int]) -> list[int]:
    return (program + [0x00] * MEM_SIZE)[:MEM_SIZE]


def load_program(args: argparse.Namespace) -> list[int]:
    if args.asm is not None:
        stmts, labels = parse_source(args.asm.read_text(encoding="utf-8"))
        return assemble(stmts, labels)
    if args.bytes:
        return pad_program(parse_hex_bytes(args.bytes))
    if args.builtin:
        return pad_program(builtin_program(args.builtin, seed=args.seed))
    raise ValueError("select --builtin, --asm, or --bytes")


def build_payload(program: list[int], max_cycles: int) -> dict:
    model = ReferenceCPU()
    model.load_program(program)
    trace = model.trace_run(max_cycles=max_cycles)
    return {
        "program": [f"0x{word:02X}" for word in program],
        "disassembly": disassemble_program(program),
        "trace": [asdict(step) for step in trace],
        "final_state": asdict(model.final_state()),
    }


def render_table(payload: dict) -> str:
    lines: list[str] = []
    lines.append("Disassembly")
    lines.extend(f"  {line}" for line in payload["disassembly"])
    lines.append("")
    lines.append("Execution Trace")
    for step_dict in payload["trace"]:
        flags_before = (
            f"Z{step_dict['zero_before']} C{step_dict['carry_before']} "
            f"N{step_dict['neg_before']} V{step_dict['overflow_before']}"
        )
        flags_after = (
            f"Z{step_dict['zero_after']} C{step_dict['carry_after']} "
            f"N{step_dict['neg_after']} V{step_dict['overflow_after']}"
        )
        if step_dict["dmem_addr"] is None:
            mem = "-"
        else:
            mem = f"[{step_dict['dmem_addr']:X}] {step_dict['dmem_before']:02X}->{step_dict['dmem_after']:02X}"
        lines.append(
            f"  {step_dict['cycle']:02d} "
            f"PC {step_dict['pc_before']:X}->{step_dict['pc_after']:X} "
            f"{step_dict['instr']:02X} {step_dict['mnemonic']:<3} {step_dict['operand']:X} "
            f"ACC {step_dict['acc_before']:02X}->{step_dict['acc_after']:02X} "
            f"{flags_before}->{flags_after} "
            f"H{step_dict['halted_before']}->{step_dict['halted_after']} "
            f"MEM {mem}"
        )
    lines.append("")
    final = payload["final_state"]
    lines.append(
        "Final State: "
        f"ACC=0x{final['acc']:02X} PC=0x{final['pc']:X} "
        f"Z={final['zero']} C={final['carry']} N={final['neg']} V={final['overflow']} "
        f"HALTED={final['halted']}"
    )
    lines.append("DMEM: " + " ".join(f"{value:02X}" for value in final["dmem"]))
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Disassemble and trace the basic CPU Python reference model.")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--builtin",
        choices=["smoke", "logic", "loop", "branch", "random", "illegal"],
        help="Trace one of the tutorial built-in programs.",
    )
    source.add_argument("--asm", type=Path, help="Trace an assembly source file.")
    source.add_argument("--bytes", nargs="+", help="Trace raw program bytes, e.g. --bytes 0x13 0x40 0x80.")
    parser.add_argument("--seed", type=int, default=0xBADC0DE0, help="Seed for randomized built-in programs.")
    parser.add_argument("--max-cycles", type=int, default=128, help="Reference-model timeout.")
    parser.add_argument("--format", choices=["table", "json"], default="table", help="Output format.")
    parser.add_argument("--output", type=Path, help="Optional output path. Defaults to stdout.")
    args = parser.parse_args()

    program = load_program(args)
    payload = build_payload(program, max_cycles=args.max_cycles)
    if args.format == "json":
        text = json.dumps(payload, indent=2) + "\n"
    else:
        text = render_table(payload)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(text, encoding="utf-8")
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
