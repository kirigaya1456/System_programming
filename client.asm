; ==============================================================
; client.asm  —  "Онлайн-библиотека": клиент
; ==============================================================
format ELF64 executable 3
entry _start


SYS_READ       = 0
SYS_WRITE      = 1
SYS_CLOSE      = 3
SYS_SOCKET     = 41
SYS_CONNECT    = 42
SYS_SENDTO     = 44
SYS_EXIT       = 60


AF_INET        = 2
SOCK_STREAM    = 1
SERVER_PORT    = 8080

LOOPBACK_BE    = 0x0100007F


IN_BUF_SZ      = 2048


segment readable executable

_start:
    call    do_connect
    cmp     rax, 0
    jl      .conn_fail

    call    recv_print_response

.main_loop:
    call    show_menu

    lea     rdi, [user_buf]
    mov     rsi, IN_BUF_SZ - 1
    call    read_line_stdin
    cmp     rax, 0
    jle     .exit

    movzx   eax, byte [user_buf]
    cmp     al, '0'
    je      .do_quit
    cmp     al, '1'
    je      .do_login
    cmp     al, '2'
    je      .do_list
    cmp     al, '3'
    je      .do_search
    cmp     al, '4'
    je      .do_info
    cmp     al, '5'
    je      .do_reserve
    cmp     al, '6'
    je      .do_return
    cmp     al, '7'
    je      .do_myloans
    cmp     al, '8'
    je      .do_rate
    cmp     al, '9'
    je      .do_review_get
    cmp     al, 'a'
    je      .do_add_review
    cmp     al, 'r'
    je      .do_register

    lea     rdi, [str_invalid_choice]
    call    print_str
    jmp     .main_loop


.do_quit:
    call    cmd_quit
    jmp     .exit


.do_login:
    lea     rdi, [str_ask_reader_id]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 32
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_login_sp]
    call    strbuild_start          
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_response
    jmp     .main_loop


.do_list:
    lea     rdi, [scmd_list_nl]
    call    send_cmd
    call    recv_print_multiline
    jmp     .main_loop


.do_search:
    lea     rdi, [str_ask_query]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 128
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_search_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_multiline
    jmp     .main_loop


.do_info:
    lea     rdi, [str_ask_book_id]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 16
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_info_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_response
    jmp     .main_loop

.do_reserve:
    lea     rdi, [str_ask_book_id]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 16
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_reserve_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_response
    jmp     .main_loop


.do_return:
    lea     rdi, [str_ask_book_id]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 16
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_return_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_response
    jmp     .main_loop


.do_myloans:
    lea     rdi, [scmd_myloans_nl]
    call    send_cmd
    call    recv_print_multiline
    jmp     .main_loop


.do_rate:
    lea     rdi, [str_ask_book_id]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 16
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_rate_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, ' '
    call    append_char
    push    rax

    lea     rdi, [str_ask_rating]
    call    print_str
    lea     rdi, [arg_buf2]
    mov     rsi, 8
    call    read_line_stdin

    pop     rdi
    lea     rsi, [arg_buf2]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_response
    jmp     .main_loop


.do_review_get:
    lea     rdi, [str_ask_book_id]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 16
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_reviews_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_multiline
    jmp     .main_loop


.do_add_review:
    lea     rdi, [str_ask_book_id]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 16
    call    read_line_stdin

    lea     rdi, [str_ask_review_text]
    call    print_str
    lea     rdi, [arg_buf2]
    mov     rsi, 255
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_review_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, ' '
    call    append_char
    mov     rdi, rax
    lea     rsi, [arg_buf2]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_response
    jmp     .main_loop


.do_register:
    lea     rdi, [str_ask_name]
    call    print_str
    lea     rdi, [arg_buf]
    mov     rsi, 63
    call    read_line_stdin

    lea     rdi, [cmd_buf]
    lea     rsi, [scmd_register_sp]
    call    strbuild_start
    mov     rdi, rax
    lea     rsi, [arg_buf]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    lea     rdi, [cmd_buf]
    call    send_cmd
    call    recv_print_response
    jmp     .main_loop

.do_upload:
.do_download:
    jmp     .main_loop

.conn_fail:
    lea     rdi, [err_connect]
    call    print_str

.exit:
    mov     eax, SYS_CLOSE
    mov     edi, [sock_fd]
    syscall
    mov     eax, SYS_EXIT
    xor     edi, edi
    syscall


do_connect:
    push    rbp
    mov     rbp, rsp

    mov     eax, SYS_SOCKET
    mov     edi, AF_INET
    mov     esi, SOCK_STREAM
    xor     edx, edx
    syscall
    cmp     rax, 0
    jl      .fail
    mov     [sock_fd], eax

    mov     word  [srv_addr + 0], AF_INET
    mov     ax, SERVER_PORT
    xchg    ah, al
    mov     word  [srv_addr + 2], ax
    mov     dword [srv_addr + 4], LOOPBACK_BE

    mov     eax, SYS_CONNECT
    mov     edi, [sock_fd]
    lea     rsi, [srv_addr]
    mov     edx, 16
    syscall
    cmp     rax, 0
    jl      .fail

    xor     eax, eax
    jmp     .ret
.fail:
    mov     eax, -1
.ret:
    pop     rbp
    ret


cmd_quit:
    lea     rdi, [scmd_quit_nl]
    call    send_cmd
    call    recv_print_response
    ret


send_cmd:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi
    call    strlen
    mov     rdx, rax

    mov     eax, SYS_SENDTO
    mov     edi, [sock_fd]
    mov     rsi, rbx
    ; rdx already set
    xor     r10d, r10d
    xor     r8d, r8d
    xor     r9d, r9d
    syscall

    pop     rbx
    pop     rbp
    ret

recv_print_response:
    push    rbp
    mov     rbp, rsp

    lea     rdi, [in_buf]
    mov     rsi, IN_BUF_SZ - 1
    mov     edx, [sock_fd]      
    call    recv_line_from

    cmp     rax, 0
    jle     .ret

    lea     rdi, [in_buf]
    call    print_str
    lea     rdi, [str_nl]
    call    print_str

.ret:
    pop     rbp
    ret


recv_print_multiline:
    push    rbp
    mov     rbp, rsp
    push    rbx

.loop:
    lea     rdi, [in_buf]
    mov     rsi, IN_BUF_SZ - 1
    mov     edx, [sock_fd]     
    call    recv_line_from

    cmp     rax, 0
    jle     .done

    lea     rdi, [in_buf]
    lea     rsi, [str_end]
    mov     rdx, 3
    call    strncmp_n
    test    rax, rax
    jz      .done


    lea     rdi, [in_buf]
    lea     rsi, [str_err_prefix]
    mov     rdx, 3
    call    strncmp_n
    test    rax, rax
    jz      .print_and_done


    lea     rdi, [in_buf]
    call    print_str
    lea     rdi, [str_nl]
    call    print_str
    jmp     .loop

.print_and_done:
    lea     rdi, [in_buf]
    call    print_str
    lea     rdi, [str_nl]
    call    print_str

.done:
    pop     rbx
    pop     rbp
    ret

show_menu:
    lea     rdi, [str_menu]
    call    print_str
    ret

recv_line_from:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8              
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12, rdi            
    mov     r13, rsi            
    mov     r14d, edx           
    xor     rbx, rbx

.loop:
    cmp     rbx, r13
    jge     .done

    mov     eax, SYS_READ
    mov     edi, r14d
    lea     rsi, [rbp - 8]
    mov     edx, 1
    syscall
    cmp     rax, 0
    jle     .done

    movzx   eax, byte [rbp - 8]
    cmp     al, 10
    je      .done
    cmp     al, 13
    je      .loop

    mov     [r12 + rbx], al
    inc     rbx
    jmp     .loop

.done:
    mov     byte [r12 + rbx], 0
    mov     rax, rbx

    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    add     rsp, 8
    pop     rbp
    ret


read_line_stdin:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi
    mov     r13, rsi
    xor     rbx, rbx

.loop:
    cmp     rbx, r13
    jge     .done

    mov     eax, SYS_READ
    mov     edi, 0              
    lea     rsi, [rbp - 8]
    mov     edx, 1
    syscall
    cmp     rax, 0
    jle     .done

    movzx   eax, byte [rbp - 8]
    cmp     al, 10
    je      .done
    cmp     al, 13
    je      .loop

    mov     [r12 + rbx], al
    inc     rbx
    jmp     .loop

.done:
    mov     byte [r12 + rbx], 0
    mov     rax, rbx

    pop     r13
    pop     r12
    pop     rbx
    add     rsp, 8
    pop     rbp
    ret


strbuild_start:
    jmp     append_str          


strlen:
    xor     eax, eax
.loop:
    cmp     byte [rdi + rax], 0
    je      .done
    inc     rax
    jmp     .loop
.done:
    ret

strncmp_n:
    xor     eax, eax
    test    rdx, rdx
    jz      .done
.loop:
    movzx   ecx, byte [rdi]
    movzx   eax, byte [rsi]
    sub     eax, ecx
    jnz     .done
    test    ecx, ecx
    jz      .done
    inc     rdi
    inc     rsi
    dec     rdx
    jnz     .loop
.done:
    ret

append_str:
    mov     rax, rdi
.loop:
    movzx   ecx, byte [rsi]
    test    cl, cl
    jz      .done
    mov     [rax], cl
    inc     rax
    inc     rsi
    jmp     .loop
.done:
    ret

append_int:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    push    rbx
    push    r12

    mov     rbx, rdi
    mov     r12, rsi

    test    r12, r12
    jnz     .nonzero
    mov     byte [rbx], '0'
    inc     rbx
    jmp     .done

.nonzero:
    lea     rdi, [rbp - 1]
    mov     byte [rdi], 0
    xor     ecx, ecx
    mov     rax, r12

.digit:
    xor     rdx, rdx
    mov     r8, 10
    div     r8
    add     dl, '0'
    dec     rdi
    mov     [rdi], dl
    inc     ecx
    test    rax, rax
    jnz     .digit

    mov     rsi, rdi
    mov     rdi, rbx
    rep     movsb
    mov     rbx, rdi

.done:
    mov     rax, rbx
    pop     r12
    pop     rbx
    add     rsp, 24
    pop     rbp
    ret

append_char:
    mov     [rdi], sil
    lea     rax, [rdi + 1]
    ret

parse_int:
    xor     eax, eax
.loop:
    movzx   ecx, byte [rdi]
    sub     ecx, '0'
    jl      .done
    cmp     ecx, 9
    jg      .done
    imul    rax, 10
    add     rax, rcx
    inc     rdi
    jmp     .loop
.done:
    ret

print_str:
    push    rbp
    mov     rbp, rsp
    push    rbx
    mov     rbx, rdi
    call    strlen
    mov     edx, eax
    mov     eax, SYS_WRITE
    mov     edi, 1
    mov     rsi, rbx
    syscall
    pop     rbx
    pop     rbp
    ret


segment readable writable

sock_fd     dd 0
srv_addr    rb 16

; Буферы
in_buf          rb IN_BUF_SZ
cmd_buf         rb IN_BUF_SZ
user_buf        rb 64
arg_buf         rb 256
arg_buf2        rb 256


scmd_quit_nl     db 'QUIT', 10, 0
scmd_list_nl     db 'LIST', 10, 0
scmd_myloans_nl  db 'MYLOANS', 10, 0
scmd_login_sp    db 'LOGIN ', 0
scmd_search_sp   db 'SEARCH ', 0
scmd_info_sp     db 'INFO ', 0
scmd_reserve_sp  db 'RESERVE ', 0
scmd_return_sp   db 'RETURN ', 0
scmd_rate_sp     db 'RATE ', 0
scmd_review_sp   db 'REVIEW ', 0
scmd_reviews_sp  db 'REVIEWS ', 0
scmd_register_sp db 'REGISTER ', 0


str_menu    db 10
            db '╔══════════════════════════════════════╗', 10
            db '║   Online Library — Главное меню      ║', 10
            db '╠══════════════════════════════════════╣', 10
            db '║  r - Зарегистрироваться (REGISTER)   ║', 10
            db '║  1 - Войти (LOGIN)                   ║', 10
            db '║  2 - Список книг (LIST)               ║', 10
            db '║  3 - Поиск (SEARCH)                  ║', 10
            db '║  4 - Инфо о книге (INFO)              ║', 10
            db '║  5 - Взять книгу (RESERVE)            ║', 10
            db '║  6 - Вернуть книгу (RETURN)           ║', 10
            db '║  7 - Мои абонементы (MYLOANS)         ║', 10
            db '║  8 - Оценить книгу (RATE)             ║', 10
            db '║  9 - Отзывы о книге (REVIEWS)         ║', 10
            db '║  a - Написать отзыв (REVIEW)          ║', 10
            db '║  0 - Выйти (QUIT)                    ║', 10
            db '╚══════════════════════════════════════╝', 10
            db 'Выбор: ', 0

str_ask_reader_id   db 'Введите ID читателя: ', 0
str_ask_book_id     db 'Введите ID книги: ', 0
str_ask_query       db 'Поисковый запрос: ', 0
str_ask_rating      db 'Оценка (1-5): ', 0
str_ask_review_text db 'Текст отзыва: ', 0
str_ask_name        db 'Ваше имя: ', 0
str_invalid_choice  db 'Неверный выбор.', 10, 0
err_connect         db 'ОШИБКА: Не удалось подключиться к серверу (127.0.0.1:8080)', 10, 0

str_nl         db 10, 0
str_end        db 'END', 0
str_err_prefix db 'ERR', 0
