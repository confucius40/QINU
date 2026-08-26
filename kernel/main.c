#define VGA_MEMORY ((volatile unsigned short *)0xB8000)

static void console_write(const char *text)
{
    unsigned int i;

    for (i = 0; text[i] != '\0'; i++)
        VGA_MEMORY[i] = (unsigned short)text[i] | ((unsigned short)0x0F << 8);
}

void long_mode_entry(void)
{
    console_write("QINU");

    for (;;)
        ;
}
