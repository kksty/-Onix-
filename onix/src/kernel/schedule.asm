global task_switch
task_switch:
    push ebp
    mov ebp, esp

    push ebx
    push esi
    push edi

    mov eax, esp; 将当前栈顶地址存储到 eax 寄存器中
    and eax, 0xfffff000; 将 eax 寄存器的值按位与上 0xfffff000，得到页对齐地址 current

    mov [eax], esp; 将当前栈顶地址保存到以页对齐地址为基址的内存位置中

    mov eax, [ebp + 8]; next
    mov esp, [eax]

    pop edi
    pop esi
    pop ebx
    pop ebp

ret
