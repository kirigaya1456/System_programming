; Макросы для системных вызовов x64 Linux

macro sys_write fd, buf, len {
    mov rax, 1
    mov rdi, fd
    mov rsi, buf
    mov rdx, len
    syscall
}

macro sys_read fd, buf, len {
    mov rax, 0
    mov rdi, fd
    mov rsi, buf
    mov rdx, len
    syscall
}

macro sys_exit code {
    mov rax, 60
    mov rdi, code
    syscall
}

; Функция печати строки, оканчивающейся нулем
; Вход: RSI - адрес строки
print_str:
    push rax
    push rdi
    push rdx
    push rcx
    
    mov rdx, 0
.len_loop:
    cmp byte [rsi+rdx], 0
    je .print_now
    inc rdx
    jmp .len_loop
.print_now:
    mov rax, 1      ; write
    mov rdi, 1      ; stdout
    syscall
    
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

; Функция отрисовки доски 3x3
; Вход: RSI - адрес массива из 9 байт (состояние доски)
draw_board:
    push rbx
    push rcx
    
    ; Печатаем новую строку для отступа
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    lea rsi, [newline]
    syscall

    ; Линия 1
    mov rbx, board_buffer
    
    ; Формируем строку для вывода
    ; Это упрощенный вывод: " 1 | 2 | 3 "
    
    ; Вывод 1-й клетки
    mov al, [game_board + 0]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, bar, 1
    
    ; Вывод 2-й клетки
    mov al, [game_board + 1]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, bar, 1
    
    ; Вывод 3-й клетки
    mov al, [game_board + 2]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, newline, 1
    sys_write 1, divider, 6
    
    ; Линия 2
    mov al, [game_board + 3]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, bar, 1
    mov al, [game_board + 4]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, bar, 1
    mov al, [game_board + 5]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, newline, 1
    sys_write 1, divider, 6
    
    ; Линия 3
    mov al, [game_board + 6]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, bar, 1
    mov al, [game_board + 7]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, bar, 1
    mov al, [game_board + 8]
    mov [rbx], al
    sys_write 1, rbx, 1
    sys_write 1, newline, 1
    
    pop rcx
    pop rbx
    ret

newline db 0xA
bar db ' | '
divider db '---+---+---', 0xA
board_buffer db 0