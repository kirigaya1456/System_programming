format ELF64
public _start

section '.data' writeable
    S db "AMVtdiYVETHnNhuYwnWDVBqL", 0
    newline db 10

section '.text' executable
_start:
    mov rsi, S
.find_end:
    cmp byte [rsi], 0
    je .end_found
    inc rsi
    jmp .find_end

.end_found:
    dec rsi

.reverse_loop:
    cmp rsi, S
    jl .done
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    push rsi
    syscall
    pop rsi
    dec rsi
    jmp .reverse_loop

.done:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall