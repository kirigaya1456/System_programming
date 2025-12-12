format ELF64

section '.text' executable

public q_create
public q_destroy
public q_push
public q_pop
public q_fill_random
public q_count_primes
public q_get_odds
public q_filter_evens

SYS_MMAP    equ 9
SYS_MUNMAP  equ 11
PROT_RW     equ 3
MAP_ANON    equ 0x22
FD_NONE     equ -1

OFF_CAP     equ 0
OFF_CNT     equ 8
OFF_HEAD    equ 16
OFF_TAIL    equ 24
OFF_DATA    equ 32

q_create:
    push rbp
    mov rbp, rsp
    push rbx
    push r12

    mov r12, rdi

    mov rax, rdi
    shl rax, 3
    add rax, 32
    mov rsi, rax

    mov rax, SYS_MMAP
    mov rdi, 0
    mov rdx, PROT_RW
    mov r10, MAP_ANON
    mov r8, FD_NONE
    mov r9, 0
    syscall

    test rax, rax
    js .error

    mov [rax + OFF_CAP], r12
    mov qword [rax + OFF_CNT], 0
    mov qword [rax + OFF_HEAD], 0
    mov qword [rax + OFF_TAIL], 0
    
    jmp .done

.error:
    xor rax, rax

.done:
    pop r12
    pop rbx
    leave
    ret

q_destroy:
    test rdi, rdi
    jz .ret

    push rbp
    mov rbp, rsp

    mov rcx, [rdi + OFF_CAP]
    shl rcx, 3
    add rcx, 32

    mov rax, SYS_MUNMAP
    mov rsi, rcx
    syscall

    leave
.ret:
    ret

q_push:
    mov rcx, [rdi + OFF_CNT]
    cmp rcx, [rdi + OFF_CAP]
    jge .full

    mov r8, [rdi + OFF_TAIL]
    
    lea rax, [rdi + OFF_DATA]
    mov [rax + r8*8], rsi

    inc r8
    xor rdx, rdx
    mov rax, r8
    div qword [rdi + OFF_CAP]
    mov [rdi + OFF_TAIL], rdx

    inc qword [rdi + OFF_CNT]
    mov rax, 1
    ret

.full:
    xor rax, rax
    ret

q_pop:
    mov rcx, [rdi + OFF_CNT]
    test rcx, rcx
    jz .empty

    mov r8, [rdi + OFF_HEAD]
    
    lea rax, [rdi + OFF_DATA]
    mov r9, [rax + r8*8]
    mov [rsi], r9

    inc r8
    xor rdx, rdx
    mov rax, r8
    div qword [rdi + OFF_CAP]
    mov [rdi + OFF_HEAD], rdx

    dec qword [rdi + OFF_CNT]
    mov rax, 1
    ret

.empty:
    xor rax, rax
    ret

q_fill_random:
    push rbp
    push rbx
    push r12
    push r13
    
    mov rbx, rdi
    mov r12, rsi
    
    rdtsc
    mov r13, rax

.loop:
    test r12, r12
    jz .done

    mov rax, r13
    mov rcx, 1103515245
    mul rcx
    add rax, 12345
    mov r13, rax

    xor rdx, rdx
    mov rcx, 100
    div rcx
    mov rsi, rdx

    mov rdi, rbx
    call q_push
    
    dec r12
    jmp .loop

.done:
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

is_prime:
    cmp rdi, 1
    jle .not_prime
    cmp rdi, 3
    jle .is_prime_yes
    
    test rdi, 1
    jz .not_prime

    mov rsi, 3
.prime_loop:
    mov rax, rsi
    mul rsi
    cmp rax, rdi
    jg .is_prime_yes

    mov rax, rdi
    xor rdx, rdx
    div rsi
    test rdx, rdx
    jz .not_prime

    add rsi, 2
    jmp .prime_loop

.is_prime_yes:
    mov rax, 1
    ret
.not_prime:
    xor rax, rax
    ret

q_count_primes:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rbx, rdi
    xor r12, r12
    
    mov r13, [rbx + OFF_CNT]
    mov r14, [rbx + OFF_HEAD]
    mov r15, [rbx + OFF_CAP]

.loop:
    test r13, r13
    jz .done

    lea rax, [rbx + OFF_DATA]
    mov rdi, [rax + r14*8]
    
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    call is_prime
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx

    add r12, rax

    inc r14
    xor rdx, rdx
    mov rax, r14
    div r15
    mov r14, rdx

    dec r13
    jmp .loop

.done:
    mov rax, r12
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

q_get_odds:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rbx, rdi
    mov r12, rsi
    xor r13, r13
    
    mov r8, [rbx + OFF_CNT]
    mov r9, [rbx + OFF_HEAD]
    mov r10, [rbx + OFF_CAP]

.loop:
    test r8, r8
    jz .done

    lea rax, [rbx + OFF_DATA]
    mov rcx, [rax + r9*8]

    test rcx, 1
    jz .next

    mov [r12 + r13*8], rcx
    inc r13

.next:
    inc r9
    xor rdx, rdx
    mov rax, r9
    div r10
    mov r9, rdx

    dec r8
    jmp .loop

.done:
    mov rax, r13
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

q_filter_evens:
    push rbx
    push r12
    push r13
    
    mov rbx, rdi
    mov r12, [rbx + OFF_CNT]
    
    sub rsp, 16 

.loop:
    test r12, r12
    jz .done

    mov rdi, rbx
    lea rsi, [rsp]
    call q_pop
    
    test rax, rax
    jz .done

    mov r13, [rsp]

    test r13, 1
    jz .is_even

    mov rdi, rbx
    mov rsi, r13
    call q_push
    jmp .next_iter

.is_even:
    
.next_iter:
    dec r12
    jmp .loop

.done:
    add rsp, 16
    pop r13
    pop r12
    pop rbx
    ret