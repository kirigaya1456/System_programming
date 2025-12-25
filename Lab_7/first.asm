format elf64

public _start

section '.bss' writable
    buffer rb 1024
    args rq 64
    tokens rb 2048
    pid rq 1
    status rd 1
    
    mapped_addr rq 1
    mapped_size rq 1
    
    env_term db "TERM=xterm-256color", 0
    env_path db "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 0
    env_home db "HOME=/home/user", 0
    env_user db "USER=user", 0
    env_shell db "SHELL=/bin/bash", 0
    env_pwd db "PWD=.", 0
    envp rq 16

section '.text' executable

mmap_anonymous:
    push rbx
    
    mov rbx, rdi
    
    mov rax, 9
    xor rdi, rdi
    mov rsi, rbx
    mov rdx, 3
    mov r10, 0x22
    mov r8, -1
    xor r9, r9
    syscall
    
    cmp rax, -4095
    jae .error
    
    pop rbx
    ret
    
.error:
    mov rax, -1
    pop rbx
    ret

munmap_memory:
    mov rax, 11
    syscall
    ret

strcpy:
    push rbx
    xor rcx, rcx
.copy_loop:
    mov bl, [rsi+rcx]
    mov [rdi+rcx], bl
    test bl, bl
    jz .done
    inc rcx
    jmp .copy_loop
.done:
    pop rbx
    ret

_start:
    lea rax, [env_term]
    mov [envp], rax
    lea rax, [env_path]
    mov [envp + 8], rax
    lea rax, [env_home]
    mov [envp + 16], rax
    lea rax, [env_user]
    mov [envp + 24], rax
    lea rax, [env_shell]
    mov [envp + 32], rax
    lea rax, [env_pwd]
    mov [envp + 40], rax
    mov qword [envp + 48], 0

    mov rdi, 4096
    call mmap_anonymous
    cmp rax, -1
    je .skip_use
    
    mov [mapped_addr], rax
    mov qword [mapped_size], 4096
    
    mov rdi, rax
    mov rsi, example_str
    call strcpy

.skip_use:
main_loop:
    mov rax, 1
    mov rdi, 1
    mov rsi, prompt
    mov rdx, prompt_len
    syscall
    
    mov rsi, buffer
    call input_keyboard
    
    cmp byte [buffer], 0
    je main_loop
    
    mov rax, 57
    syscall
    
    cmp rax, 0
    jne wait_up

    mov rdi, buffer
    call parse

    mov rdi, [args]
    lea rsi, [args]
    lea rdx, [envp]
    mov rax, 59
    syscall
    
    call exit

wait_up:
    mov [pid], rax
    
    mov rdi, [pid]
    mov rsi, status
    xor rdx, rdx
    xor r10, r10
    mov rax, 61
    syscall
    jmp main_loop

input_keyboard:
    push rdi
    push rdx
    push rcx
    
    mov rax, 0
    mov rdi, 0
    mov rdx, 1023
    syscall
    
    mov rcx, rax
    cmp rcx, 0
    je .done
    mov byte [rsi + rcx - 1], 0
    
.done:
    pop rcx
    pop rdx
    pop rdi
    ret

parse:
    push rbx
    push r12
    push r13

    mov rbx, rdi
    lea r12, [tokens]
    lea r13, [args]
    xor rcx, rcx
    xor rdx, rdx

.skip_spaces:
    mov al, [rbx + rdx]
    test al, al
    jz .done
    cmp al, ' '
    jne .start_token
    inc rdx
    jmp .skip_spaces

.start_token:
    mov [r13 + rcx*8], r12
    inc rcx

.copy_token:
    mov al, [rbx + rdx]
    test al, al
    jz .end_token
    cmp al, ' '
    je .end_token
    mov [r12], al
    inc r12
    inc rdx
    jmp .copy_token

.end_token:
    mov byte [r12], 0
    inc r12
    mov al, [rbx + rdx]
    test al, al
    jz .done
    inc rdx
    jmp .skip_spaces

.done:
    mov qword [r13 + rcx*8], 0
    pop r13
    pop r12
    pop rbx
    ret

exit:
    mov rdi, [mapped_addr]
    cmp rdi, 0
    je .no_memory
    mov rsi, [mapped_size]
    call munmap_memory

.no_memory:
    mov rax, 60
    xor rdi, rdi
    syscall

section '.data'
example_str db "Hello from mapped memory!", 0
prompt db "$ ", 0
prompt_len = $ - prompt