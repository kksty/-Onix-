[org 0x7c00]  

; 设置屏幕模式，清除屏幕
mov ax,3 ;设置为80x25的文本模式。
int 0x10 

; 初始化段寄存器
mov ax,0
mov ds,ax
mov es,ax
mov ss,ax
mov sp,0x7c00

xchg bx,bx ;bochs魔术断点

mov si, booting
call printf

; 阻塞
jmp $

printf:
    mov ah,0x0e ; BIOS中断0x10用于打印字符的功能码。
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next

.done:
    ret

booting:
    db "Booting Onix...", 10, 13, 0

; 末尾填充0
times 510 - ($ - $$) db 0

; 最后两个字节必须是0x55,0xaa   
; dw 0xaa55
db 0x55,0xaa
