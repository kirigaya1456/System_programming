format ELF64
public _start

extrn initscr
extrn start_color
extrn init_pair
extrn attron
extrn attroff
extrn mvaddch
extrn refresh
extrn getmaxx
extrn getmaxy
extrn raw
extrn noecho
extrn stdscr
extrn getch
extrn endwin
extrn timeout
extrn erase
extrn curs_set
extrn COLOR_PAIR

section '.bss' writable
    xmax_actual       dq 1
    ymax_actual       dq 1
    current_x         dq 0
    current_y         dq 0
    delta_x           dq 1
    delta_y           dq 1
    color_pair        dq 1
    symbol            db '*'

section '.text' executable
_start:
    ; Инициализация ncurses и цветов
    call initscr
    call start_color

    mov rdi, 1
    mov rsi, 1
    mov rdx, 0
    call init_pair
    mov rdi, 2
    mov rsi, 2
    mov rdx, 0
    call init_pair
    mov rdi, 3
    mov rsi, 3
    mov rdx, 0
    call init_pair
    mov rdi, 4
    mov rsi, 4
    mov rdx, 0
    call init_pair
    mov rdi, 5
    mov rsi, 5
    mov rdx, 0
    call init_pair
    mov rdi, 6
    mov rsi, 6
    mov rdx, 0
    call init_pair

    mov rdi, [stdscr]
    call getmaxx
    dec rax
    mov [xmax_actual], rax

    mov rdi, [stdscr]
    call getmaxy
    dec rax
    mov [ymax_actual], rax

    call raw
    call noecho
    xor rdi, rdi
    call curs_set

    mov qword [current_x], 5
    mov qword [current_y], 5
    mov qword [delta_x], 1
    mov qword [delta_y], 1
    mov qword [color_pair], 1

.main_loop:
    call erase

    ; Включаем цвет
    mov rdi, [color_pair]
    shl rdi, 8             ; COLOR_PAIR(n) макро = n << 8
    call attron

    ; Вывод символа
    mov rdi, [current_y]
    mov rsi, [current_x]
    mov dl, [symbol]
    call mvaddch

    ; Выключаем цвет
    mov rdi, [color_pair]
    shl rdi, 8
    call attroff

    call refresh

    ; Задержка
    mov rcx, 1000000
.delay_loop:
    dec rcx
    jnz .delay_loop

    ; Случайное направление через rdtsc (-1,0,+1)
    rdtsc
    xor rdx, rdx
    mov rbx, 3
    div rbx
    sub rdx, 1
    mov [delta_x], rdx

    rdtsc
    xor rdx, rdx
    mov rbx, 3
    div rbx
    sub rdx, 1
    mov [delta_y], rdx

    ; Обновление координат X
    mov rax, [current_x]
    add rax, [delta_x]
    cmp rax, 0
    jl .hit_wall_x
    mov rbx, [xmax_actual]
    cmp rax, rbx
    jg .hit_wall_x
    mov [current_x], rax
    jmp .check_y

.hit_wall_x:
    neg qword [delta_x]
    ; Случайный цвет при ударе
    rdtsc
    xor rdx, rdx
    mov rbx, 6
    div rbx
    inc rdx
    mov [color_pair], rdx
    mov rax, [current_x]
    add rax, [delta_x]
    mov [current_x], rax

.check_y:
    mov rax, [current_y]
    add rax, [delta_y]
    cmp rax, 0
    jl .hit_wall_y
    mov rbx, [ymax_actual]
    cmp rax, rbx
    jg .hit_wall_y
    mov [current_y], rax
    jmp .continue_loop

.hit_wall_y:
    neg qword [delta_y]
    rdtsc
    xor rdx, rdx
    mov rbx, 6
    div rbx
    inc rdx
    mov [color_pair], rdx
    mov rax, [current_y]
    add rax, [delta_y]
    mov [current_y], rax

.continue_loop:
    mov byte [symbol], '*'  ; символ всегда '*'

    ; Проверка клавиши выхода
    call timeout
    call getch
    cmp rax, 'q'
    je .end_program

    jmp .main_loop

.end_program:
    call endwin
    mov rax, 60
    xor rdi, rdi
    syscall