format ELF64
section '.data' writeable
    S db 'AMVtdiYVETHnNhuYwnWDVBqL',0
    len = $ - S - 1  ; Длина строки без нулевого байта

section '.text' executable
public _start

_start:
    mov rsi, S           
    xor rcx, rcx         
    
calculate_length:
    cmp byte [rsi + rcx], 0  
    je print_reverse
    inc rcx
    jmp calculate_length

print_reverse:
    test rcx, rcx       
    jz exit
    
    mov rdx, rcx        
    
    
reverse_loop:
    dec rcx              
    mov rax, 1           
    mov rdi, 1           
    lea rsi, [S + rcx]   
    mov rdx, 1          
    push rcx             
    pop rcx              
    
    test rcx, rcx       
    jnz reverse_loop

exit:
    mov rax, 60          
    xor rdi, rdi       
    syscall