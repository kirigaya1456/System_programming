format ELF64
public _start

section '.data' writable
    usage db 'Usage: program <directory>', 0xA, 0
    usage_len = $ - usage
    error_dir db 'Error: Cannot open directory', 0xA, 0
    error_dir_len = $ - error_dir
    error_files db 'Error: Need at least 2 files in directory', 0xA, 0
    error_files_len = $ - error_files
    error_swap db 'Error: File swap failed', 0xA, 0
    error_swap_len = $ - error_swap
    success db 'Files swapped successfully', 0xA, 0
    success_len = $ - success
    
    buffer_size equ 4096
    buffer1 rb buffer_size
    buffer2 rb buffer_size
    
    dir_fd dq 0
    file1_fd dq 0
    file2_fd dq 0
    file1_name rq 1
    file2_name rq 1
    
    file_count dq 0
    file_list rq 100

section '.text' executable
_start:
    pop rcx
    cmp rcx, 2
    jne .show_usage

    pop rsi
    pop rdi

    mov rax, 2
    mov rsi, 0
    syscall
    cmp rax, 0
    jl .error_directory
    mov [dir_fd], rax

    call .read_directory
    cmp qword [file_count], 2
    jl .error_not_enough_files

    call .select_random_files
    call .swap_files

    mov rax, 3
    mov rdi, [dir_fd]
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, success
    mov rdx, success_len
    syscall

    jmp .exit

.show_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, usage
    mov rdx, usage_len
    syscall
    jmp .exit

.error_directory:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_dir
    mov rdx, error_dir_len
    syscall
    jmp .exit

.error_not_enough_files:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_files
    mov rdx, error_files_len
    syscall
    
    mov rax, 3
    mov rdi, [dir_fd]
    syscall
    jmp .exit

.error_swap:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_swap
    mov rdx, error_swap_len
    syscall
    jmp .exit

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall

.read_directory:
    mov rax, 217
    mov rdi, [dir_fd]
    mov rsi, buffer1
    mov rdx, buffer_size
    syscall
    
    cmp rax, 0
    jle .read_done
    
    mov r8, rax
    xor r9, r9
    
.process_entry:
    cmp r9, r8
    jge .read_done
    
    lea r10, [buffer1 + r9]
    
    mov al, [r10 + 19]
    cmp al, '.'
    je .skip_entry
    
    mov rax, [file_count]
    lea r11, [file_list + rax * 8]
    
    mov rax, 12
    xor rdi, rdi
    syscall
    mov rdi, rax
    add rdi, 256
    mov rax, 12
    syscall
    
    lea rsi, [r10 + 19]
    mov rdi, rax
    call .copy_string
    mov [r11], rax
    
    inc qword [file_count]
    
.skip_entry:
    movzx rcx, word [r10 + 16]
    add r9, rcx
    jmp .process_entry

.read_done:
    ret

.select_random_files:
    mov rax, 201
    xor rdi, rdi
    syscall
    
    xor rdx, rdx
    mov rbx, [file_count]
    div rbx
    mov r12, rdx
    
.get_second:
    mov rax, 201
    xor rdi, rdi
    syscall
    xor rdx, rdx
    mov rbx, [file_count]
    div rbx
    cmp rdx, r12
    je .get_second
    mov r13, rdx
    
    mov rax, [file_list + r12 * 8]
    mov [file1_name], rax
    mov rax, [file_list + r13 * 8]
    mov [file2_name], rax
    
    ret

.swap_files:
    mov rax, 2
    mov rdi, [file1_name]
    mov rsi, 0
    syscall
    cmp rax, 0
    jl .swap_error
    mov [file1_fd], rax
    
    mov rax, 2
    mov rdi, [file2_name]
    mov rsi, 0
    syscall
    cmp rax, 0
    jl .swap_error
    mov [file2_fd], rax
    
    mov rax, 0
    mov rdi, [file1_fd]
    mov rsi, buffer1
    mov rdx, buffer_size
    syscall
    mov r12, rax
    
    mov rax, 0
    mov rdi, [file2_fd]
    mov rsi, buffer2
    mov rdx, buffer_size
    syscall
    mov r13, rax
    
    mov rax, 3
    mov rdi, [file1_fd]
    syscall
    mov rax, 3
    mov rdi, [file2_fd]
    syscall
    
    mov rax, 2
    mov rdi, [file1_name]
    mov rsi, 1
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .swap_error
    mov [file1_fd], rax
    
    mov rax, 1
    mov rdi, [file1_fd]
    mov rsi, buffer2
    mov rdx, r13
    syscall
    
    mov rax, 3
    mov rdi, [file1_fd]
    syscall
    
    mov rax, 2
    mov rdi, [file2_name]
    mov rsi, 1
    mov rdx, 0644o
    syscall
    cmp rax, 0
    jl .swap_error
    mov [file2_fd], rax
    
    mov rax, 1
    mov rdi, [file2_fd]
    mov rsi, buffer1
    mov rdx, r12
    syscall
    
    mov rax, 3
    mov rdi, [file2_fd]
    syscall
    
    ret

.swap_error:
    jmp .error_swap

.copy_string:
    mov rax, rdi
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    test al, al
    jnz .copy_loop
    ret