from __future__ import annotations

from dataclasses import asdict

import pytest

from scripts.asm import OPCODES
from tb.cpu_lib import (
    MEM_SIZE,
    OPC_ADD,
    OPC_HLT,
    OPC_JZ,
    OPC_LDI,
    OPC_SHL,
    OPC_STA,
    OPCODE_NAMES,
    OPCODES_WITH_DMEM_READ,
    OPCODES_WITH_DMEM_WRITE,
    OPCODES_WITH_OPERANDS,
    ReferenceCPU,
    build_add_carry_program,
    build_branch_stress_program,
    build_cmp_negative_program,
    build_illegal_opcode_program,
    build_jump_loop_program,
    build_logic_ops_program,
    build_random_dataflow_program,
    build_shift_overflow_program,
    build_smoke_program,
    build_sub_carry_program,
    decode_instruction,
    disassemble_instruction,
    disassemble_program,
    ins,
    opcode_name,
)


def test_assembler_opcode_table_matches_reference_model_metadata() -> None:
    asm_by_opcode = {opcode: (mnemonic, mode) for mnemonic, (opcode, mode) in OPCODES.items()}

    assert set(asm_by_opcode) == set(OPCODE_NAMES)
    for opcode, mnemonic in OPCODE_NAMES.items():
        asm_mnemonic, asm_mode = asm_by_opcode[opcode]
        assert asm_mnemonic == mnemonic
        assert (asm_mode == "nibble") == (opcode in OPCODES_WITH_OPERANDS)
        assert not (opcode in OPCODES_WITH_DMEM_READ and opcode in OPCODES_WITH_DMEM_WRITE)


def run_program(program: list[int], max_cycles: int = 128) -> tuple[ReferenceCPU, list]:
    model = ReferenceCPU()
    model.load_program(program)
    trace = model.trace_run(max_cycles=max_cycles)
    return model, trace


@pytest.mark.parametrize(
    ("word", "expected"),
    [
        (ins(OPC_LDI, 3), "0: LDI 0x3"),
        (ins(OPC_STA, 0), "0: STA 0x0"),
        (ins(OPC_SHL, 7), "0: SHL"),
        (ins(OPC_HLT, 4), "0: HLT"),
        (0xF2, "0: .BYTE 0xF2 ; illegal opcode 0xF"),
    ],
)
def test_disassemble_instruction(word: int, expected: str) -> None:
    assert disassemble_instruction(word, address=0) == expected


def test_opcode_decode_helpers_cover_valid_and_illegal_words() -> None:
    opcode, operand = decode_instruction(ins(OPC_ADD, 5))
    assert opcode == OPC_ADD
    assert operand == 5
    assert opcode_name(OPC_JZ) == "JZ"
    assert opcode_name(0xF) == "OPF"


def test_smoke_trace_exposes_taken_branch_and_final_state() -> None:
    model, trace = run_program(build_smoke_program(), max_cycles=96)

    assert trace[-1].mnemonic == "HLT"
    assert trace[-1].halted_after == 1
    assert any(step.opcode == OPC_JZ and step.pc_after == step.operand for step in trace)
    assert model.acc == 0
    assert model.pc == 8
    assert model.dmem[0] == 3
    assert model.dmem[1] == 7
    assert asdict(model.final_state())["halted"] == 1


@pytest.mark.parametrize(
    ("name", "program", "max_cycles"),
    [
        ("logic", build_logic_ops_program(), 128),
        ("loop", build_jump_loop_program(), 128),
        ("branch", build_branch_stress_program(seed=0xBADC0DE0), 128),
        ("random", build_random_dataflow_program(seed=20260221, length=12), 128),
        ("add_carry", build_add_carry_program(), 96),
        ("sub_carry", build_sub_carry_program(), 96),
        ("shift_overflow", build_shift_overflow_program(), 96),
        ("cmp_negative", build_cmp_negative_program(), 64),
    ],
)
def test_program_builders_emit_halting_programs(name: str, program: list[int], max_cycles: int) -> None:
    assert len(program) <= MEM_SIZE, name
    model, trace = run_program(program, max_cycles=max_cycles)
    assert model.halted == 1, name
    assert trace, name
    assert trace[-1].mnemonic == "HLT", name


def test_illegal_opcode_halts_without_advancing_pc() -> None:
    model, trace = run_program(build_illegal_opcode_program(), max_cycles=4)

    assert len(trace) == 1
    assert trace[0].mnemonic == "OPF"
    assert trace[0].pc_before == 0
    assert trace[0].pc_after == 0
    assert model.halted == 1


def test_trace_records_memory_side_effects() -> None:
    model, trace = run_program([ins(OPC_LDI, 9), ins(OPC_STA, 2), ins(OPC_HLT, 0)], max_cycles=8)

    store_step = next(step for step in trace if step.opcode == OPC_STA)
    assert store_step.dmem_addr == 2
    assert store_step.dmem_before == 0
    assert store_step.dmem_after == 9
    assert model.dmem[2] == 9


def test_trace_records_flag_closure_examples() -> None:
    _, add_trace = run_program(build_add_carry_program(), max_cycles=96)
    _, shift_trace = run_program(build_shift_overflow_program(), max_cycles=96)
    _, cmp_trace = run_program(build_cmp_negative_program(), max_cycles=64)

    assert any(step.carry_after == 1 for step in add_trace)
    assert any(step.overflow_after == 1 for step in shift_trace)
    assert any(step.neg_after == 1 for step in cmp_trace)


def test_disassemble_program_limits_to_instruction_memory_size() -> None:
    program = [ins(OPC_HLT, 0)] * (MEM_SIZE + 4)
    listing = disassemble_program(program)

    assert len(listing) == MEM_SIZE
    assert listing[0] == "0: HLT"
    assert listing[-1] == "F: HLT"
