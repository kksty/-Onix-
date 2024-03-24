BUILD:=../build
SRC:=.

#指定入口地址，内核开始执行的位置
ENTRYPOINT:=0X10000

CFLAGS:= -m32 #32位程序
CFLAGS+= -fno-builtin #不需要gcc的内置函数 如memcpy
CFLAGS+= -nostdinc #不需要标准头文件
CFLAGS+= -fno-pic #不需要位置无关的代码
CFLAGS+= -fno-pie #不需要位置无关的可执行程序
CFLAGS+= -nostdlib #不需要标准库
CFLAGS+= -fno-stack-protector #不需要栈保护
CFLAGS:= $(strip ${CFLAGS})



DEBUG:= -g
INCLUDE:= -I$(SRC)/include

#模式规则，符合规则的都以这种模式来编译
$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@

$(BUILD)/kernel/%.o: $(SRC)/kernel/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f elf32 $(DEBUG) $< -o $@

$(BUILD)/kernel/%.o: $(SRC)/kernel/%.c
	$(shell mkdir -p $(dir $@))
	gcc $(CFLAGS) $(DEBUG) $(INCLUDE) -c $< -o $@

$(BUILD)/kernel.bin: $(BUILD)/kernel/start.o \
	$(BUILD)/kernel/main.o
	$(shell mkdir -p $(dir $@))
	ld -m elf_i386 -static $^ -o $@ -Ttext $(ENTRYPOINT)

$(BUILD)/system.bin: $(BUILD)/kernel.bin
	objcopy -O binary $< $@

$(BUILD)/system.map: $(BUILD)/kernel.bin
	nm $< | sort > $@
 
$(BUILD)/master.img: $(BUILD)/boot/boot.bin \
	$(BUILD)/boot/loader.bin \
	$(BUILD)/system.bin \
	$(BUILD)/system.map \

	yes|bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $@
	dd if=$(BUILD)/boot/boot.bin of=$@ bs=512 count=1 conv=notrunc 
#从第二个扇区开始写，写四个扇区
	dd if=$(BUILD)/boot/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc 
	dd if=$(BUILD)/system.bin of=$@ bs=512 count=200 seek=10 conv=notrunc 

test: $(BUILD)/master.img

.PHNOY: clean
clean:
	rm -rf $(BUILD)

.PHNOY: bochs
bochs: $(BUILD)/master.img
	bochs -q -f ../bochs/bochsrc

.PHNOY: bochsg
bochsg: $(BUILD)/master.img
	bochs-gdb-a20 -q -f ../bochs/bochsrc.gdb

