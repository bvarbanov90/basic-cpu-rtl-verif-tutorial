; Force a taken JZ path and store the skipped value.

    LDI #0
    JZ taken
    LDI #15

taken:
    STA 0
    HLT
