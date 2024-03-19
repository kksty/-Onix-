[org 0x1000]

dw 0x55aa


; 打印字符串
mov si,loading
call print

; xchg bx,bx; 断点

detecting_memory:
    xor ebx,ebx ;清空ebx
    ; es:di结构体的缓存位置
    mov ax, 0
    mov es, ax
    mov edi,ards_buffer ;存储结构体的内存位置

    mov edx, 0x534d4150 ;固定签名
.next:
    mov eax,0xe820 ;子功能号
    mov ecx,20 ;ards 结构的大小 (字节)
    int 0x15 ;调用 0x15 系统调用

    jc error ;如果cf置位,表示出错
    add di, cx ;缓存指针指向下一个结构体

    inc word[ards_cout]; 结构体数量+1
    cmp ebx,0
    jnz .next

    mov si, detecting
    call print

    ; xchg bx,bx
    ; mov byte [0xb8000], 'H'

    jmp prepare_protected_mode

prepare_protected_mode:

    ; xchg bx,bx

    cli;关闭中断

    ;打开A20总线
    in al,0x92
    or al,0b10
    out 0x92,al

    ;加载gdt
    lgdt[gdt_ptr] ;加载gdt

    ;启动保护模式
    mov eax, cr0
    or eax,1
    mov cr0,eax

    ;跳转刷新缓存,启用保护模式
    jmp dword code_selector:protect_mode

print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret

loading:
    db "Loading Onix...", 10, 13, 0 
detecting:
    db "Detecting Memory Success!", 10, 13, 0
error:
    mov si, .msg
    call print
    hlt ;停止cpu
    jmp $
    .msg db"Loading error!", 10, 13, 0  

[bits 32]
protect_mode:
    xchg bx,bx ;中断
    mov ax,data_selector ;将代码段之外的数据全部写为数据段
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax ;初始化段寄存器

    mov esp, 0x10000 ;修改栈顶

    mov edi, 0x10000 ;读取的目标内存
    mov ecx, 10 ;起始扇区
    mov bl, 200 ;读取的扇区数量

    call read_disk

    jmp dword code_selector:0x10000

    ud2 ;表示出错


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


code_selector equ (1 << 3 ) 
data_selector equ (2 << 3 ) 


memory_base equ 0 ;内存开始的位置->基地址
memory_limit equ ((1024 * 1024 * 1024 * 4) / (1024 * 4)) - 1 ;内存界限4G/4K - 1

gdt_ptr:
    dw (gdt_end - gdt_base) - 1
    dd gdt_base
gdt_base:
    dd 0,0 ;NULL描述符   
gdt_code:
    dw  memory_limit & 0xffff ;段界限的 0 ～ 15 位
    dw memory_base & 0xffff; 基地址 0 ~ 15 位
    db  (memory_base >> 16) & 0xff  
    db 0b_1_00_1_1_0_1_0   ; 代码_非依从_可读_没有被访问过 
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf ;4k_32位_不是64位_送给操作系统了
    db (memory_base >> 24) & 0xff ;基地址24-31位

gdt_data: 
    dw  memory_limit & 0xffff ;段界限的 0 ～ 15 位
    dw memory_base & 0xffff; 基地址 0 ~ 15 位
    db  (memory_base >> 16) & 0xff  
    db 0b_1_00_1_0_0_1_0   ; 数据_向上_可写_没有被访问过 
    db 0b1_1_0_0_0000 | (memory_limit >> 16) & 0xf ;4k_32位_不是64位_送给操作系统了
    db (memory_base >> 24) & 0xff ;基地址24-31位
gdt_end:
ards_cout:
    dw 0
ards_buffer:

