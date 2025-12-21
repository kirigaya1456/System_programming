format elf64
public _start

extrn printf

section '.data' writeable
    fmt_table_header    db " Точность    Члены ряда   Члены дроби ", 0xa,0
    
    fmt_table_row       db " %-10.0e  %-11d  %-11d ", 0xa, 0
    
    fmt_e_series        db "e (ряд)    = %.15f", 0xa, 0
    fmt_e_fraction      db "e (дробь)  = %.15f", 0xa, 0
    fmt_math_e          db "math.h e   = %.15f", 0xa, 0
    
    newline             db 0xa, 0
    
    precisions dq 1.0e-1, 1.0e-2, 1.0e-3, 1.0e-4, 1.0e-5, 1.0e-6, 1.0e-7, 1.0e-8
    prec_count = ($ - precisions) / 8
    
    one      dq 1.0
    two      dq 2.0
    math_e   dq 2.718281828459045
    abs_mask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF ; маска для взятия модуля (2x64 бита)
    
section '.bss' writeable
    e_series     rq 1
    e_fraction   rq 1
    terms_series   rd 1
    terms_fraction rd 1
    depth       rd 1
    current_n   rd 1
    prev_e      rq 1
    
section '.text' executable

; ============================================
; Функция вычисления e через ряд
; ============================================
compute_e_series:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    
    movq [rbp-8], xmm0    ; сохраняем точность
    finit
    
    fld qword [two]       ; e = 2.0
    fld1                  ; term = 1.0
    mov dword [current_n], 1
    mov dword [terms_series], 0
    
.series_loop:
    inc dword [current_n]
    fild dword [current_n] ; st(0) = n, st(1) = term, st(2) = e
    fdivp st1, st0        ; st(0) = term/n, st(1) = e
    
    ; Проверяем точность
    fld st0               ; копируем term
    fabs                  ; |term|
    fcomp qword [rbp-8]   ; сравниваем с точностью
    fstsw ax
    sahf
    jb .series_done
    
    ; Добавляем term к e
    fadd st1, st0
    inc dword [terms_series]
    
    ; Проверяем максимум итераций
    cmp dword [terms_series], 1000
    jl .series_loop
    
.series_done:
    fstp st0              ; удаляем term
    fstp qword [e_series] ; сохраняем e
    
    movq xmm0, [e_series]
    add rsp, 16
    pop rbp
    ret

; ============================================
; Функция цепной дроби
; ============================================
compute_e_fraction_adaptive_real:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    ; Сохраняем точность
    movq [rbp-8], xmm0
    movq [rbp-16], xmm0   ; копия для FPU
    
    ; Начинаем с небольшой глубины
    mov dword [depth], 2
    mov dword [terms_fraction], 0
    
    ; Инициализируем предыдущее значение
    fld qword [two]       ; начальное приближение e = 2
    fstp qword [prev_e]
    
.fraction_convergence_loop:
    ; Вычисляем цепную дробь текущей глубины
    finit
    
    ; Начинаем с конца: значение на глубине depth+1 = 0
    fldz                  ; st(0) = 0.0
    
    ; Выполняем depth шагов снизу вверх
    mov ecx, [depth]
    mov [current_n], ecx  ; начинаем с n = depth
    
.inner_compute_loop:
    ; x = n / (n + x)
    fild dword [current_n] ; st(0) = n, st(1) = x
    fld st0               ; st(0) = n, st(1) = n, st(2) = x
    fadd st0, st2         ; st(0) = n + x, st(1) = n, st(2) = x
    fdivp st1, st0        ; st(0) = n/(n+x), st(1) = x
    fstp st1              ; st(0) = новое x
    
    ; Уменьшаем n
    dec dword [current_n]
    cmp dword [current_n], 1
    jg .inner_compute_loop
    
    ; После цикла добавляем 2: e = 2 + x
    fld qword [two]
    faddp st1, st0        ; st(0) = e
    
    ; Сохраняем текущее значение
    fst qword [e_fraction]
    fst qword [rbp-24]    ; временное хранение
    
    ; Проверяем сходимость
    cmp dword [terms_fraction], 0
    je .first_iteration
    
    ; Вычисляем |текущее - предыдущее|
    fld qword [prev_e]    ; st(0) = предыдущее, st(1) = текущее
    fsub st0, st1         ; st(0) = разница
    fabs

; st(0) = |разница|
    
    ; Сравниваем с требуемой точностью
    fcomp qword [rbp-16]
    fstsw ax
    sahf
    jb .converged         ; если |разница| < точности, сошлось
    
    ; Очищаем стек
    fstp st0              ; удаляем текущее значение
    
.first_iteration:
    ; Сохраняем текущее как предыдущее для следующей итерации
    fld qword [rbp-24]
    fstp qword [prev_e]
    
    ; Увеличиваем глубину
    inc dword [depth]
    inc dword [terms_fraction]
    
    ; Проверяем максимальную глубину
    cmp dword [depth], 50
    jl .fraction_convergence_loop
    
.converged:
    ; Корректируем счетчик (добавляем 1 для текущей итерации)
    inc dword [terms_fraction]
    
    ; Загружаем результат
    fld qword [e_fraction]
    fstp qword [e_fraction]
    
    movq xmm0, [e_fraction]
    add rsp, 48
    pop rbp
    ret


; ============================================
; Основная программа
; ============================================
_start:
    
    
    ; Выводим заголовок таблицы
    mov rdi, fmt_table_header
    xor rax, rax
    call printf
    
    ; Перебираем все точности
    mov rbx, precisions
    mov r12, prec_count
    
.precision_loop:
    push rbx
    push r12
    
    ; Вычисляем e через ряд
    movq xmm0, [rbx]
    call compute_e_series
    
    ; Вычисляем e через цепную дробь
    movq xmm0, [rbx]
    call compute_e_fraction_adaptive_real
    
    ; Выводим строку таблицы
    movq xmm0, [rbx]
    mov esi, [terms_series]
    mov edx, [terms_fraction]
    mov rax, 1
    mov rdi, fmt_table_row
    call printf
    
    pop r12
    pop rbx
    
    ; Следующая точность
    add rbx, 8
    dec r12
    jnz .precision_loop
    
    
    ; Выводим финальные значения для самой высокой точности
    movq xmm0, [precisions + 56]  ; 1e-8
    call compute_e_series
    mov rdi, fmt_e_series
    mov rax, 1
    call printf
    
    movq xmm0, [precisions + 56]
    call compute_e_fraction_adaptive_real
    mov rdi, fmt_e_fraction
    mov rax, 1
    call printf
    
    
    ; Завершение программы
    mov rax, 60
    xor rdi, rdi
    syscall