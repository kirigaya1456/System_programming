format ELF64
public _start

section '.data' writeable
    ; Константы
    const_four    dq 4.0
    const_one     dq 1.0
    const_two     dq 2.0
    const_three   dq 3.0
    abs_mask      dq 0x7FFFFFFFFFFFFFFF

    ; Тестовые значения x (должны быть в диапазоне -1 < x < 1)
    x_values      dq 0.1, 0.3, 0.5, 0.7, 0.9, -0.2, -0.4, -0.6, -0.8
    x_count       equ 9

    ; Значения точности (epsilon)
    eps_values    dq 1e-4, 1e-6, 1e-8, 1e-10, 1e-12
    eps_count     equ 5

    ; Строки для вывода
    header        db "x",9,"epsilon",9,"terms",10
    header_len    equ $ - header
    
    error_msg     db "Error: |x| must be < 1, got "
    error_len     equ $ - error_msg
    
    newline       db 10
    
    ; Буферы для преобразования чисел в строки
    x_buffer      times 20 db 0
    eps_buffer    times 20 db 0
    int_buffer    times 20 db 0
    
    ; Таблицы для вывода знаков
    digits        db "0123456789"

section '.text' executable

; Функция для вычисления абсолютного значения
fabs_sse2:
    movq    rax, xmm0
    and     rax, [abs_mask]
    movq    xmm0, rax
    ret

; Функция преобразования double в строку
; Вход: xmm0 = число, rdi = буфер
double_to_string:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    
    ; Проверяем знак
    movq    rax, xmm0
    test    rax, 0x8000000000000000
    jz      .positive
    
    ; Отрицательное число
    mov     byte [rdi], '-'
    inc     rdi
    and     rax, [abs_mask]
    movq    xmm0, rax
    
.positive:
    ; Преобразуем в целое и дробную части
    cvttsd2si r12, xmm0      ; целая часть
    cvtsi2sd xmm1, r12       ; обратно в double
    subsd   xmm0, xmm1       ; дробная часть
    
    ; Преобразуем целую часть в строку
    mov     rax, r12
    call    int_to_string
    
    ; Добавляем точку
    mov     byte [rdi], '.'
    inc     rdi
    
    ; Преобразуем дробную часть (2 знака)
    movsd   xmm1, [const_one]
    mulsd   xmm0, xmm1
    mulsd   xmm0, [const_one]
    mulsd   xmm0, [const_one] ; умножаем на 100
    cvttsd2si rax, xmm0
    
    ; Преобразуем два знака после запятой
    xor     rdx, rdx
    mov     rbx, 10
    div     rbx
    add     dl, '0'
    mov     [rdi+1], dl
    mov     byte [rdi], '0'
    add     al, '0'
    cmp     al, '0'
    je      .skip_first
    mov     [rdi], al
.skip_first:
    add     rdi, 2
    
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

; Функция преобразования целого числа в строку
; Вход: rax = число, rdi = буфер
int_to_string:
    push    rbp
    mov     rbp, rsp
    push    rbx
    
    mov     rbx, rdi
    test    rax, rax
    jns     .positive_int
    
    ; Отрицательное число
    mov     byte [rdi], '-'
    inc     rdi
    neg     rax
    
.positive_int:
    mov     rcx, rdi
    
.convert_loop:
    xor     rdx, rdx
    mov     r8, 10
    div     r8
    add     dl, '0'
    mov     [rdi], dl
    inc     rdi
    test    rax, rax
    jnz     .convert_loop
    
    ; Переворачиваем строку
    mov     byte [rdi], 0
    dec     rdi
    
.reverse_loop:
    cmp     rcx, rdi
    jae     .done
    mov     al, [rcx]
    mov     bl, [rdi]
    mov     [rdi], al
    mov     [rcx], bl
    inc     rcx
    dec     rdi
    jmp     .reverse_loop
    
.done:
    pop     rbx
    pop     rbp
    ret

; Функция вывода строки
; Вход: rsi = строка, rdx = длина
print_string:
    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    syscall
    ret

; Функция вычисления ряда
; Вход: xmm0 = x, xmm1 = epsilon
; Выход: rax = количество членов ряда
compute_series:
    ; Проверяем, что |x| < 1
    movsd   xmm2, xmm0
    call    fabs_sse2
    comisd  xmm0, [const_one]
    movsd   xmm0, xmm2
    jae     .error
    
    ; Инициализация
    xorpd   xmm2, xmm2        ; сумма ряда
    mov     rax, 0            ; счетчик членов
    movsd   xmm3, xmm0        ; текущий член
    movsd   xmm4, xmm0        ; x
    mulsd   xmm4, xmm4        ; x^2
    mulsd   xmm4, xmm4        ; x^4

.loop:
    ; Добавляем текущий член к сумме
    addsd   xmm2, xmm3
    inc     rax
    
    ; Проверяем условие выхода |current| < epsilon
    movsd   xmm5, xmm3
    call    fabs_sse2
    comisd  xmm0, xmm1
    jb      .done
    
    ; Вычисляем следующий член: next = current * x^4 * (4n+1)/(4n+5)
    ; Вычисляем (4n+1)/(4n+5)
    mov     rcx, rax          ; n+1
    dec     rcx               ; n
    imul    rcx, rcx, 4       ; 4n
    lea     rdx, [rcx + 1]    ; 4n+1
    lea     rbx, [rcx + 5]    ; 4n+5
    
    cvtsi2sd xmm5, rdx
    cvtsi2sd xmm6, rbx
    divsd   xmm5, xmm6        ; (4n+1)/(4n+5)
    
    ; Умножаем на x^4 и текущий член
    mulsd   xmm5, xmm4
    mulsd   xmm5, xmm3
    movsd   xmm3, xmm5        ; обновляем текущий член
    
    jmp     .loop

.done:
    ret

.error:
    mov     rax, -1
    ret

_start:
    ; Вывод заголовка таблицы
    mov     rsi, header
    mov     rdx, header_len
    call    print_string
    
    ; Сохраняем регистры
    push    r12
    push    r13
    push    r14
    push    r15
    
    ; Цикл по значениям x
    mov     r12, x_values
    xor     r13, r13          ; индекс x

.x_loop:
    cmp     r13, x_count
    jge     .x_done
    
    ; Цикл по значениям точности
    mov     r14, eps_values
    xor     r15, r15          ; индекс epsilon

.eps_loop:
    cmp     r15, eps_count
    jge     .eps_done
    
    ; Загружаем x и epsilon
    movsd   xmm0, [r12 + r13*8]
    movsd   xmm1, [r14 + r15*8]
    
    ; Вычисляем ряд
    call    compute_series
    
    ; Проверяем результат
    cmp     rax, -1
    je      .error
    
    ; Выводим x
    movsd   xmm0, [r12 + r13*8]
    mov     rdi, x_buffer
    call    double_to_string
    
    mov     rsi, x_buffer
    mov     rdx, 0
.calc_x_len:
    cmp     byte [rsi + rdx], 0
    je      .x_len_done
    inc     rdx
    jmp     .calc_x_len
.x_len_done:
    call    print_string
    
    ; Выводим табуляцию
    mov     byte [x_buffer], 9
    mov     rsi, x_buffer
    mov     rdx, 1
    call    print_string
    
    ; Выводим epsilon
    movsd   xmm0, [r14 + r15*8]
    mov     rdi, eps_buffer
    
    ; Простое преобразование epsilon (упрощенное)
    mov     rax, [r14 + r15*8]
    cmp     rax, 0x3F1A36E2EB1C432D   ; 1e-4
    je      .eps1
    cmp     rax, 0x3EE4F8B588E368F1   ; 1e-6
    je      .eps2
    cmp     rax, 0x3E7AD7F29ABCAF48   ; 1e-8
    je      .eps3
    cmp     rax, 0x3E0D826A140A400C   ; 1e-10
    je      .eps4
    mov     rsi, eps_12
    mov     rdx, 5
    jmp     .print_eps
    
.eps1:
    mov     rsi, eps_4
    mov     rdx, 4
    jmp     .print_eps
.eps2:
    mov     rsi, eps_6
    mov     rdx, 4
    jmp     .print_eps
.eps3:
    mov     rsi, eps_8
    mov     rdx, 4
    jmp     .print_eps
.eps4:
    mov     rsi, eps_10
    mov     rdx, 6
    
.print_eps:
    call    print_string
    
    ; Выводим табуляцию
    mov     byte [x_buffer], 9
    mov     rsi, x_buffer
    mov     rdx, 1
    call    print_string
    
    ; Выводим количество членов
    mov     rdi, int_buffer
    call    int_to_string
    
    mov     rsi, int_buffer
    mov     rdx, 0
.calc_int_len:
    cmp     byte [rsi + rdx], 0
    je      .int_len_done
    inc     rdx
    jmp     .calc_int_len
.int_len_done:
    call    print_string
    
    ; Выводим новую строку
    mov     rsi, newline
    mov     rdx, 1
    call    print_string
    
    jmp     .next_eps
    
.error:
    ; Выводим сообщение об ошибке
    mov     rsi, error_msg
    mov     rdx, error_len
    call    print_string
    
    ; Выводим значение x
    movsd   xmm0, [r12 + r13*8]
    mov     rdi, x_buffer
    call    double_to_string
    
    mov     rsi, x_buffer
    mov     rdx, 0
.calc_err_len:
    cmp     byte [rsi + rdx], 0
    je      .err_len_done
    inc     rdx
    jmp     .calc_err_len
.err_len_done:
    call    print_string
    
    ; Выводим новую строку
    mov     rsi, newline
    mov     rdx, 1
    call    print_string

.next_eps:
    inc     r15
    jmp     .eps_loop

.eps_done:
    inc     r13
    jmp     .x_loop

.x_done:
    ; Восстанавливаем регистры
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    
    ; Завершение программы
    mov     rax, 60          ; sys_exit
    xor     rdi, rdi         ; код возврата 0
    syscall

section '.data' writeable
    ; Строки для epsilon (для упрощенного вывода)
    eps_4     db "1e-4"
    eps_6     db "1e-6"
    eps_8     db "1e-8"
    eps_10    db "1e-10"
    eps_12    db "1e-12"