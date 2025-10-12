format ELF64
public _start

section '.data' writeable
    usage_msg db "Использование: ./program n", 10
    usage_len = $ - usage_msg
    
    result_msg db "Количество чисел от 1 до "
    result_msg_len = $ - result_msg
    
    result_msg2 db ", делящихся на 37 и 13: "
    result_msg2_len = $ - result_msg2
    
    newline db 10
    divisor1 dq 37
    divisor2 dq 13

section '.bss' writeable
    n dq 0
    result dq 0
    buffer rb 20

section '.text' executable
_start:

    pop rcx             
    cmp rcx, 2
    jl .show_usage       
    
    pop rsi            
    pop rsi             
    
 
    call string_to_number
    test rax, rax
    jz .show_usage      
    
    mov [n], rax       
    
   
    call calculate_result
    
   
    call print_result
    
  
    mov rax, 60        
    xor rdi, rdi        
    syscall

.show_usage:
   
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, usage_msg
    mov rdx, usage_len
    syscall
    
    mov rax, 60          ; sys_exit
    mov rdi, 1           ; код возврата 1 (ошибка)
    syscall


string_to_number:
    xor rax, rax        
    xor rcx, rcx       
    mov rbx, 10         

.convert_loop:
    mov cl, [rsi]        
    test cl, cl          
    jz .done
    
   
    cmp cl, '0'
    jb .error
    cmp cl, '9'
    ja .error
    
    
    sub cl, '0'
    
  
    mul rbx             
    add rax, rcx        
    
    inc rsi              
    jmp .convert_loop

.done:
    ret

.error:
    xor rax, rax         
    ret


calculate_result:
    ; Вычисляем НОК(37, 13) = 37 * 13 = 481
    mov rax, [divisor1]
    mov rbx, [divisor2]
    mul rbx              ; rax = 37 * 13 = 481
    
    mov rbx, rax         ; rbx = 481 (НОК)
    mov rcx, [n]         ; rcx = n
     
    xor rdx, rdx        
    mov rax, rcx        
    div rbx              
    
    mov [result], rax    
    ret

print_result:

    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall
    
    mov rax, [n]
    call print_number
    
   
    mov rax, 1           
    mov rdi, 1          
    mov rsi, result_msg2
    mov rdx, result_msg2_len
    syscall
    
    
    mov rax, [result]
    call print_number
    
   
    mov rax, 1         
    mov rdi, 1          
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ret


print_number:
    mov rdi, buffer + 19 
    mov byte [rdi], 0    
    mov rbx, 10          
    
.convert_loop:
    xor rdx, rdx         
    div rbx             
    add dl, '0'          
    dec rdi              
    mov [rdi], dl        
    test rax, rax        
    jnz .convert_loop   
    
    mov rsi, rdi         
    mov rdx, buffer + 20 
    sub rdx, rdi
    mov rax, 1           
    mov rdi, 1          
    syscall
    
    ret