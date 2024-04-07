#include <onix/printk.h>
#include <onix/stdarg.h>
#include <onix/stdio.h>
#include <onix/console.h>

static char buf[1024];

int printk(const char *fmt, ...)
{
    va_list args;
    int i;

    va_start(args, fmt);
    i = vsprintf(buf, fmt, args);
    va_end(args);
    console_writer(buf, i);
    return i;
}