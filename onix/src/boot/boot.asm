[org 0x7c00]  

; 设置屏幕模式，清除屏幕
mov ax,3 ;设置为80x25的文本模式。
int 0x10 ; BIOS中断0x10用于打印字符的功能码。

; 初始化段寄存器
mov ax,0
mov ds,ax
mov es,ax
mov ss,ax
mov sp,0x7c00


mov si, booting
call print

mov edi, 0x1000 ;读取的目标内存
mov ecx, 2 ;起始扇区
mov bl, 4 ;读取的扇区数量
call read_disk

cmp word[0x1000], 0x55aa
jnz error

jmp 0:0x1002
;阻塞
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
    out dx, al;主盘LBA模式

    inc dx ;0x1f7
    mov al, 0x20;读硬盘
    out dx, al

    xor ecx, ecx ;清空ecx
    mov cl, bl ;得到读写扇区的数量

    .read:
        push cx ;保存cx
        call .waits ;等待
        call .reads ;读取一个扇区
        pop cx       
        loop .read

    ret

    .waits:
        mov dx, 0x1f7
        .check: ;检查是否准备完毕
            in al, dx
            jmp $+2;跳转到下一行
            jmp $+2
            jmp $+2
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret
    .reads:
        mov dx, 0x1f0
        mov cx, 256;一个扇区256个字
        .readw: 
            in ax, dx
            jmp $+2
            jmp $+2
            jmp $+2
            mov [edi], ax
            add edi, 2
            loop .readw
        ret   

print:
    mov ah,0x0e 
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

error:
    mov si, .msg
    call print
    hlt ;停止cpu
    jmp $
    .msg db"Booting error!", 10, 13, 0

; 末尾填充0
times 510 - ($ - $$) db 0

; 最后两个字节必须是0x55,0xaa   
; dw 0xaa55
db 0x55,0xaa
