format elf64
public _start

extrn printf

section '.data' writeable
    fmt_table_header    db " Точность    Члены ряда   Члены дроби ", 0xa,0
    
    fmt_table_row       db " %-10.0e  %-11d  %-11d ", 0xa, 0
    
    fmt_e_series        db "e (ряд)    = %.15f", 0xa, 0
    fmt_e_fraction      db "e (дробь)  = %.15f", 0xa, 0
    fmt_math_e          db "math.h e   = %.15f", 0xa, 0
    
    newline             db 0xa, 0
    
    precisions dq 1.0e-1, 1.0e-2, 1.0e-3, 1.0e-4, 1.0e-5, 1.0e-6, 1.0e-7, 1.0e-8
    prec_count = ($ - precisions) / 8
    
    one      dq 1.0
    two      dq 2.0
    math_e   dq 2.718281828459045
    abs_mask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
    
section '.bss' writeable
    e_series     rq 1
    e_fraction   rq 1
    terms_series   rd 1
    terms_fraction rd 1
    depth       rd 1
    current_n   rd 1
    prev_e      rq 1
    
section '.text' executable

compute_e_series:
    push rbp
    mov rbp, rsp
    sub rsp, 16
    
    movq [rbp-8], xmm0
    finit
    
    fld qword [two]
    fld1
    mov dword [current_n], 1
    mov dword [terms_series], 0
    
.series_loop:
    inc dword [current_n]
    fild dword [current_n]
    fdivp st1, st0
    
    fld st0
    fabs
    fcomp qword [rbp-8]
    fstsw ax
    sahf
    jb .series_done
    
    fadd st1, st0
    inc dword [terms_series]
    
    cmp dword [terms_series], 1000
    jl .series_loop
    
.series_done:
    fstp st0
    fstp qword [e_series]
    
    movq xmm0, [e_series]
    add rsp, 16
    pop rbp
    ret

compute_e_fraction_adaptive_real:
    push rbp
    mov rbp, rsp
    sub rsp, 48
    
    movq [rbp-8], xmm0
    movq [rbp-16], xmm0
    
    mov dword [depth], 2
    mov dword [terms_fraction], 0
    
    fld qword [two]
    fstp qword [prev_e]
    
.fraction_convergence_loop:
    finit
    
    fldz
    
    mov ecx, [depth]
    mov [current_n], ecx
    
.inner_compute_loop:
    fild dword [current_n]
    fld st0
    fadd st0, st2
    fdivp st1, st0
    fstp st1
    
    dec dword [current_n]
    cmp dword [current_n], 1
    jg .inner_compute_loop
    
    fld qword [two]
    faddp st1, st0
    
    fst qword [e_fraction]
    fst qword [rbp-24]
    
    cmp dword [terms_fraction], 0
    je .first_iteration
    
    fld qword [prev_e]
    fsub st0, st1
    fabs

    fcomp qword [rbp-16]
    fstsw ax
    sahf
    jb .converged
    
    fstp st0
    
.first_iteration:
    fld qword [rbp-24]
    fstp qword [prev_e]
    
    inc dword [depth]
    inc dword [terms_fraction]
    
    cmp dword [depth], 50
    jl .fraction_convergence_loop
    
.converged:
    inc dword [terms_fraction]
    
    fld qword [e_fraction]
    fstp qword [e_fraction]
    
    movq xmm0, [e_fraction]
    add rsp, 48
    pop rbp
    ret

_start:
    mov rdi, fmt_table_header
    xor rax, rax
    call printf
    
    mov rbx, precisions
    mov r12, prec_count
    
.precision_loop:
    push rbx
    push r12
    
    movq xmm0, [rbx]
    call compute_e_series
    
    movq xmm0, [rbx]
    call compute_e_fraction_adaptive_real
    
    movq xmm0, [rbx]
    mov esi, [terms_series]
    mov edx, [terms_fraction]
    mov rax, 1
    mov rdi, fmt_table_row
    call printf
    
    pop r12
    pop rbx
    
    add rbx, 8
    dec r12
    jnz .precision_loop
    
    movq xmm0, [precisions + 56]
    call compute_e_series
    mov rdi, fmt_e_series
    mov rax, 1
    call printf
    
    movq xmm0, [precisions + 56]
    call compute_e_fraction_adaptive_real
    mov rdi, fmt_e_fraction
    mov rax, 1
    call printf
    
    movq xmm0, [math_e]
    mov rdi, fmt_math_e  
    mov rax, 1
    call printf

    mov rax, 60
    xor rdi, rdi
    syscall