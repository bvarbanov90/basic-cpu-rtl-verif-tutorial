import argparse
import pathlib
from dataclasses import dataclass

MEM_SIZE = 16

OPCODES = {
    "NOP": (0x0, "none"),
    "LDI": (0x1, "nibble"),
    "ADD": (0x2, "nibble"),
    "SUB": (0x3, "nibble"),
    "STA": (0x4, "nibble"),
    "LDA": (0x5, "nibble"),
    "JMP": (0x6, "nibble"),
    "JZ": (0x7, "nibble"),
    "HLT": (0x8, "none"),
    "AND": (0x9, "nibble"),
    "OR": (0xA, "nibble"),
    "XOR": (0xB, "nibble"),
    "SHL": (0xC, "none"),
    "SHR": (0xD, "none"),
    "CMP": (0xE, "nibble"),
}


@dataclass
class Stmt:
    kind: str
    args: list[str]
    line_no: int


def clean_line(line: str) -> str:
    # ';' starts comment. '#' is allowed for immediates (e.g. LDI #3).
    if ";" in line:
        line = line.split(";", 1)[0]
    return line.strip()


def parse_value(token: str, labels: dict[str, int], line_no: int) -> int:
    tok = token.strip()
    if tok.startswith("#"):
        tok = tok[1:]

    if tok in labels:
        return labels[tok]

    try:
        return int(tok, 0)
    except ValueError as exc:
        raise ValueError(f"Line {line_no}: invalid value '{token}'") from exc


def parse_source(text: str) -> tuple[list[Stmt], dict[str, int]]:
    stmts: list[Stmt] = []
    labels: dict[str, int] = {}
    pc = 0

    for line_no, raw in enumerate(text.splitlines(), start=1):
        line = clean_line(raw)
        if not line:
            continue

        if ":" in line:
            label, rest = line.split(":", 1)
            label = label.strip()
            if not label:
                raise ValueError(f"Line {line_no}: empty label")
            if label in labels:
                raise ValueError(f"Line {line_no}: duplicate label '{label}'")
            labels[label] = pc
            line = rest.strip()
            if not line:
                continue

        line = line.replace(",", " ")
        parts = [p for p in line.split() if p]
        head = parts[0].upper()
        args = parts[1:]

        if head == ".ORG":
            if len(args) != 1:
                raise ValueError(f"Line {line_no}: .org requires one argument")
            stmts.append(Stmt("org", args, line_no))
            try:
                pc = int(args[0], 0)
            except ValueError as exc:
                raise ValueError(f"Line {line_no}: invalid .org value '{args[0]}'") from exc
            if not (0 <= pc < MEM_SIZE):
                raise ValueError(f"Line {line_no}: .org out of range (0..{MEM_SIZE - 1})")
        elif head == ".BYTE":
            if len(args) != 1:
                raise ValueError(f"Line {line_no}: .byte requires one argument")
            stmts.append(Stmt("byte", args, line_no))
            pc += 1
        else:
            if head not in OPCODES:
                raise ValueError(f"Line {line_no}: unknown instruction '{head}'")
            mode = OPCODES[head][1]
            if mode == "none" and len(args) != 0:
                raise ValueError(f"Line {line_no}: instruction '{head}' takes no operand")
            if mode == "nibble" and len(args) != 1:
                raise ValueError(f"Line {line_no}: instruction '{head}' requires one operand")
            stmts.append(Stmt("ins", [head] + args, line_no))
            pc += 1

        if pc > MEM_SIZE:
            raise ValueError(f"Line {line_no}: program exceeds {MEM_SIZE} bytes")

    return stmts, labels


def assemble(stmts: list[Stmt], labels: dict[str, int]) -> list[int]:
    mem = [0x00] * MEM_SIZE
    pc = 0

    for stmt in stmts:
        if stmt.kind == "org":
            pc = parse_value(stmt.args[0], labels, stmt.line_no)
            if not (0 <= pc < MEM_SIZE):
                raise ValueError(f"Line {stmt.line_no}: .org out of range")
        elif stmt.kind == "byte":
            val = parse_value(stmt.args[0], labels, stmt.line_no)
            if not (0 <= val <= 0xFF):
                raise ValueError(f"Line {stmt.line_no}: .byte value out of range (0..255)")
            if pc >= MEM_SIZE:
                raise ValueError(f"Line {stmt.line_no}: write out of memory range")
            mem[pc] = val
            pc += 1
        elif stmt.kind == "ins":
            mnemonic = stmt.args[0]
            opcode, mode = OPCODES[mnemonic]
            if mode == "none":
                operand = 0
            else:
                operand = parse_value(stmt.args[1], labels, stmt.line_no)
                if not (0 <= operand <= 0xF):
                    raise ValueError(f"Line {stmt.line_no}: operand out of range (0..15)")
            if pc >= MEM_SIZE:
                raise ValueError(f"Line {stmt.line_no}: write out of memory range")
            mem[pc] = ((opcode & 0xF) << 4) | (operand & 0xF)
            pc += 1
        else:
            raise ValueError(f"Line {stmt.line_no}: internal error, unknown stmt type")

    return mem


def main() -> None:
    parser = argparse.ArgumentParser(description="Assembler for the basic CPU tutorial ISA")
    parser.add_argument("source", type=pathlib.Path, help="Input .asm file")
    parser.add_argument("-o", "--output", type=pathlib.Path, required=True, help="Output .hex file")
    parser.add_argument("--list", action="store_true", help="Print assembled bytes")
    args = parser.parse_args()

    src = args.source.read_text(encoding="utf-8")
    stmts, labels = parse_source(src)
    mem = assemble(stmts, labels)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(f"{b:02X}" for b in mem) + "\n", encoding="utf-8")

    if args.list:
        print("Address  Byte")
        for addr, value in enumerate(mem):
            print(f"{addr:02X}       {value:02X}")


if __name__ == "__main__":
    main()
