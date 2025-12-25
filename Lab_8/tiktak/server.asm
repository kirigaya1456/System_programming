format ELF64 executable 3
entry start

SYS_SOCKET = 41
SYS_BIND = 49
SYS_LISTEN = 50
SYS_ACCEPT = 43
SYS_READ = 0
SYS_WRITE = 1
SYS_CLOSE = 3
SYS_EXIT = 60

AF_INET = 2
SOCK_STREAM = 1
INADDR_ANY = 0
PORT = 12345

BUFFER_SIZE = 16
BOARD_SIZE = 9

struc sockaddr_in {
    .sin_family dw 0
    .sin_port dw 0
    .sin_addr dd 0
    .sin_zero dq 0
}

segment readable executable

start:
    mov rax, SYS_SOCKET
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jge socket_ok
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_socket_error
    mov rdx, msg_socket_error_len
    syscall
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

socket_ok:
    mov [server_socket], rax

    mov word [server_addr.sin_family], AF_INET
    
    mov ax, PORT
    xchg al, ah
    mov word [server_addr.sin_port], ax
    
    mov dword [server_addr.sin_addr], INADDR_ANY

    mov rax, SYS_BIND
    mov rdi, [server_socket]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    cmp rax, 0
    jge bind_ok
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_bind_error
    mov rdx, msg_bind_error_len
    syscall
    jmp error_close_socket

bind_ok:
    mov rax, SYS_LISTEN
    mov rdi, [server_socket]
    mov rsi, 2
    syscall
    
    cmp rax, 0
    jge listen_ok
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_listen_error
    mov rdx, msg_listen_error_len
    syscall
    jmp error_close_socket

listen_ok:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_server_started
    mov rdx, msg_server_started_len
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_waiting1
    mov rdx, msg_waiting1_len
    syscall

    mov rax, SYS_ACCEPT
    mov rdi, [server_socket]
    mov rsi, 0
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jge accept1_ok
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_accept_error
    mov rdx, msg_accept_error_len
    syscall
    jmp error_close_socket

accept1_ok:
    mov [player1_socket], rax

    mov rax, 1
    mov rdi, [player1_socket]
    mov rsi, player1_num
    mov rdx, 1
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, msg_waiting2
    mov rdx, msg_waiting2_len
    syscall

    mov rax, SYS_ACCEPT
    mov rdi, [server_socket]
    mov rsi, 0
    mov rdx, 0
    syscall
    
    cmp rax, 0
    jge accept2_ok
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_accept_error
    mov rdx, msg_accept_error_len
    syscall
    jmp error_close_player1

accept2_ok:
    mov [player2_socket], rax

    mov rax, 1
    mov rdi, [player2_socket]
    mov rsi, player2_num
    mov rdx, 1
    syscall

    call init_game
    call send_game_state

game_loop:
    mov al, [current_player]
    cmp al, 1
    je player1_turn
    jmp player2_turn

player1_turn:
    mov rdi, [player1_socket]
    call process_move
    jmp after_move

player2_turn:
    mov rdi, [player2_socket]
    call process_move

after_move:
    cmp rax, 0
    jne invalid_move

    call check_win
    cmp al, 0
    jne game_over

    call check_draw
    cmp al, 1
    je game_draw

    mov al, [current_player]
    xor al, 3
    mov [current_player], al

    call send_game_state
    jmp game_loop

invalid_move:
    mov rdi, [player1_socket]
    cmp byte [current_player], 1
    je send_error
    mov rdi, [player2_socket]
send_error:
    mov rax, 1
    mov rsi, msg_invalid
    mov rdx, msg_invalid_len
    syscall
    jmp game_loop

game_draw:
    mov byte [winner], 3
    jmp game_over_end

game_over:
    mov [winner], al

game_over_end:
    call send_game_state
    
    cmp byte [winner], 3
    je send_draw
    
    mov rsi, msg_win
    mov rdx, msg_win_len
    jmp send_result
    
send_draw:
    mov rsi, msg_draw
    mov rdx, msg_draw_len

send_result:
    mov rax, 1
    mov rdi, [player1_socket]
    syscall
    
    mov rax, 1
    mov rdi, [player2_socket]
    syscall

    mov rax, SYS_CLOSE
    mov rdi, [player1_socket]
    syscall
    
    mov rax, SYS_CLOSE
    mov rdi, [player2_socket]
    syscall
    
    mov rax, SYS_CLOSE
    mov rdi, [server_socket]
    syscall
    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

error_close_player1:
    mov rax, SYS_CLOSE
    mov rdi, [player1_socket]
    syscall

error_close_socket:
    mov rax, SYS_CLOSE
    mov rdi, [server_socket]
    syscall

error_exit:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

init_game:
    mov rcx, BOARD_SIZE
    lea rdi, [board]
    xor al, al
    rep stosb
    mov byte [current_player], 1
    mov byte [winner], 0
    ret

send_game_state:
    lea rdi, [state_buffer]
    lea rsi, [board]
    mov rcx, BOARD_SIZE

convert_loop:
    mov al, [rsi]
    cmp al, 0
    je put_dot
    cmp al, 1
    je put_x
    mov al, 'O'
    jmp put_char
put_x:
    mov al, 'X'
    jmp put_char
put_dot:
    mov al, '.'
put_char:
    stosb
    inc rsi
    loop convert_loop
    
    mov al, [current_player]
    add al, '0'
    stosb
    
    mov rax, 1
    mov rdi, [player1_socket]
    lea rsi, [state_buffer]
    mov rdx, 11
    syscall
    
    mov rax, 1
    mov rdi, [player2_socket]
    lea rsi, [state_buffer]
    mov rdx, 11
    syscall
    ret

process_move:
    push rdi
    mov rax, 0
    lea rsi, [buffer]
    mov rdx, BUFFER_SIZE
    syscall
    
    cmp rax, 0
    jle move_error
    
    mov al, [buffer]
    cmp al, '1'
    jb move_error
    cmp al, '9'
    ja move_error
    
    sub al, '1'
    movzx rbx, al
    cmp byte [board + rbx], 0
    jne move_error
    
    mov al, [current_player]
    mov [board + rbx], al
    
    pop rdi
    xor rax, rax
    ret

move_error:
    pop rdi
    mov rax, -1
    ret

check_win:
    lea rsi, [board]
    call check_line
    cmp al, 0
    jne win_end
    
    add rsi, 3
    call check_line
    cmp al, 0
    jne win_end
    
    add rsi, 3
    call check_line
    cmp al, 0
    jne win_end
    
    lea rsi, [board]
    call check_column
    cmp al, 0
    jne win_end
    
    inc rsi
    call check_column
    cmp al, 0
    jne win_end
    
    inc rsi
    call check_column
    cmp al, 0
    jne win_end
    
    lea rsi, [board]
    call check_diag1
    cmp al, 0
    jne win_end
    
    lea rsi, [board+2]
    call check_diag2
    cmp al, 0
    jne win_end
    
    xor al, al
    ret

win_end:
    ret

check_line:
    mov al, [rsi]
    cmp al, 0
    je no_win
    cmp al, [rsi+1]
    jne no_win
    cmp al, [rsi+2]
    jne no_win
    ret

check_column:
    mov al, [rsi]
    cmp al, 0
    je no_win
    cmp al, [rsi+3]
    jne no_win
    cmp al, [rsi+6]
    jne no_win
    ret

check_diag1:
    mov al, [rsi]
    cmp al, 0
    je no_win
    cmp al, [rsi+4]
    jne no_win
    cmp al, [rsi+8]
    jne no_win
    ret

check_diag2:
    mov al, [rsi]
    cmp al, 0
    je no_win
    cmp al, [rsi+2]
    jne no_win
    cmp al, [rsi+4]
    jne no_win
    ret

no_win:
    xor al, al
    ret

check_draw:
    mov rcx, BOARD_SIZE
    lea rsi, [board]
draw_loop:
    cmp byte [rsi], 0
    je not_draw
    inc rsi
    loop draw_loop
    mov al, 1
    ret
not_draw:
    xor al, al
    ret

segment readable writeable

server_socket dq 0
player1_socket dq 0
player2_socket dq 0

server_addr sockaddr_in

board rb BOARD_SIZE
current_player db 0
winner db 0

buffer rb BUFFER_SIZE
state_buffer rb 11

player1_num db '1'
player2_num db '2'

msg_server_started db "Server started on port 12345...", 10
msg_server_started_len = $ - msg_server_started

msg_waiting1 db "Waiting for player 1...", 10
msg_waiting1_len = $ - msg_waiting1

msg_waiting2 db "Waiting for player 2...", 10
msg_waiting2_len = $ - msg_waiting2

msg_socket_error db "Error creating socket", 10
msg_socket_error_len = $ - msg_socket_error

msg_bind_error db "Error binding socket", 10
msg_bind_error_len = $ - msg_bind_error

msg_listen_error db "Error listening on socket", 10
msg_listen_error_len = $ - msg_listen_error

msg_accept_error db "Error accepting connection", 10
msg_accept_error_len = $ - msg_accept_error

msg_invalid db "Invalid move. Try again.", 10
msg_invalid_len = $ - msg_invalid

msg_win db "You win!", 10
msg_win_len = $ - msg_win

msg_draw db "It's a draw!", 10
msg_draw_len = $ - msg_draw