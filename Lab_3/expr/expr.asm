format ELF64
public _start

section '.data' writeable
usage_msg db "Usage: expr <a> <b> <c>",10
usage_len = $ - usage_msg
newline db 10

section '.bss' writeable
buf rb 32

section '.text' executable align 16

atoi:
    push rbx
    xor rax, rax
    xor rbx, rbx
    mov bl, [rsi]
    cmp bl, '-'
    jne .parse
    mov bl, 1
    inc rsi
.parse:
    mov cl, [rsi]
    test cl, cl
    jz .done
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    ja .done
    imul rax, 10
    sub cl, '0'
    add rax, rcx
    inc rsi
    jmp .parse
.done:
    cmp bl, 1
    jne .ret
    neg rax
.ret:
    pop rbx
    ret

_start:
    mov rdi, [rsp]
    cmp rdi, 4
    jl show_usage

    mov rsi, [rsp+16]
    call atoi
    mov r8, rax

    mov rsi, [rsp+24]
    call atoi
    mov r9, rax

    mov rsi, [rsp+32]
    call atoi
    mov r10, rax

    cmp r10, 0
    je show_usage

    mov rax, r8
    sub rax, r10
    add rax, r9
    imul rax, r10
    imul rax, r10
    add rax, r10

  
    
    lea rcx, [buf + 32]
    mov rbx, 10
    cmp rax, 0
    jge .convert
    neg rax
    mov r11b, 1
.convert:
.next_digit:
    xor rdx, rdx
    test rbx, rbx
    jz show_usage        
    div rbx
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .next_digit
    cmp r11b, 1
    jne .print
    dec rcx
    mov byte [rcx], '-'
.print:
    mov rdx, buf + 32
    sub rdx, rcx
    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    syscall


    
exit:
    mov rax, 60
    xor rdi, rdi
    syscall


show_usage:
    mov rax, 1
    mov rdi, 1
    lea rsi, [usage_msg]
    mov rdx, usage_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall

