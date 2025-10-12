

format ELF64
public _start

section '.text' executable
_start:
    ; --- читаем stdin ---
    mov     rax, 0
    mov     rdi, 0
    lea     rsi, [buf]
    mov     rdx, 4096
    syscall
    test    rax, rax
    jle     .no
    mov     [len], rax

    lea     r13, [buf]
    mov     r9, [len]
    lea     r10, [buf]
    add     r10, r9

    call    read_number
    mov     r12, rax         
    test    r12, r12
    jle     .no

    xor     rbx, rbx       
    xor     r14, r14         

.next_vote:
    cmp     r14, r12
    jge     .eval
    call    read_number
    cmp     rax, 1
    jne     .skip
    inc     rbx
.skip:
    inc     r14
    jmp     .next_vote

.eval:
    mov     rax, r12
    shr     rax, 1
    cmp     rbx, rax
    jg      .yes

.no:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [msg_no]
    mov     rdx, msg_no_len
    syscall
    jmp     .exit

.yes:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [msg_yes]
    mov     rdx, msg_yes_len
    syscall

.exit:
    mov     rax, 60
    xor     rdi, rdi
    syscall


read_number:
.skip_space:
    cmp     r13, r10
    jae     .eof
    mov     al, [r13]
    cmp     al, ' '
    je      .inc_ws
    cmp     al, 10
    je      .inc_ws
    cmp     al, 13
    je      .inc_ws
    jmp     .parse
.inc_ws:
    inc     r13
    jmp     .skip_space

.parse:
    xor     rax, rax
.loop:
    cmp     r13, r10
    jae     .done
    movzx   rdx, byte [r13]
    cmp     rdx, '0'
    jb      .done
    cmp     rdx, '9'
    ja      .done
    sub     rdx, '0'
    imul    rax, rax, 10
    add     rax, rdx
    inc     r13
    jmp     .loop

.done:
    ret

.eof:
    xor     rax, rax
    ret


section '.data' writeable
buf rb 4096
len dq 0

msg_yes db "Решение: Да",10
msg_yes_len = $-msg_yes
msg_no  db "Решение: Нет",10
msg_no_len = $-msg_no
