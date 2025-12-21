; Клиент для игры в крестики-нолики
; FASM, Linux x64

format ELF64 executable 3
entry start

; Системные вызовы
SYS_SOCKET = 41
SYS_CONNECT = 42
SYS_READ = 0
SYS_WRITE = 1
SYS_CLOSE = 3
SYS_EXIT = 60

; Параметры сокетов
AF_INET = 2
SOCK_STREAM = 1
PORT = 12345
SERVER_IP = 0x0100007F ; 127.0.0.1 в правильном формате

; Размеры
BUFFER_SIZE = 16

struc sockaddr_in {
    .sin_family dw 0
    .sin_port dw 0
    .sin_addr dd 0
    .sin_zero dq 0
}

segment readable executable

start:
    ; Создание сокета
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

    ; Заполнение структуры адреса
    mov word [server_addr.sin_family], AF_INET
    
    ; Преобразование порта в сетевой порядок байтов
    mov ax, PORT
    xchg al, ah
    mov word [server_addr.sin_port], ax
    
    mov dword [server_addr.sin_addr], SERVER_IP

    ; Подключение к серверу
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
    ; Сообщение об успешном подключении
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_connected
    mov rdx, msg_connected_len
    syscall

    ; Получение номера игрока
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
    
    ; Вывод номера игрока
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

    ; Основной цикл игры
game_loop:
    ; Получение состояния от сервера
    mov rax, 0
    mov rdi, [client_socket]
    lea rsi, [buffer]
    mov rdx, BUFFER_SIZE
    syscall
    cmp rax, 0
    jle server_closed

    ; Отображение доски
    call display_board

    ; Проверка, наш ли ход
    mov al, [buffer+9]
    sub al, '0'
    mov [current_player], al
    
    cmp al, [my_player]
    jne wait_turn

    ; Ввод хода
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

    ; Проверка ввода
    mov al, [input_buffer]
    cmp al, '1'
    jb input_loop
    cmp al, '9'
    ja input_loop

    ; Отправка хода
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
    
    ; Вывод заголовка
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_board
    mov rdx, msg_board_len
    syscall

    ; Вывод номера текущего игрока
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
    
    ; Вывод разделителя
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_top
    mov rdx, separator_top_len
    syscall

    ; Вывод первой строки
    mov rax, 1
    mov rdi, 1
    mov rsi, left_border
    mov rdx, 1
    syscall
    
    ; Первая ячейка
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
    
    ; Вторая ячейка
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
    
    ; Третья ячейка
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
    
    ; Разделитель
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_middle
    mov rdx, separator_middle_len
    syscall
    
    ; Вывод второй строки
    mov rax, 1
    mov rdi, 1
    mov rsi, left_border
    mov rdx, 1
    syscall
    
    ; Четвертая ячейка
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
    
    ; Пятая ячейка
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
    
    ; Шестая ячейка
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
    
    ; Разделитель
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_middle
    mov rdx, separator_middle_len
    syscall
    
    ; Вывод третьей строки
    mov rax, 1
    mov rdi, 1
    mov rsi, left_border
    mov rdx, 1
    syscall
    
    ; Седьмая ячейка
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
    
    ; Восьмая ячейка
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
    
    ; Девятая ячейка
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
    
    ; Нижний разделитель
    mov rax, 1
    mov rdi, 1
    mov rsi, separator_middle
    mov rdx, separator_middle _len
    syscall
    
    ; Вывод нумерации позиций
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

; Данные
client_socket dq 0
server_addr sockaddr_in

my_player db 0
current_player db 0

buffer rb BUFFER_SIZE
input_buffer rb 2
temp_char rb 1

; Сообщения
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

; Элементы для отрисовки доски
separator_top db "+----------+", 10
separator_top_len = $ - separator_top

separator_middle db "+---+", 10
separator_middle_len = $ - separator_middle

left_border db "|"
middle_separator db "|"
right_border db "|", 10