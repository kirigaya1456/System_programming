format ELF64
include 'func.asm'

public _start

THREAD_FLAGS = 2147585792
ARRLEN = 832

section '.bss' writable
    array rb ARRLEN
    digits rq 10
    buffer rb 10
    f db "/dev/random", 0
    stack1 rq 4096
    msg1 db "Третье после максимального:", 0xA, 0
    msg2 db "Пятое после миниманого:", 0xA, 0
    msg3 db "Наиболее редко встречающаяся цифра:", 0xA, 0
    msg4 db "Среднее арифметическое значение (округленное до целого):", 0xA, 0
    space db " ", 0

section '.text' executable
_start:
    mov rax, 2
    mov rdi, f
    mov rsi, 0
    syscall
    mov r8, rax

    mov rax, 0
    mov rdi, r8
    mov rsi, array
    mov rdx, ARRLEN
    syscall

    .filter_loop:
        call filter
        cmp rax, 0
        jne .filter_loop

    mov rcx, ARRLEN
    .print:
        dec rcx
        xor rax, rax
        mov al, [array + rcx]
        mov rsi, buffer
        call number_str
        call print_str
        mov rsi, space
        call print_str
        inc rcx
    loop .print

    call new_line

    mov rax, 57
    syscall

    cmp rax, 0
    je .medium

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall

    mov rax, 57
    syscall

    cmp rax, 0
    je .most_frequent_digit

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall

    mov rax, 57
    syscall

    cmp rax, 0
    je .3th_max

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall

    mov rax, 57
    syscall

    cmp rax, 0
    je .5th_min

    mov rax, 61
    mov rdi, -1
    mov rdx, 0
    mov r10, 0
    syscall

    call exit

.3th_max:
    mov rsi, msg1
    call print_str

    xor rax, rax
    mov al, [array + ARRLEN - 3]
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit

.5th_min:
    mov rsi, msg2
    call print_str

    xor rax, rax
    mov al, [array + 4]
    mov rsi, buffer
    call number_str
    call print_str
    call new_line
    call exit

.medium:
    mov rsi, msg4
    call print_str

    xor rax, rax
    xor rbx, rbx
    .loop2:
        push rax
        mov al, [array + rbx]
        movzx r8, al
        pop rax
        add rax, r8

        inc rbx
        cmp rbx, ARRLEN
        jl .loop2

    xor rdx, rdx
    mov r8, ARRLEN
    div r8

    call number_str
    call print_str
    call new_line
    call exit

.most_frequent_digit:
    mov rsi, msg3
    call print_str

    mov rdi, digits
    mov rcx, 10
    xor rax, rax
    rep stosq

    mov rsi, array
    mov rcx, ARRLEN
    .loop1:
        movzx rax, byte [rsi]

        .decomp_loop:
            xor rdx, rdx
            mov rbx, 10
            div rbx

            mov r8, [digits + rdx*8]
            inc r8
            mov [digits + rdx*8], r8

            test rax, rax
            jnz .decomp_loop

        inc rsi
        loop .loop1

        mov rax, 0x7FFFFFFFFFFFFFFF
        xor rbx, rbx
        mov rcx, 0

    .comp_loop:
        cmp rcx, 10
        je .next2

        mov r9, [digits + rcx*8]
        cmp r9, rax
        jge @f

        mov rax, r9
        mov rbx, rcx

    @@:
        inc rcx
        jmp .comp_loop

    .next2:
        mov rax, rbx
        mov rsi, buffer
        call number_str
        call print_str
        call new_line
        call exit

filter:
    xor rax, rax
    mov rsi, array
    mov rcx, ARRLEN
    dec rcx
    .check:
        mov dl, [rsi]
        mov dh, [rsi+1]
        cmp dl, dh
        jbe .ok

        mov [rsi], dh
        mov [rsi+1], dl
        inc rax

        .ok:
        inc rsi
    loop .check
    ret