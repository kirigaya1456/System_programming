format elf64

public _start

section '.bss' writable
    buffer rb 1024
    args rq 64
    tokens rb 2048
    pid rq 1
    status rd 1

    ; Переменные окружения (обязательные для ncurses)
    env_term db "TERM=xterm-256color", 0
    env_path db "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin", 0
    env_home db "HOME=/home/user", 0
    env_user db "USER=user", 0
    env_shell db "SHELL=/bin/bash", 0
    env_pwd db "PWD=.", 0
    envp rq 16

section '.text' executable
_start:
; Инициализация массива envp
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
    mov qword [envp + 48], 0  ; NULL терминатор

main_loop:
    mov rsi, buffer
    call input_keyboard
    mov rax, 57
    syscall

    cmp byte [buffer], 0
    je main_loop

    cmp rax, 0
    jne wait_up

    mov rdi, buffer
    call parse

    mov rdi, [args]
    lea rsi, [args]
    lea rdx, [envp]
    mov rax, 59
    syscall

    ;syscall
    call exit

wait_up:
    mov rdi, -1
    mov rsi, status
    mov rdx, 0
    mov r10, 0
    mov rax, 61
    syscall
    jmp main_loop

;The function realizates user input from the keyboard
;input: rsi - place of memory saved input string
input_keyboard:
  push rax
  push rdi
  push rdx

  mov rax, 0
  mov rdi, 0
  mov rdx, 255
  syscall

  xor rcx, rcx
  .loop:
     mov al, [rsi+rcx]
     inc rcx
     cmp rax, 0x0A
     jne .loop
  dec rcx
  mov byte [rsi+rcx], 0

  pop rdx
  pop rdi
  pop rax
  ret

; Парсинг аргументов
parse:
    push rbx
    push r12
    push r13

    mov rbx, rdi
    lea r12, [tokens]
    lea r13, [args]
    xor rcx, rcx
    xor rdx, rdx

.skip:
    mov al, [rbx + rdx]
    test al, al
    jz .done
    cmp al, ' '
    jne .start
    inc rdx
    jmp .skip

.start:
    mov [r13 + rcx*8], r12
.copy:
    mov al, [rbx + rdx]
    test al, al
    jz .end
    cmp al, ' '
    je .end
    mov [r12], al
    inc r12
    inc rdx
    jmp .copy

.end:
    mov byte [r12], 0
    inc r12
    inc rcx
    mov al, [rbx + rdx]
    test al, al
    jz .done
    inc rdx
    jmp .skip

.done:
    mov qword [r13 + rcx*8], 0
    pop r13
    pop r12
    pop rbx
    ret

exit:
	mov rax, 0x3c
	mov rdi, 0
	syscall