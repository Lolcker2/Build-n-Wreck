:tasm.exe /zi /m2 base.asm
:tlink.exe /v base.obj

tasm.exe /zi /m2 BNW.asm
tlink.exe /v BNW.obj
cycles=10000
