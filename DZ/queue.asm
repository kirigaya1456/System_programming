format ELF64

; --- Публичные функции ---
public queue_create
public queue_push
public queue_pop
public queue_fill_random
public queue_get_odds
public queue_filter_evens
public queue_count_end_1
public queue_destroy

; --- Константы системных вызовов Linux x64 ---
SYS_MMAP    equ 9
SYS_MUNMAP  equ 11
SYS_GETPID  equ 39    ; Используем PID как зерно для random

; --- Параметры mmap ---
PROT_READ   equ 1
PROT_WRITE  equ 2
MAP_PRIVATE equ 2
MAP_ANON    equ 32

; --- Параметры аллокатора ---
HEAP_SIZE   equ 1024 * 1024 ; 1 МБ памяти под очередь (упрощенно)

section '.data' writeable
    ; Глобальные переменные для нашего простого аллокатора
    heap_base   dq 0    ; Начало нашего региона памяти
    heap_ptr    dq 0    ; Текущий указатель свободной памяти
    heap_end    dq 0    ; Конец региона

    ; Для генератора случайных чисел
    rand_seed   dq 12345

section '.text' executable

; ==========================================================
; Внутренняя функция: my_malloc
; Выделяет память из нашего региона mmap
; Вход: RDI = размер
; Выход: RAX = указатель
; ==========================================================
my_malloc:
    push rbx
    mov rbx, rdi            ; Сохраняем требуемый размер

    ; Если база 0, значит нужно инициализировать кучу
    cmp qword [heap_base], 0
    jne .alloc

    ; --- Инициализация (mmap) ---
    ; syscall mmap(0, HEAP_SIZE, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANON, -1, 0)
    mov rax, SYS_MMAP
    xor rdi, rdi            ; addr = NULL
    mov rsi, HEAP_SIZE      ; length
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_PRIVATE or MAP_ANON
    mov r8, -1              ; fd
    xor r9, r9              ; offset
    syscall

    ; Проверка на ошибку (отрицательный результат)
    test rax, rax
    js .error

    mov [heap_base], rax
    mov [heap_ptr], rax
    add rax, HEAP_SIZE
    mov [heap_end], rax

.alloc:
    ; Выделение по принципу Bump Pointer
    mov rax, [heap_ptr]     ; Текущий свободный адрес (результат)
    mov rdx, rax
    add rdx, rbx            ; Новый свободный адрес = старый + размер
    
    cmp rdx, [heap_end]     ; Проверка на переполнение
    ja .error               ; Если места нет (в реальном коде нужен new mmap)

    mov [heap_ptr], rdx     ; Сохраняем новый указатель
    pop rbx
    ret

.error:
    xor rax, rax            ; Вернуть NULL
    pop rbx
    ret

; ==========================================================
; Внутренняя функция: my_rand
; Простой LCG: seed = seed * 6364136223846793005 + 1
; Выход: RAX = случайное число
; ==========================================================
my_rand:
    mov rax, [rand_seed]
    mov rdx, 6364136223846793005
    mul rdx
    add rax, 1
    mov [rand_seed], rax
    ret

; ==========================================================
; 1. Создание очереди
; ==========================================================
queue_create:
    push rbp
    mov rbp, rsp
    
    ; Инициализация зерна random через PID (чтобы было разным при запусках)
    mov rax, SYS_GETPID
    syscall
    xor [rand_seed], rax

    ; Выделяем память под структуру Queue (24 байта: head, tail, size)
    mov rdi, 24
    call my_malloc
    
    ; Зануляем поля
    mov qword [rax], 0      ; head
    mov qword [rax+8], 0    ; tail
    mov qword [rax+16], 0   ; size
    
    leave
    ret

; ==========================================================
; 2. Добавление в конец (Enqueue)
; RDI = Queue*, RSI = Value
; ==========================================================
queue_push:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    mov rbx, rdi            ; Queue*
    mov r12, rsi            ; Value
    
    ; Выделяем память под Node (16 байт: 8 val + 8 next)
    mov rdi, 16
    call my_malloc
    test rax, rax
    jz .exit                ; Если память кончилась
    
    mov [rax], r12          ; node->val
    mov qword [rax+8], 0    ; node->next
    
    ; Если очередь пуста
    cmp qword [rbx], 0
    jne .append
    
    mov [rbx], rax          ; head = node
    mov [rbx+8], rax        ; tail = node
    jmp .inc_size

.append:
    mov rdx, [rbx+8]        ; tail
    mov [rdx+8], rax        ; tail->next = node
    mov [rbx+8], rax        ; update tail

.inc_size:
    inc qword [rbx+16]

.exit:
    pop r12
    pop rbx
    leave
    ret

; ==========================================================
; 3. Удаление из начала (Dequeue)
; RDI = Queue*
; Вывод: RAX = val, RDX = success (1) / fail (0)
; ==========================================================
queue_pop:
    push rbp
    mov rbp, rsp
    
    mov rcx, [rdi]          ; head
    test rcx, rcx
    jz .empty
    
    mov rax, [rcx]          ; save val
    mov r8, [rcx+8]         ; next
    mov [rdi], r8           ; head = next
    
    test r8, r8
    jnz .dec_size
    mov qword [rdi+8], 0    ; tail = NULL if empty

.dec_size:
    dec qword [rdi+16]
    ; В simple bump allocator мы не делаем free() для отдельных узлов.
    ; Память "утекает" внутри нашего mmap-блока, что допустимо для учебного примера.
    
    mov rdx, 1
    jmp .done

.empty:
    xor rax, rax
    xor rdx, rdx

.done:
    leave
    ret

; ==========================================================
; 4. Заполнение случайными числами
; RDI = Queue*, RSI = count
; ==========================================================
queue_fill_random:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    mov rbx, rdi
    mov r12, rsi
    
.loop:
    test r12, r12
    jz .done
    
    call my_rand
    ; Ограничим 0..99: abs(rax) % 100
    test rax, rax
    jns .pos
    neg rax
.pos:
    xor rdx, rdx
    mov rcx, 100
    div rcx                 ; rdx = rand % 100
    
    mov rdi, rbx
    mov rsi, rdx
    call queue_push
    
    dec r12
    jmp .loop

.done:
    pop r12
    pop rbx
    leave
    ret

; ==========================================================
; 5. Получение списка нечетных
; RDI = Queue*, RSI = int64_t* buffer
; Вывод: RAX = count
; ==========================================================
queue_get_odds:
    push rbp
    mov rbp, rsp
    
    mov rcx, [rdi]          ; current = head
    mov r8, rsi             ; buffer
    xor rax, rax            ; counter
    
.loop:
    test rcx, rcx
    jz .done
    
    mov r9, [rcx]           ; val
    test r9, 1
    jz .next
    
    mov [r8], r9
    add r8, 8
    inc rax
    
.next:
    mov rcx, [rcx+8]
    jmp .loop
    
.done:
    leave
    ret

; ==========================================================
; 6. Удаление четных (Нечетные переносятся в конец)
; RDI = Queue*
; ==========================================================
queue_filter_evens:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    mov rbx, rdi
    mov r12, [rbx+16]       ; Изначальный размер очереди (цикл)
    
.loop:
    test r12, r12
    jz .done
    
    mov rdi, rbx
    call queue_pop          ; rax = val
    
    test rax, 1
    jz .skip                ; Если четное, просто забываем (удаляем)
    
    ; Если нечетное - возвращаем в очередь
    mov rdi, rbx
    mov rsi, rax
    call queue_push
    
.skip:
    dec r12
    jmp .loop
    
.done:
    pop r12
    pop rbx
    leave
    ret

; ==========================================================
; 7. Подсчет оканчивающихся на 1
; RDI = Queue*
; ==========================================================
queue_count_end_1:
    push rbp
    mov rbp, rsp
    
    mov rcx, [rdi]          ; current
    xor rsi, rsi            ; count
    mov r8, 10              ; делитель
    
.loop:
    test rcx, rcx
    jz .done
    
    mov rax, [rcx]
    test rax, rax
    jns .check
    neg rax                 ; abs()
.check:
    xor rdx, rdx
    div r8                  ; rax % 10
    
    cmp rdx, 1
    jne .next
    inc rsi
    
.next:
    mov rcx, [rcx+8]
    jmp .loop

.done:
    mov rax, rsi
    leave
    ret

; ==========================================================
; 8. Деструктор
; ==========================================================
queue_destroy:
    push rbp
    mov rbp, rsp
    
    ; В нашей простой реализации аллокатора (mmap + bump pointer)
    ; мы не можем освободить отдельные куски.
    ; Мы просто освобождаем весь регион памяти целиком.
    
    cmp qword [heap_base], 0
    je .done
    
    ; syscall munmap(addr, length)
    mov rax, SYS_MUNMAP
    mov rdi, [heap_base]
    mov rsi, HEAP_SIZE
    syscall
    
    mov qword [heap_base], 0
    mov qword [heap_ptr], 0
    
.done:
    leave
    ret