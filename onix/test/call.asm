[bits 32]

extern exit
global main
main:
    push 5
    push eax

    pop ebx
    pop ecx
    call exit