format ELF64

section '.data' writeable
    symbol db '8'
    N = 30
    newline db 10

section '.text' executable
public _start

_start:
    mov esi, N          
    mov ebx, 1          
    mov edi, 1          

print_triangle:
    cmp esi, 0
    jle exit
    
   
    mov ecx, ebx
    cmp ecx, esi
    jle print_row
    mov ecx, esi

print_row:
    push rsi
    push rbx
    push rcx
    
    mov eax, 1       
    mov edx, 1       
print_symbol:
    push rcx
    mov esi, symbol 
    syscall
    pop rcx
    loop print_symbol
    

    mov eax, 1
    mov esi, newline
    mov edx, 1
    syscall
    
    pop rcx
    pop rbx
    pop rsi
    
    sub esi, ecx       
    inc ebx            
    jmp print_triangle

exit:
    mov eax, 60
    xor edi, edi
    syscall