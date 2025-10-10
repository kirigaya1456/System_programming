
format ELF64
public _start

section '.data' writeable
usage_msg db "Usage: ascii_code <char>",10
usage_len = $ - usage_msg
newline db 10

section '.bss' writeable
outbuf rb 32

section '.text' executable align 16

_start:
    mov rax, [rsp]          ; argc
    cmp rax, 2
    jl usage                

    mov rsi, [rsp+16]       ; argv[1]
    movzx rax, byte [rsi]   
    test rax, rax
    jz print_zero

    ; подготовим делитель
    mov rbx, 10
    lea rcx, [outbuf + 32]

conv_loop:
    xor rdx, rdx
    div rbx                 
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz conv_loop
    jmp print

print_zero:
    lea rcx, [outbuf + 31]
    mov byte [rcx], '0'
    jmp print

print:
    lea rsi, [outbuf + 32]
    sub rsi, rcx
    mov rdx, rsi
    mov rax, 1              ; sys_write
    mov rdi, 1
    mov rsi, rcx
    syscall

    mov rax, 1
    mov rdi, 1
    lea rsi, [newline]
    mov rdx, 1
    syscall

    mov rax, 60             ; sys_exit
    xor rdi, rdi
    syscall

usage:
    mov rax, 1
    mov rdi, 1
    lea rsi, [usage_msg]
    mov rdx, usage_len
    syscall
    mov rax, 60
    mov rdi, 1
    syscall
