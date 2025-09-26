format ELF64
section '.data' writeable
    
    symbol db '+'        
    N equ 66            
    M equ 6             
    K equ 11             
    
    newline db 10        
    space db ' '        

section '.bss' writeable
    buffer rb N         
    output rb M + 1     

section '.text' executable
public _start

_start:
   
    mov rdi, buffer       
    mov rcx, N           
    mov al, [symbol]     
    
fill_buffer:
    mov [rdi], al       
    inc rdi
    loop fill_buffer

    mov rsi, buffer      
    mov rcx, K           
    
print_rows:
    push rcx             
    mov rcx, M           
    mov rdi, output      
    
fill_row:
    mov al, [rsi]        
    mov [rdi], al        
    inc rsi
    inc rdi
    loop fill_row
    
    
    mov byte [rdi], 10
    
  
    mov rax, 1          
    mov rdi, 1           
    mov rsi, output     
    mov rdx, M + 1       
    syscall
    
    pop rcx              
    loop print_rows

exit:
    mov rax, 60         
    xor rdi, rdi
    syscall