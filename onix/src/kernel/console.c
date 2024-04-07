#include <onix/console.h>
#include <onix/io.h>
#include <onix/types.h>
#include <onix/string.h>

#define CRT_ADDR_REG 0x3D4 // CRT(6845)索引寄存器
#define CRT_DATA_REG 0x3D5 // CRT(6845)数据寄存器

#define CRT_START_ADDR_H 0xC // 显示内存起始位置 - 高位
#define CRT_START_ADDR_L 0xD // 显示内存起始位置 - 低位
#define CRT_CURSOR_H 0xE     // 光标位置 - 高位
#define CRT_CURSOR_L 0xF     // 光标位置 - 低位

#define MEM_BASE 0xB8000              // 显卡内存起始位置
#define MEM_SIZE 0x4000               // 显卡内存大小
#define MEM_END (MEM_BASE + MEM_SIZE) // 显卡内存结束位置
#define WIDTH 80                      // 屏幕文本列数
#define HEIGHT 25                     // 屏幕文本行数
#define ROW_SIZE (WIDTH * 2)          // 每行字节数
#define SCR_SIZE (ROW_SIZE * HEIGHT)  // 屏幕字节数

#define NUL 0x00
#define ENQ 0x05
#define ESC 0x1B // ESC
#define BEL 0x07 // \a
#define BS 0x08  // \b
#define HT 0x09  // \t
#define LF 0x0A  // \n
#define VT 0x0B  // \v
#define FF 0x0C  // \f
#define CR 0x0D  // \r
#define DEL 0x7F

static u32 screen;       // 当前显示器开始的内存位置
static u32 pos;          // 记录当前光标的内存位置
static u32 x, y;         // 当前光标的坐标
static u8 attr = 7;      // 字符样式
static u16 erase = 0x07; // 空格

// 获得当前显示器的开始位置
static void get_screen()
{
    outb(CRT_ADDR_REG, CRT_START_ADDR_H); // 开始位置高地址
    screen = inb(CRT_DATA_REG) << 8;      // 开始位置高八位
    outb(CRT_ADDR_REG, CRT_START_ADDR_L);
    screen |= inb(CRT_DATA_REG);
    screen <<= 1; // screen *= 2
    screen += MEM_BASE;
}
// 设置当前显示器的开始位置
static void set_screen()
{
    outb(CRT_ADDR_REG, CRT_START_ADDR_H);
    outb(CRT_DATA_REG, ((screen - MEM_BASE) >> 9) & 0xff);
    outb(CRT_ADDR_REG, CRT_START_ADDR_L);
    outb(CRT_DATA_REG, ((screen - MEM_BASE) >> 1) & 0xff);
}

// 获得当前光标位置
static void get_cursor()
{
    outb(CRT_ADDR_REG, CRT_CURSOR_H); // 高地址
    pos = inb(CRT_DATA_REG) << 8;     // 高八位
    outb(CRT_ADDR_REG, CRT_CURSOR_L);
    pos |= inb(CRT_DATA_REG);

    get_screen();

    pos <<= 1; // pos * 2
    pos += MEM_BASE;
    u32 delta = (pos - screen) >> 1; // 光标的相对位置
    x = delta % WIDTH;
    y = delta / WIDTH;
}

// 设置当前光标位置
static void set_cursor()
{
    outb(CRT_ADDR_REG, CRT_CURSOR_H); // 光标高地址
    outb(CRT_DATA_REG, ((pos - MEM_BASE) >> 9) & 0xff);
    outb(CRT_ADDR_REG, CRT_CURSOR_L); // 光标低地址
    outb(CRT_DATA_REG, ((pos - MEM_BASE) >> 1) & 0xff);
}

// 清除屏幕
void console_clear()
{
    screen = MEM_BASE;
    pos = MEM_BASE;
    x = y = 0;
    set_cursor();
    set_screen();
    u16 *ptr = (u16 *)MEM_BASE;
    while (ptr < (u16 *)MEM_END)
    {
        *ptr++ = erase;
    }
}

static void command_bs()
{
    if (x)
    {
        x--;
        pos -= 2;
        *(u16 *)pos = erase;
    }
}

static void command_del()
{
    *(u16 *)pos = erase;
}

static void command_cr()
{
    pos -= (x << 1);
    x = 0;
}

// 向上滚屏
static void scroll_up()
{
    // 判断是否超过内存区域
    if (screen + SCR_SIZE + ROW_SIZE < MEM_END)
    {
        u32 *ptr = (u32 *)(screen + SCR_SIZE);
        for (size_t i = 0; i < WIDTH; i++)
        {
            *ptr++ = erase;
        }
        screen += ROW_SIZE;
        pos += ROW_SIZE;
    }
    else
    {
        memcpy((void *)MEM_BASE, (void *)screen, SCR_SIZE);
        pos -= (screen - MEM_BASE);
        screen = MEM_BASE;
    }
    set_screen();
}

static void command_lf()
{
    if (y + 1 < HEIGHT)
    {
        y++;
        pos += ROW_SIZE;
        return;
    }
    scroll_up();
}

void console_writer(char *buf, u32 count)
{
    char ch;
    char *ptr = (char *)pos;
    while (count--)
    {
        ch = *buf++;
        switch (ch)
        {
        case NUL:
            break;
        case BEL:
            break;
        case BS:
            command_bs();
            break;
        case HT:
            break;
        case LF:
            command_lf();
            command_cr();
            break;
        case VT:
            break;
        case FF:
            command_lf();
            break;
        case CR:
            command_cr();
            break;
        case DEL:
            command_del();
            break;

        default:
            if (x >= WIDTH)
            {
                x -= WIDTH;
                pos -= ROW_SIZE;
                command_lf();
            }

            *ptr = ch;
            ptr++;
            *ptr = attr;
            ptr++;

            pos += 2;
            x++;
            break;
        };
    }
    set_cursor();
}
void console_init()
{
    console_clear();
}
