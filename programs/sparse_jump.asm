; Use .org and a forward label to test sparse image assembly.

    JMP start

    .org 8
start:
    LDI #5
    STA 0
    HLT
