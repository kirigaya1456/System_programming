format ELF64

section '.data' writeable
    usage db 'Usage: ./a.out n',0xA,0
    result_msg db 'Result: ',0
    newline db 0xA

section '.bss' writeable
    result dd 0
    n dd 0
    buffer rb 32

section '.text' executable
public _start

_start:
    pop rcx
    cmp rcx, 2
    jne show_usage

    pop rsi
    pop rsi
    
    xor rax, rax
    xor rcx, rcx
    mov rdi, rsi
    
convert_loop:
    movzx rdx, byte [rdi]
    test rdx, rdx
    jz convert_done
    
    cmp rdx, '0'
    jb show_usage
    cmp rdx, '9'
    ja show_usage
    
    sub rdx, '0'
    imul rax, rax, 10
    add rax, rdx
    
    inc rdi
    jmp convert_loop

convert_done:
    mov [n], eax

    mov ecx, [n]
    xor eax, eax
    mov ebx, 1
    mov edx, 1

calc_loop:
    cmp ebx, ecx
    jg done

    mov esi, ebx
    imul esi, edx
    add eax, esi

    test ebx, 1
    jnz next
    neg edx

next:
    inc ebx
    jmp calc_loop

done:
    mov [result], eax

    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, 8
    syscall

    mov eax, [result]
    mov rdi, buffer
    call int_to_string

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

    mov rax, 60
    xor rdi, rdi
    syscall

show_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, usage
    mov rdx, 16
    syscall
    
    mov rax, 60
    mov rdi, 1
    syscall

int_to_string:
    mov rbx, 10
    mov rcx, 0
    mov rsi, rdi

    test rax, rax
    jnz convert
    mov byte [rdi], '0'
    inc rdi
    mov rcx, 1
    ret

convert:
    xor rdx, rdx
    div rbx
    add dl, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz convert

reverse:
    pop rax
    mov [rdi], al
    inc rdi
    loop reverse
    
    mov byte [rdi], 0
    mov rcx, rdi
    sub rcx, rsi
    ret