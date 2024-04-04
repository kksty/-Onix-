[bits 32]

section .text

global inb ;导出inb
inb:
    push    ebp
    mov ebp, esp

    xor eax,eax
    mov edx,[ebp + 8] ; port
    in al,dx ;将端口号 dx 的 8 bit 输入到 ax

    jmp $+2
    jmp $+2
    jmp $+2

    leave ;恢复栈帧
    ret

global outb
outb:
    push    ebp
    mov ebp, esp

    mov edx,[ebp + 8] ; port
    mov eax,[ebp + 12] ;value
    out dx,al ;将al中的 8 bit 输出到端口号 dx

    jmp $+2
    jmp $+2
    jmp $+2

    leave ;恢复栈帧
    ret

global inw ;导出inb
inw:
    push    ebp
    mov ebp, esp

    xor eax,eax
    mov edx,[ebp + 8] ; port
    in ax,dx ;将端口号 dx 的 8 bit 输入到 ax

    jmp $+2
    jmp $+2
    jmp $+2

    leave ;恢复栈帧
    ret

global outw
outw:
    push    ebp
    mov ebp, esp

    mov edx,[ebp + 8] ; port
    mov eax,[ebp + 12] ;value
    out dx,ax ;将ax 中的 8 bit 输出到端口号 dx

    jmp $+2
    jmp $+2
    jmp $+2

    leave ;恢复栈帧
    ret

; global inb ;导出inb
; inb:
;     push	ebp 
;     mov	    ebp, esp

;     leave ;恢复栈帧

;     ret 