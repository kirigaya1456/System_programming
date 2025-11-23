format ELF64

section '.data' writeable
    N db '5277616985',0
    newline db 10

section '.bss' writeable
    output rb 20

section '.text' executable
public _start

_start:
    
    xor rax, rax
    mov rsi, N
    mov rcx, 10

digit_sum:
    movzx rbx, byte [rsi]
    sub rbx, '0'
    add rax, rbx
    inc rsi
    loop digit_sum

    mov rdi, output + 19
    mov byte [rdi], 0
    mov rbx, 10

int_to_str:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    test rax, rax
    jnz int_to_str

    mov rsi, rdi
    mov rdx, output + 19
    sub rdx, rdi

    mov rax, 1
    mov rdi, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall