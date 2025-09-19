format ELF64
public _start

msg:
    db "Manukyan", 10
    db "Agasi", 10
    db "Rubenovich", 10
msgEnd:

    msg_len = msgEnd - msg

_start:
    ;инициализация регистров для вывода информации на экран
    mov rax, 4
    mov rbx, 1
    mov rcx, msg
    mov rdx, msg_len
    int 0x80
    ;инициализация регистров для успешного завершения работы программы
    mov rax, 1
    mov rbx, 0
    int 0x80