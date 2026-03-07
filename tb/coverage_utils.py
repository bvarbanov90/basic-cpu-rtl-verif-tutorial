from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

from tb.cpu_lib import (
    OPC_ADD,
    OPC_AND,
    OPC_CMP,
    OPC_HLT,
    OPC_JMP,
    OPC_JZ,
    OPC_LDA,
    OPC_LDI,
    OPC_NOP,
    OPC_OR,
    OPC_SHL,
    OPC_SHR,
    OPC_STA,
    OPC_SUB,
    OPC_XOR,
    ReferenceCPU,
)

MAX_VALID_OPCODE = OPC_CMP


@dataclass
class StepObservation:
    opcode: int
    operand: int
    pc_before: int
    pc_after: int
    zero_before: int
    zero_after: int
    carry_after: int
    neg_after: int
    overflow_after: int


def zero_cross_reachable(opcode: int, zero_state: int) -> int:
    return int(opcode <= MAX_VALID_OPCODE and zero_state in (0, 1))


def carry_cross_reachable(opcode: int, carry_state: int) -> int:
    if carry_state not in (0, 1) or opcode > MAX_VALID_OPCODE:
        return 0
    if opcode in (OPC_LDI, OPC_LDA, OPC_AND, OPC_OR, OPC_XOR):
        return int(carry_state == 0)
    return 1


def neg_cross_reachable(opcode: int, neg_state: int) -> int:
    if neg_state not in (0, 1) or opcode > MAX_VALID_OPCODE:
        return 0
    if opcode in (OPC_LDI, OPC_SHR):
        return int(neg_state == 0)
    return 1


def overflow_cross_reachable(opcode: int, overflow_state: int) -> int:
    if overflow_state not in (0, 1) or opcode > MAX_VALID_OPCODE:
        return 0
    if opcode in (OPC_LDI, OPC_LDA, OPC_AND, OPC_OR, OPC_XOR, OPC_SHR):
        return int(overflow_state == 0)
    return 1


class CoverageModel:
    def __init__(self) -> None:
        self.opcode_hit = [0] * (MAX_VALID_OPCODE + 1)
        self.opcode_counts = [0] * (MAX_VALID_OPCODE + 1)
        self.opcode_zero_cross = [[0, 0] for _ in range(MAX_VALID_OPCODE + 1)]
        self.opcode_carry_cross = [[0, 0] for _ in range(MAX_VALID_OPCODE + 1)]
        self.opcode_neg_cross = [[0, 0] for _ in range(MAX_VALID_OPCODE + 1)]
        self.opcode_overflow_cross = [[0, 0] for _ in range(MAX_VALID_OPCODE + 1)]
        self.illegal_opcode_hit = 0
        self.jz_taken = 0
        self.jz_not_taken = 0
        self.zero_transition_00 = 0
        self.zero_transition_01 = 0
        self.zero_transition_10 = 0
        self.zero_transition_11 = 0
        self.carry_0 = 0
        self.carry_1 = 0
        self.neg_0 = 0
        self.neg_1 = 0
        self.overflow_0 = 0
        self.overflow_1 = 0
        self.total_cycles = 0
        self.program_runs = 0

    def sample_step(self, step: StepObservation) -> None:
        opcode = int(step.opcode)
        if 0 <= opcode <= MAX_VALID_OPCODE:
            self.opcode_hit[opcode] = 1
            self.opcode_counts[opcode] += 1
            self.opcode_zero_cross[opcode][int(step.zero_after)] += 1
            self.opcode_carry_cross[opcode][int(step.carry_after)] += 1
            self.opcode_neg_cross[opcode][int(step.neg_after)] += 1
            self.opcode_overflow_cross[opcode][int(step.overflow_after)] += 1
        else:
            self.illegal_opcode_hit = 1

        transition = (int(step.zero_before) << 1) | int(step.zero_after)
        if transition == 0:
            self.zero_transition_00 += 1
        elif transition == 1:
            self.zero_transition_01 += 1
        elif transition == 2:
            self.zero_transition_10 += 1
        elif transition == 3:
            self.zero_transition_11 += 1

        self.carry_1 += int(step.carry_after)
        self.carry_0 += int(not step.carry_after)
        self.neg_1 += int(step.neg_after)
        self.neg_0 += int(not step.neg_after)
        self.overflow_1 += int(step.overflow_after)
        self.overflow_0 += int(not step.overflow_after)

        if opcode == OPC_JZ:
            if step.pc_after == step.operand:
                self.jz_taken += 1
            elif step.pc_after == ((step.pc_before + 1) & 0xF):
                self.jz_not_taken += 1

        self.total_cycles += 1

    def sample_run(self, steps: list[StepObservation]) -> None:
        for step in steps:
            self.sample_step(step)
        self.program_runs += 1

    def to_report(self, random_suite_iterations: int = 0, branch_random_suite_iterations: int = 0) -> dict:
        opcode_hits = {str(opcode): self.opcode_hit[opcode] for opcode in range(MAX_VALID_OPCODE + 1)}
        opcode_counts = {str(opcode): self.opcode_counts[opcode] for opcode in range(MAX_VALID_OPCODE + 1)}
        opcode_zero_cross = {
            str(opcode): {"zero0": self.opcode_zero_cross[opcode][0], "zero1": self.opcode_zero_cross[opcode][1]}
            for opcode in range(MAX_VALID_OPCODE + 1)
        }
        opcode_carry_cross = {
            str(opcode): {"carry0": self.opcode_carry_cross[opcode][0], "carry1": self.opcode_carry_cross[opcode][1]}
            for opcode in range(MAX_VALID_OPCODE + 1)
        }
        opcode_neg_cross = {
            str(opcode): {"neg0": self.opcode_neg_cross[opcode][0], "neg1": self.opcode_neg_cross[opcode][1]}
            for opcode in range(MAX_VALID_OPCODE + 1)
        }
        opcode_overflow_cross = {
            str(opcode): {
                "overflow0": self.opcode_overflow_cross[opcode][0],
                "overflow1": self.opcode_overflow_cross[opcode][1],
            }
            for opcode in range(MAX_VALID_OPCODE + 1)
        }
        opcode_zero_cross_reachability = {
            str(opcode): {"zero0": zero_cross_reachable(opcode, 0), "zero1": zero_cross_reachable(opcode, 1)}
            for opcode in range(MAX_VALID_OPCODE + 1)
        }
        opcode_carry_cross_reachability = {
            str(opcode): {"carry0": carry_cross_reachable(opcode, 0), "carry1": carry_cross_reachable(opcode, 1)}
            for opcode in range(MAX_VALID_OPCODE + 1)
        }
        opcode_neg_cross_reachability = {
            str(opcode): {"neg0": neg_cross_reachable(opcode, 0), "neg1": neg_cross_reachable(opcode, 1)}
            for opcode in range(MAX_VALID_OPCODE + 1)
        }
        opcode_overflow_cross_reachability = {
            str(opcode): {
                "overflow0": overflow_cross_reachable(opcode, 0),
                "overflow1": overflow_cross_reachable(opcode, 1),
            }
            for opcode in range(MAX_VALID_OPCODE + 1)
        }

        failures: list[str] = []
        for opcode in range(MAX_VALID_OPCODE + 1):
            if not self.opcode_hit[opcode]:
                failures.append(f"opcode 0x{opcode:01X} not hit")

        for state in (0, 1):
            if self.opcode_zero_cross[OPC_JZ][state] == 0:
                failures.append(f"JZ x ZERO={state} not observed")
            if self.opcode_carry_cross[OPC_ADD][state] == 0:
                failures.append(f"ADD x CARRY={state} not observed")
            if self.opcode_carry_cross[OPC_SUB][state] == 0:
                failures.append(f"SUB x CARRY={state} not observed")
            if self.opcode_overflow_cross[OPC_SHL][state] == 0:
                failures.append(f"SHL x OVERFLOW={state} not observed")

        if self.opcode_neg_cross[OPC_SUB][1] == 0:
            failures.append("SUB x NEG=1 not observed")
        if self.opcode_neg_cross[OPC_CMP][1] == 0:
            failures.append("CMP x NEG=1 not observed")

        for opcode in range(MAX_VALID_OPCODE + 1):
            for state in (0, 1):
                if not zero_cross_reachable(opcode, state) and self.opcode_zero_cross[opcode][state] != 0:
                    failures.append(
                        f"Impossible ZERO bin observed for opcode 0x{opcode:01X} x ZERO={state}: "
                        f"{self.opcode_zero_cross[opcode][state]}"
                    )
                if not carry_cross_reachable(opcode, state) and self.opcode_carry_cross[opcode][state] != 0:
                    failures.append(
                        f"Impossible CARRY bin observed for opcode 0x{opcode:01X} x CARRY={state}: "
                        f"{self.opcode_carry_cross[opcode][state]}"
                    )
                if not neg_cross_reachable(opcode, state) and self.opcode_neg_cross[opcode][state] != 0:
                    failures.append(
                        f"Impossible NEG bin observed for opcode 0x{opcode:01X} x NEG={state}: "
                        f"{self.opcode_neg_cross[opcode][state]}"
                    )
                if not overflow_cross_reachable(opcode, state) and self.opcode_overflow_cross[opcode][state] != 0:
                    failures.append(
                        f"Impossible OVERFLOW bin observed for opcode 0x{opcode:01X} x OVERFLOW={state}: "
                        f"{self.opcode_overflow_cross[opcode][state]}"
                    )

        if not self.illegal_opcode_hit:
            failures.append("illegal opcode path not hit")
        if self.jz_taken == 0 or self.jz_not_taken == 0:
            failures.append("both JZ taken and not-taken bins were not hit")
        if self.zero_transition_01 == 0 or self.zero_transition_10 == 0:
            failures.append("both ZERO transition bins 01 and 10 were not hit")
        if self.carry_0 == 0 or self.carry_1 == 0:
            failures.append("both CARRY flag bins 0 and 1 were not hit")
        if self.neg_0 == 0 or self.neg_1 == 0:
            failures.append("both NEG flag bins 0 and 1 were not hit")
        if self.overflow_0 == 0 or self.overflow_1 == 0:
            failures.append("both OVERFLOW flag bins 0 and 1 were not hit")
        if self.program_runs < 10:
            failures.append("minimum program run count not reached")

        coverage_pass = int(not failures)

        return {
            "coverage_pass": coverage_pass,
            "coverage_failures": failures,
            "opcode_hit_bitmap": "".join(str(self.opcode_hit[opcode]) for opcode in reversed(range(MAX_VALID_OPCODE + 1))),
            "opcode_hits": opcode_hits,
            "opcode_counts": opcode_counts,
            "opcode_zero_cross": opcode_zero_cross,
            "opcode_zero_cross_reachability": opcode_zero_cross_reachability,
            "opcode_carry_cross": opcode_carry_cross,
            "opcode_carry_cross_reachability": opcode_carry_cross_reachability,
            "opcode_neg_cross": opcode_neg_cross,
            "opcode_neg_cross_reachability": opcode_neg_cross_reachability,
            "opcode_overflow_cross": opcode_overflow_cross,
            "opcode_overflow_cross_reachability": opcode_overflow_cross_reachability,
            "illegal_opcode_hit": self.illegal_opcode_hit,
            "jz_taken": self.jz_taken,
            "jz_not_taken": self.jz_not_taken,
            "zero_transition_00": self.zero_transition_00,
            "zero_transition_01": self.zero_transition_01,
            "zero_transition_10": self.zero_transition_10,
            "zero_transition_11": self.zero_transition_11,
            "carry_0": self.carry_0,
            "carry_1": self.carry_1,
            "neg_0": self.neg_0,
            "neg_1": self.neg_1,
            "overflow_0": self.overflow_0,
            "overflow_1": self.overflow_1,
            "program_runs": self.program_runs,
            "total_cycles": self.total_cycles,
            "random_suite_iterations": random_suite_iterations,
            "branch_random_suite_iterations": branch_random_suite_iterations,
            "coverage_goals": {
                "opcode_coverage": 1,
                "illegal_opcode_hit": 1,
                "jz_taken": 1,
                "jz_not_taken": 1,
                "zero_transition_01": 1,
                "zero_transition_10": 1,
                "carry_0": 1,
                "carry_1": 1,
                "neg_0": 1,
                "neg_1": 1,
                "overflow_0": 1,
                "overflow_1": 1,
                "jz_x_zero0": 1,
                "jz_x_zero1": 1,
                "add_x_carry0": 1,
                "add_x_carry1": 1,
                "sub_x_carry0": 1,
                "sub_x_carry1": 1,
                "sub_x_neg1": 1,
                "cmp_x_neg1": 1,
                "shl_x_overflow0": 1,
                "shl_x_overflow1": 1,
                "reachability_annotations": 1,
                "min_program_runs": 10,
            },
        }

    def write_report(self, path: str | Path, random_suite_iterations: int = 0, branch_random_suite_iterations: int = 0) -> None:
        report = self.to_report(
            random_suite_iterations=random_suite_iterations,
            branch_random_suite_iterations=branch_random_suite_iterations,
        )
        out_path = Path(path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


def trace_program(program: list[int], max_cycles: int = 128) -> tuple[list[StepObservation], ReferenceCPU]:
    model = ReferenceCPU()
    model.load_program(program)
    steps: list[StepObservation] = []

    for _ in range(max_cycles):
        if model.halted:
            break
        pc_before = model.pc
        zero_before = model.zero
        instr = model.imem[pc_before]
        opcode = (instr >> 4) & 0xF
        operand = instr & 0xF
        model.step()
        steps.append(
            StepObservation(
                opcode=opcode,
                operand=operand,
                pc_before=pc_before,
                pc_after=model.pc,
                zero_before=zero_before,
                zero_after=model.zero,
                carry_after=model.carry,
                neg_after=model.neg,
                overflow_after=model.overflow,
            )
        )
    else:
        raise AssertionError("Reference model did not halt in time")

    return steps, model


def coverage_from_program(program: list[int], max_cycles: int = 128) -> dict:
    steps, _ = trace_program(program, max_cycles=max_cycles)
    coverage = CoverageModel()
    coverage.sample_run(steps)
    return coverage.to_report(random_suite_iterations=1, branch_random_suite_iterations=0)


def final_state_dict(program: list[int], max_cycles: int = 128) -> dict:
    _, model = trace_program(program, max_cycles=max_cycles)
    return asdict(model.final_state())
