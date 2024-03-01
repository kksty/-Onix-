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

mov edi, 0x1000 ;读取的目标内存
mov ecx, 0 ;起始扇区
mov bl, 1 ;读取的扇区数量
call read_disk

; 阻塞
jmp $

read_disk:
    ; 设置读写扇区的数量
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx ;移动到0x1f3
    mov al, cl; 起始扇区的前八位
    out dx, al

    inc dx ;移动到0x1f4
    shr ecx, 8
    mov al, cl; 起始扇区的中八位
    out dx, al

    inc dx ;移动到0x1f5
    shr ecx, 8
    mov al, cl; 起始扇区的高八位
    out dx, al

    inc dx;0x1f6
    shr ecx, 8 
    and cl, 0b1111 ;将高四位置为0
    
    mov al, 0b1110_0000 
    or al, cl
    out dx, al

    

    ret
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
