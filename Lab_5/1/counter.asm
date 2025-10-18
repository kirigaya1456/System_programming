format ELF64
public _start

section '.data' writable
    usage db 'Usage: program <input_file> <output_file>', 0xA, 0
    usage_len = $ - usage
    error_open db 'Error: Cannot open file', 0xA, 0
    error_open_len = $ - error_open
    error_read db 'Error: Cannot read file', 0xA, 0
    error_read_len = $ - error_read
    error_write db 'Error: Cannot write file', 0xA, 0
    error_write_len = $ - error_write
    
    letters_msg db '+ number of letters: ', 0
    letters_len = $ - letters_msg
    digits_msg db '+ number of digits: ', 0
    digits_len = $ - digits_msg
    newline db 0xA, 0
    
    buffer_size equ 4096
    buffer rb buffer_size
    result_buffer rb 100

section '.bss' writable
    input_fd dq 0
    output_fd dq 0
    letters_count dq 0
    digits_count dq 0

section '.text' executable
_start:
    pop rcx
    cmp rcx, 3
    jne .show_usage

    pop rsi
    pop rdi
    mov r12, rdi
    
    pop rdi
    mov r13, rdi

    mov rax, 2
    mov rdi, r12
    mov rsi, 0
    syscall
    cmp rax, 0
    jl .error_open
    mov [input_fd], rax

    mov rax, 2
    mov rdi, r13
    mov rsi, 0x241
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .error_open
    mov [output_fd], rax

    call .process_file
    call .write_results

    mov rax, 3
    mov rdi, [input_fd]
    syscall
    
    mov rax, 3
    mov rdi, [output_fd]
    syscall

    jmp .exit

.show_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, usage
    mov rdx, usage_len
    syscall
    jmp .exit

.error_open:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_open
    mov rdx, error_open_len
    syscall
    jmp .exit

.error_read:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_read
    mov rdx, error_read_len
    syscall
    jmp .exit

.error_write:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_write
    mov rdx, error_write_len
    syscall
    jmp .exit

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

.process_file:
.read_loop:
    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, buffer_size
    syscall
    cmp rax, 0
    jl .error_read
    cmp rax, 0
    je .process_done
    
    mov r8, rax
    xor r9, r9
    
.process_buffer:
    cmp r9, r8
    jge .read_loop
    
    mov al, [buffer + r9]
    
    cmp al, 'A'
    jl .check_digit
    cmp al, 'Z'
    jle .is_letter
    
    cmp al, 'a'
    jl .check_digit
    cmp al, 'z'
    jle .is_letter
    
    jmp .check_digit

.is_letter:
    inc qword [letters_count]
    jmp .next_char

.check_digit:
    cmp al, '0'
    jl .next_char
    cmp al, '9'
    jg .next_char
    inc qword [digits_count]

.next_char:
    inc r9
    jmp .process_buffer

.process_done:
    ret

.write_results:
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, letters_msg
    mov rdx, letters_len
    syscall
    cmp rax, 0
    jl .error_write
    
    mov rax, [letters_count]
    mov rdi, result_buffer
    call .number_to_string
    
    mov rdx, rcx
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, result_buffer
    syscall
    cmp rax, 0
    jl .error_write
    
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, newline
    mov rdx, 1
    syscall
    cmp rax, 0
    jl .error_write
    
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, digits_msg
    mov rdx, digits_len
    syscall
    cmp rax, 0
    jl .error_write
    
    mov rax, [digits_count]
    mov rdi, result_buffer
    call .number_to_string
    
    mov rdx, rcx
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, result_buffer
    syscall
    cmp rax, 0
    jl .error_write
    
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ret

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