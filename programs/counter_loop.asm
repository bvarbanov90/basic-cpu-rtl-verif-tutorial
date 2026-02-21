; Count down from 3 to 0 using SUB/JZ/JMP.

    LDI #3
    STA 0
    LDI #1
    STA 1

loop:
    LDA 0
    SUB 1
    STA 0
    JZ done
    JMP loop

done:
    HLT
