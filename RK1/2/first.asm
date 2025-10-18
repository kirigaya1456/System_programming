format ELF64
public _start

section '.data' writable
    usage db 'Usage: program <2n+1>', 0xA, 0
    usage_len = $ - usage
    result db 'Sum = ', 0
    result_len = $ - result
    newline db 0xA, 0
    buffer rb 20

section '.text' executable
_start:
    pop rcx              
    cmp rcx, 2
    jne .show_usage

    pop rsi                
    pop rsi                

    xor rax, rax
    xor rcx, rcx
    mov rdi, rsi

.string_to_number:
    mov cl, [rdi]
    cmp cl, 0
    je .calculate_n
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rdi
    jmp .string_to_number

.calculate_n:
    dec rax                 
    shr rax, 1             

    inc rax                 
    mov rbx, rax           
    imul rax, rax          
    mov r8, rax     

    mov rax, 1            
    mov rdi, 1              
    mov rsi, result
    mov rdx, result_len
    syscall

    mov rax, r8
    mov rdi, buffer
    call .number_to_string

    mov rax, 1              
    mov rdi, 1              
    mov rsi, buffer
    mov rdx, rcx           
    syscall

    mov rax, 1            
    mov rdi, 1            
    mov rsi, newline
    mov rdx, 1
    syscall

    jmp .exit

.show_usage:
    mov rax, 1         
    mov rdi, 1              
    mov rsi, usage
    mov rdx, usage_len
    syscall

.exit:
    mov rax, 60          
    xor rdi, rdi         
    syscall


.number_to_string:
    mov rbx, 10            
    mov rcx, 0
    mov rsi, rdi

    test rax, rax
    jnz .convert_loop
    mov byte [rdi], '0'
    mov rcx, 1
    ret

.convert_loop:
    xor rdx, rdx
    div rbx                 
    add dl, '0'         
    push rdx                
    inc rcx
    test rax, rax
    jnz .convert_loop

    mov rdi, rsi
.reverse_loop:
    pop rax
    mov [rdi], al
    inc rdi
    loop .reverse_loop

    mov byte [rdi], 0      
    mov rcx, rdi
    sub rcx, rsi         
    ret