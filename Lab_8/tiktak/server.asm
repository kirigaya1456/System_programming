format ELF64 executable 3
entry start

SYS_SOCKET = 41
SYS_CONNECT = 42
SYS_READ = 0
SYS_WRITE = 1
SYS_CLOSE = 3
SYS_EXIT = 60

AF_INET = 2
SOCK_STREAM = 1
PORT = 12345
SERVER_IP = 0x0100007F

BUFFER_SIZE = 16

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
    mov [client_socket], rax
    mov word [server_addr.sin_family], AF_INET
    mov ax, PORT
    xchg al, ah
    mov word [server_addr.sin_port], ax
    mov dword [server_addr.sin_addr], SERVER_IP
    mov rax, SYS_CONNECT
    mov rdi, [client_socket]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    cmp rax, 0
    jge connect_ok
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connect_error
    mov rdx, msg_connect_error_len
    syscall
    jmp error_close_socket

connect_ok:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connected
    mov rdx, msg_connected_len
    syscall
    mov rax, 0
    mov rdi, [client_socket]
    lea rsi, [buffer]
    mov rdx, 1
    syscall
    cmp rax, 1
    jge got_player_num
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_server_error
    mov rdx, msg_server_error_len
    syscall
    jmp exit

got_player_num:
    mov al, [buffer]
    sub al, '0'
    mov [my_player], al
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_player
    mov rdx, msg_player_len
    syscall
    mov rax, 1
    mov rdi, 1
    lea rsi, [buffer]
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

game_loop:
    mov rax, 0
    mov rdi, [client_socket]
    lea rsi, [buffer]
    mov rdx, BUFFER_SIZE
    syscall
    cmp rax, 0
    jle server_closed
    call display_board
    mov al, [buffer+9]
    sub al, '0'
    mov [current_player], al
    cmp al, [my_player]
    jne wait_turn

input_loop:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_enter_move
    mov rdx, msg_enter_move_len
    syscall
    mov rax, 0
    mov rdi, 0
    lea rsi, [input_buffer]
    mov rdx, 2
    syscall
    mov al, [input_buffer]
    cmp al, '1'
    jb input_loop
    cmp al, '9'
    ja input_loop
    mov rax, 1
    mov rdi, [client_socket]
    lea rsi, [input_buffer]
    mov rdx, 1
    syscall
    jmp game_loop

wait_turn:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_waiting
    mov rdx, msg_waiting_len
    syscall
    jmp game_loop

server_closed:
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_server_closed
    mov rdx, msg_server_closed_len
    syscall

exit:
    mov rax, SYS_CLOSE
    mov rdi, [client_socket]
    syscall
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

error_close_socket:
    mov rax, SYS_CLOSE
    mov rdi, [client_socket]
    syscall
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

display_board:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_board
    mov rdx, msg_board_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_current_player
    mov rdx, msg_current_player_len
    syscall
    mov al, [current_player]
    add al, '0'
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_top
    mov rdx, separator_top_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, left_border
    mov rdx, 1
    syscall
    mov al, [buffer]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, middle_separator
    mov rdx, 1
    syscall
    mov al, [buffer+1]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, middle_separator
    mov rdx, 1
    syscall
    mov al, [buffer+2]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, right_border
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_middle
    mov rdx, separator_middle_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, left_border
    mov rdx, 1
    syscall
    mov al, [buffer+3]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, middle_separator
    mov rdx, 1
    syscall
    mov al, [buffer+4]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, middle_separator
    mov rdx, 1
    syscall
    mov al, [buffer+5]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, right_border
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_middle
    mov rdx, separator_middle_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, left_border
    mov rdx, 1
    syscall
    mov al, [buffer+6]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, middle_separator
    mov rdx, 1
    syscall
    mov al, [buffer+7]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, middle_separator
    mov rdx, 1
    syscall
    mov al, [buffer+8]
    mov [temp_char], al
    mov rax, 1
    mov rdi, 1
    mov rsi, temp_char
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, right_border
    mov rdx, 1
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_middle
    mov rdx, separator_middle_len
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_positions
    mov rdx, msg_positions_len
    syscall
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

segment readable writeable

client_socket dq 0
server_addr sockaddr_in

my_player db 0
current_player db 0

buffer rb BUFFER_SIZE
input_buffer rb 2
temp_char rb 1

msg_connected db "Connected to server.", 10
msg_connected_len = $ - msg_connected

msg_player db "You are player: "
msg_player_len = $ - msg_player

msg_board db 10, "Game board:", 10
msg_board_len = $ - msg_board

msg_current_player db "Current player: "
msg_current_player_len = $ - msg_current_player

msg_positions db "Positions:",10, "1 2 3", 10, "4 5 6", 10, "7 8 9", 10, 10
msg_positions_len = $ - msg_positions

msg_enter_move db "Enter your move (1-9): "
msg_enter_move_len = $ - msg_enter_move

msg_waiting db "Waiting for opponent's move...", 10
msg_waiting_len = $ - msg_waiting

msg_server_closed db "Server disconnected.", 10
msg_server_closed_len = $ - msg_server_closed

msg_socket_error db "Error creating socket", 10
msg_socket_error_len = $ - msg_socket_error

msg_connect_error db "Error connecting to server", 10
msg_connect_error_len = $ - msg_connect_error

msg_server_error db "Error receiving data from server", 10
msg_server_error_len = $ - msg_server_error

newline db 10

separator_top db "+----------+", 10
separator_top_len = $ - separator_top

separator_middle db "+---+", 10
separator_middle_len = $ - separator_middle

left_border db "|"
middle_separator db "|"
right_border db "|", 10