format ELF64 executable 3
entry _start

segment readable writeable
msg_child1 db "Child 1: ",0
msg_child2 db "Child 2: ",0
newline    db 10,0

child_pids dq 0, 0
N_value    dq 0

segment readable executable

print_string:
    ; rsi = строка, rdx = длина
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    syscall
    ret

print_number:
    ; rdi = число
    push rbp
    mov rbp, rsp
    sub rsp, 32     
    
    mov rax, rdi
    mov rcx, 10
    lea rsi, [rbp - 16] 
    mov byte [rsi + 15], 0
    mov rbx, 14
    
.convert_loop:
    xor rdx, rdx
    div rcx        
    add dl, '0'
    mov [rsi + rbx], dl
    dec rbx
    test rax, rax
    jnz .convert_loop
    
    lea rsi, [rsi + rbx + 1]
    mov rdx, 14
    sub rdx, rbx
    call print_string
    
    mov rsp, rbp
    pop rbp
    ret

; Главная программа
_start:
    mov rax, [rsp]          
    cmp rax, 2
    jl .default_n
    mov rsi, [rsp + 16]     
    xor rax, rax
    xor rcx, rcx
.convert_arg:
    mov cl, [rsi]
    test cl, cl
    jz .arg_done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .convert_arg
.arg_done:
    jmp .store_n
.default_n:
    mov rax, 5
.store_n:
    mov [N_value], rax

    mov rax, 57            
    syscall
    cmp rax, 0
    je .child1
    
    mov [child_pids], rax
    
    mov rdi, rax
    mov rsi, 0             
    mov rdx, 2            
    mov rax, 61             
    xor r10, r10
    syscall
    
    mov rax, 57             
    syscall
    cmp rax, 0
    je .child2
    
    mov [child_pids + 8], rax
    
    mov rdi, rax
    mov rsi, 0
    mov rdx, 2
    mov rax, 61
    xor r10, r10
    syscall
    
    mov r12, [N_value]
    xor r13, r13            
    
.parent_loop:
    cmp r13, r12
    jge .parent_exit
    
    mov rdi, [child_pids]
    mov rsi, 18             ; SIGCONT
    mov rax, 62             ; kill
    syscall
    
    mov rdi, [child_pids]
    mov rsi, 0
    mov rdx, 2
    mov rax, 61
    xor r10, r10
    syscall
    
    mov rdi, [child_pids + 8]
    mov rsi, 18
    mov rax, 62
    syscall
    
    mov rdi, [child_pids + 8]
    mov rsi, 0
    mov rdx, 2
    mov rax, 61
    xor r10, r10
    syscall
    
    inc r13
    jmp .parent_loop

.parent_exit:
    mov rdi, -1
    mov rax, 61
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall

.child1:
    mov rax, 39             
    syscall
    mov rdi, rax
    mov rsi, 19             
    mov rax, 62             
    syscall
    
    mov r14, [N_value]
    xor r15, r15           
    
.child1_loop:
    cmp r15, r14
    jge .child1_exit
    
    mov rsi, msg_child1
    mov rdx, 9              
    call print_string
    
    mov rdi, r15
    call print_number
    
    mov rsi, newline
    mov rdx, 1
    call print_string
    
    inc r15
    cmp r15, r14
    je .child1_exit
    
    mov rax, 39             
    syscall
    mov rdi, rax
    mov rsi, 19             
    mov rax, 62
    syscall
    
    jmp .child1_loop

.child1_exit:
    mov rax, 60
    xor rdi, rdi
    syscall


.child2:   
    mov rax, 39             
    syscall
    mov rdi, rax
    mov rsi, 19             
    mov rax, 62             
    syscall
    
    mov r14, [N_value]
    xor r15, r15            
    
.child2_loop:
    cmp r15, r14
    jge .child2_exit
    
    mov rsi, msg_child2
    mov rdx, 9              
    call print_string
    
    mov rdi, r15
    call print_number
    
    mov rsi, newline
    mov rdx, 1
    call print_string
    
    inc r15
    cmp r15, r14
    je .child2_exit
    
    mov rax, 39             
    syscall
    mov rdi, rax
    mov rsi, 19             
    mov rax, 62
    syscall
    
    jmp .child2_loop

.child2_exit:
    mov rax, 60
    xor rdi, rdi
    syscall