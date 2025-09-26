format ELF64

section '.data' writeable
    N db '5277616985',0
    newline db 10

section '.bss' writeable
    output rb 20

section '.text' executable
public _start

_start:
    ; Вычисляем сумму цифр
    xor eax, eax       
    mov esi, N          ]
    mov ecx, 10         ]

digit_sum:
    movzx ebx, byte [esi]
    sub ebx, '0'        ]
    add eax, ebx       ]
    inc esi
    loop digit_sum

    mov edi, output + 19
    mov byte [edi], 0
    mov ebx, 10

int_to_str:
    dec edi
    xor edx, edx
    div ebx             
    add dl, '0'         
    mov [edi], dl
    test eax, eax
    jnz int_to_str

    ; Вычисляем длину
    mov esi, edi
    mov edx, output + 19
    sub edx, edi

    ; Выводим результат
    mov eax, 1
    mov edi, 1
    syscall

    ; Новая строка
    mov eax, 1
    mov edi, 1
    mov esi, newline
    mov edx, 1
    syscall

exit:
    mov eax, 60
    xor edi, edi
    syscall