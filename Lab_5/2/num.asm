format ELF64
public _start

include 'func.asm'

section '.bss' writeable
    input rb 255
    N dq 0
    buffer rb 20
    output rb 1

section '.text' executable
_start:
    call read
    mov rsi, input
    call str_number
    mov [N], rax

    call read

    mov rdi, input
    call remove_newline

    mov rdi, input
    mov rax, 2
    mov rsi, 1078
    mov rdx, 777o
    syscall
    cmp rax, 0
    jl exit

    mov r8, rax

    mov r10, 1

    .main_loop:
        inc r10
        mov r9, r10

        mov rax, [N]
        cmp r10, rax
        jg .second

        call is_prime
        cmp rax, 1
        jne .main_loop

        mov rax, r10
        call print_num
        mov rax, ' '
        call print

        jmp .main_loop

    .second:

    call read

    mov rdi, input
    call remove_newline

    mov rdi, input
    mov rax, 2
    mov rsi, 1078
    mov rdx, 777o
    syscall
    cmp rax, 0
    jl exit

    mov r8, rax

    mov r10, 1

    .main_loop2:
        add r10, 10
        mov r9, r10

        mov rax, [N]
        cmp r10, rax
        jg exit

        call is_prime
        cmp rax, 1
        jne .main_loop2

        mov rax, r10
        call print_num
        mov rax, ' '
        call print

        jmp .main_loop2

read:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 255
    syscall
    ret

is_prime:
    push rbp
    mov rbp, rsp
    push rbx
    push rcx
    push rdx
    push r10
    push r11

    cmp r9, 2
    jl .not_prime
    je .prime

    test r9, 1
    jz .not_prime

    mov r10, 3

.check_loop:
    mov rax, r10
    mul r10
    cmp rax, r9
    ja .prime

    mov rax, r9
    xor rdx, rdx
    div r10
    test rdx, rdx
    jz .not_prime

    add r10, 2
    jmp .check_loop

.prime:
    mov rax, 1
    jmp .exit

.not_prime:
    xor rax, rax

.exit:
    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rbx
    pop rbp
    ret

print:
    push rcx
    mov [output], al
    mov rax, 1
    mov rdi, r8
    mov rsi, output
    mov rdx, 1
    syscall
    pop rcx
    ret

print_num:
    push rbx
    push rcx
    push rdx

    mov rcx, 10
    xor rbx, rbx

    test rax, rax
    jns .loop
    push rax
    mov al, '-'
    call print
    pop rax
    neg rax

.loop:
    xor rdx, rdx
    div rcx
    push rdx
    inc rbx
    test rax, rax
    jnz .loop

.print_loop:
    pop rax
    add al, '0'
    call print
    dec rbx
    jnz .print_loop

    pop rdx
    pop rcx
    pop rbx
    ret

; Функция удаления символа новой строки
remove_newline:
    .loop:
        mov al, [rdi]
        test al, al
        jz .done
        cmp al, 10
        je .replace
        cmp al, 13
        je .replace
        inc rdi
        jmp .loop
    .replace:
        mov byte [rdi], 0
    .done:
        ret
