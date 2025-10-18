format ELF64
public _start

section '.data' writable
    prompt_n       db "Enter n: ", 0
    result_msg     db "Prime numbers ending with 1: ", 0
    newline        db 10, 0
    space          db " ", 0
    
    n_buffer       rb 32
    number_buffer  rb 32
    
    n_value        dq 0

section '.text' executable
_start:
    ; Запрос ввода n
    mov rax, prompt_n
    call print_string
    
    mov rax, n_buffer
    mov rbx, 32
    call read_string
    call string_to_int
    mov [n_value], rax
    
    ; Выводим результат
    mov rax, result_msg
    call print_string
    
    ; Ищем и выводим простые числа, заканчивающиеся на 1
    mov r9, 2
.find_loop:
    mov rax, r9
    cmp rax, [n_value]
    jg .exit
    
    ; Проверяем на простоту
    call is_prime
    test rax, rax
    jz .next
    
    ; Проверяем, заканчивается ли на 1
    mov rax, r9
    mov rbx, 10
    xor rdx, rdx
    div rbx
    cmp rdx, 1
    jne .next
    
    ; Выводим число
    mov rax, r9
    call int_to_string
    
    mov rax, 1
    mov rdi, 1
    mov rsi, number_buffer
    mov rdx, r10
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, space
    mov rdx, 1
    syscall

.next:
    inc r9
    jmp .find_loop

.exit:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall

; Функция проверки числа на простоту
; Вход: число в r9
; Выход: rax = 1 если простое, 0 если нет
is_prime:
    cmp r9, 1
    jle .not_prime
    cmp r9, 2
    je .prime
    
    ; Проверяем делимость на 2
    mov rax, r9
    and rax, 1
    jz .not_prime
    
    ; Проверяем нечетные делители от 3 до sqrt(n)
    mov rbx, 3
.check_loop:
    ; Проверяем rbx * rbx <= r9
    mov rax, rbx
    mul rax
    cmp rax, r9
    jg .prime
    
    ; Проверяем делимость r9 на rbx
    mov rax, r9
    xor rdx, rdx
    div rbx
    cmp rdx, 0
    je .not_prime
    
    add rbx, 2
    jmp .check_loop

.prime:
    mov rax, 1
    ret

.not_prime:
    xor rax, rax
    ret

; Функция преобразования строки в число
; Вход: строка в rax
; Выход: число в rax
string_to_int:
    xor rbx, rbx    ; обнуляем результат
.next_char:
    mov cl, [rax]   ; читаем символ
    cmp cl, 0       ; конец строки?
    je .done
    cmp cl, 10      ; символ новой строки?
    je .done
    
    sub cl, '0'     ; преобразуем в цифру
    imul rbx, 10    ; умножаем результат на 10
    add rbx, rcx    ; добавляем цифру
    inc rax         ; следующий символ
    jmp .next_char
.done:
    mov rax, rbx
    ret

; Функция преобразования числа в строку
; Вход: число в rax
; Выход: строка в number_buffer, длина в r10
int_to_string:
    mov rdi, number_buffer + 31  ; конец буфера
    mov byte [rdi], 0            ; нулевой терминатор
    mov rbx, 10                  ; делитель
    mov r10, 0                   ; счетчик цифр
    
    test rax, rax
    jnz .convert_loop
    ; Особый случай: число 0
    dec rdi
    mov byte [rdi], '0'
    inc r10
    jmp .copy_result
    
.convert_loop:
    xor rdx, rdx
    div rbx          ; rax = quotient, rdx = remainder
    add dl, '0'      ; преобразуем в символ
    dec rdi
    mov [rdi], dl
    inc r10
    test rax, rax
    jnz .convert_loop
    
.copy_result:
    ; Копируем результат в начало буфера
    mov rsi, rdi
    mov rdi, number_buffer
    mov rcx, r10
    rep movsb
    mov byte [number_buffer + r10], 0
    ret

; Функция вычисления длины строки
; Вход: строка в rax
; Выход: длина в rax
string_length:
    mov rsi, rax
    xor rax, rax
.loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

; Функция вывода строки
; Вход: строка в rax
print_string:
    push rax
    call string_length
    mov rdx, rax    ; длина
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    pop rsi         ; строка
    syscall
    ret

; Функция чтения строки
; Вход: буфер в rax, размер в rbx
; Выход: строка в буфере
read_string:
    mov rsi, rax    ; буфер
    mov rdx, rbx    ; размер
    mov rax, 0      ; sys_read
    mov rdi, 0      ; stdin
    syscall
    
    ; Убираем символ новой строки
    cmp rax, 0
    jle .done
    mov rcx, rax
    dec rcx
    mov byte [rsi + rcx], 0
.done:
    ret