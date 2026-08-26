section .multiboot
align 4

multiboot_header:
    dd 0x1BADB002
    dd 0x00000000
    dd -(0x1BADB002 + 0x00000000)


global _start
extern long_mode_entry


section .bss
align 4096

p4_table:
    resb 4096

p3_table:
    resb 4096

p2_table:
    resb 4096

stack_bottom:
    resb 16384

stack_top:


section .text
bits 32

_start:
    mov esp, stack_top

    mov edi, eax        ; multiboot magic (GRUB leaves it in eax)
    mov esi, ebx        ; multiboot info pointer (GRUB leaves it in ebx)

    call check_multiboot
    call check_cpuid
    call check_long_mode

    call set_up_page_tables
    call enable_paging

    lgdt [gdt64.pointer]
    jmp gdt64.code:long_mode_start

    hlt


check_multiboot:
    cmp edi, 0x2BADB002
    jne .no_multiboot ; IM FUCKING TIRED
    ret

.no_multiboot:
    mov al, "0"
    jmp error


check_cpuid:
    pushfd
    pop eax

    mov ecx, eax

    xor eax, 1 << 21

    push eax
    popfd

    pushfd
    pop eax

    push ecx ; WATCH THIS PEAK VIDEO INSTEAD https://www.youtube.com/watch?v=u7vOdlwA3E0

    popfd

    cmp eax, ecx
    je .no_cpuid

    ret

.no_cpuid:
    mov al, "1"
    jmp error


check_long_mode:
    mov eax, 0x80000000
    cpuid

    cmp eax, 0x80000001
    jb .no_long_mode

    mov eax, 0x80000001
    cpuid

    test edx, 1 << 29
    jz .no_long_mode

    ret

.no_long_mode:
    mov al, "2" ; BOM BOM BOM BOM say yes lets get together and forgive say yes or no whatever
    jmp error


set_up_page_tables:
    mov eax, p3_table
    or eax, 0b11
    mov [p4_table], eax

    mov eax, p2_table
    or eax, 0b11
    mov [p3_table], eax

    xor ecx, ecx

.map_p2_table:
    mov eax, 0x200000
    mul ecx

    or eax, 0b10000011

    mov [p2_table + ecx * 8], eax

    inc ecx
    cmp ecx, 512
    jne .map_p2_table

    ret


enable_paging:
    mov eax, p4_table
    mov cr3, eax

    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    mov ecx, 0xC0000080
    rdmsr

    or eax, 1 << 8

    wrmsr

    mov eax, cr0 ; why are you reading this
    or eax, 1 << 31 ; i used the Intel manual, since this shits literally pain?
    mov cr0, eax

    ret


error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f4f4f52
    mov dword [0xb8008], 0x4f3a4f52
    mov byte [0xb800a], al

    hlt


section .rodata

gdt64:
    dq 0

.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)

.pointer:
    dw $ - gdt64 - 1
    dq gdt64


section .text
bits 64

long_mode_start:

    mov ax, 0

    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call long_mode_entry

    hlt ; the end of a journey, and a proof im the smartest programmer alive.
