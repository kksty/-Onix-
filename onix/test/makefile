CFLAGS:= -m32 #32位程序
#CFLAGS+= -fno-builtin #不需要gcc的内置函数 如memcpy
#CFLAGS+= -nostdinc #不需要标准头文件
CFLAGS+= -fno-pic #不需要位置无关的代码
#CFLAGS+= -fno-pie #不需要位置无关的可执行程序
#CFLAGS+= -nostdlib #不需要标准库
#CFLAGS+= -fno-stack-protector #不需要栈保护
CFLAGS+= -fno-asynchronous-unwind-tables #可去除调试信息
CFLAGS+= -Qn #去除版本信息
CFLAGS+= -mpreferred-stack-boundary=2 #去掉栈对齐
#CFLAGS+= -fomit-frame-pointer #去掉栈帧
CFLAGS:= $(strip ${CFLAGS})

.PHNOY: hello.s
hello.s: hello.c
	gcc $(CFLAGS) -S  $< -o $@

.PHNOY: params.s
params.s: params.c
	gcc $(CFLAGS) -S  $< -o $@