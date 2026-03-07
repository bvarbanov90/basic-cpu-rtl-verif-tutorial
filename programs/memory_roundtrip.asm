; Basic store/load roundtrip through data memory.

    LDI #6
    STA 0
    LDA 0
    STA 1
    HLT
