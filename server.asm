; ==============================================================
; server.asm  —  "Онлайн-библиотека": сервер
; ==============================================================
format ELF64 executable 3
entry _start

SYS_READ       = 0
SYS_WRITE      = 1
SYS_CLOSE      = 3
SYS_MMAP       = 9
SYS_SOCKET     = 41
SYS_ACCEPT     = 43
SYS_SENDTO     = 44
SYS_BIND       = 49
SYS_LISTEN     = 50
SYS_SETSOCKOPT = 54
SYS_FORK       = 57
SYS_EXIT       = 60
SYS_WAIT4      = 61


AF_INET        = 2
SOCK_STREAM    = 1
SOL_SOCKET     = 1
SO_REUSEADDR   = 2
INADDR_ANY     = 0
SERVER_PORT    = 8080
BACKLOG        = 10


PROT_READ      = 1
PROT_WRITE     = 2
MAP_SHARED     = 1
MAP_ANONYMOUS  = 0x20

WNOHANG        = 1
CMD_BUF_SZ     = 2048


MAX_BOOKS      = 100
MAX_READERS    = 50
MAX_LOANS      = 200
MAX_REVIEWS    = 500


BOOK_SZ   = 160
B_ID      = 0       
B_TITLE   = 4       
B_AUTHOR  = 68      
B_YEAR    = 132     
B_TOTAL   = 136     
B_AVAIL   = 140     
B_RSUM    = 144     
B_RCOUNT  = 148     


READER_SZ = 144
R_ID      = 0       
R_NAME    = 4       
R_EMAIL   = 68      
R_LOANS   = 132     


LOAN_SZ   = 32
L_ID      = 0       
L_BOOK    = 4       
L_READER  = 8       
L_STATUS  = 12      


REVIEW_SZ = 288
RV_BOOK   = 0       
RV_READER = 4       
RV_RATING = 8       
RV_TEXT   = 12      


DB_BC          = 0          
DB_RC          = 4          
DB_LC          = 8          
DB_RVC         = 12         
DB_NLI         = 16         

DB_BOOKS       = 32
DB_READERS     = DB_BOOKS   + MAX_BOOKS   * BOOK_SZ      
DB_LOANS       = DB_READERS + MAX_READERS * READER_SZ    
DB_REVIEWS     = DB_LOANS   + MAX_LOANS   * LOAN_SZ      
DB_TOTAL_SIZE  = DB_REVIEWS + MAX_REVIEWS * REVIEW_SZ    


segment readable executable


_start:
    mov     eax, SYS_MMAP
    xor     rdi, rdi
    mov     rsi, DB_TOTAL_SIZE
    mov     rdx, PROT_READ or PROT_WRITE
    mov     r10, MAP_SHARED or MAP_ANONYMOUS
    mov     r8, -1
    xor     r9, r9
    syscall
    cmp     rax, -1
    je      .die_mmap
    mov     [db_ptr], rax

    mov     rdi, rax
    xor     esi, esi
    mov     rdx, DB_TOTAL_SIZE
    call    memset


    mov     r15, [db_ptr]
    mov     dword [r15 + DB_NLI], 1


    call    init_db


    lea     rdi, [str_banner]
    call    print_str


    mov     eax, SYS_SOCKET
    mov     edi, AF_INET
    mov     esi, SOCK_STREAM
    xor     edx, edx
    syscall
    cmp     rax, 0
    jl      .die_sock
    mov     [srv_fd], eax


    mov     eax, SYS_SETSOCKOPT
    mov     edi, [srv_fd]
    mov     esi, SOL_SOCKET
    mov     edx, SO_REUSEADDR
    lea     r10, [opt_one]
    mov     r8d, 4
    syscall


    mov     word  [srv_addr + 0], AF_INET
    mov     ax, SERVER_PORT
    xchg    ah, al
    mov     word  [srv_addr + 2], ax
    mov     dword [srv_addr + 4], INADDR_ANY
    mov     eax, SYS_BIND
    mov     edi, [srv_fd]
    lea     rsi, [srv_addr]
    mov     edx, 16
    syscall
    cmp     rax, 0
    jl      .die_bind

    ; Listen
    mov     eax, SYS_LISTEN
    mov     edi, [srv_fd]
    mov     esi, BACKLOG
    syscall
    cmp     rax, 0
    jl      .die_listen

    lea     rdi, [str_listening]
    call    print_str

.accept_loop:
    mov     eax, SYS_WAIT4
    mov     edi, -1
    xor     rsi, rsi
    mov     edx, WNOHANG
    xor     r10, r10
    syscall


    mov     dword [cli_alen], 16
    mov     eax, SYS_ACCEPT
    mov     edi, [srv_fd]
    lea     rsi, [cli_addr]
    lea     rdx, [cli_alen]
    syscall
    cmp     rax, 0
    jl      .accept_loop
    mov     [cli_fd], eax

    lea     rdi, [str_new_conn]
    call    print_str


    mov     eax, SYS_FORK
    syscall
    cmp     rax, 0
    je      .child
    jl      .accept_loop


    mov     eax, SYS_CLOSE
    mov     edi, [cli_fd]
    syscall
    jmp     .accept_loop

.child:
    mov     eax, SYS_CLOSE
    mov     edi, [srv_fd]
    syscall
    mov     edi, [cli_fd]
    call    handle_client
    mov     eax, SYS_CLOSE
    mov     edi, [cli_fd]
    syscall
    mov     eax, SYS_EXIT
    xor     edi, edi
    syscall

.die_mmap:
    lea     rdi, [err_mmap]
    call    print_str
    jmp     .die
.die_sock:
    lea     rdi, [err_sock]
    call    print_str
    jmp     .die
.die_bind:
    lea     rdi, [err_bind]
    call    print_str
    jmp     .die
.die_listen:
    lea     rdi, [err_listen]
    call    print_str
.die:
    mov     eax, SYS_EXIT
    mov     edi, 1
    syscall


init_db:
    push    rbp
    mov     rbp, rsp
    push    r14
    push    r15

    mov     r15, [db_ptr]


    lea     r14, [r15 + DB_BOOKS + 0 * BOOK_SZ]
    mov     dword [r14 + B_ID],    1
    mov     dword [r14 + B_YEAR],  1978
    mov     dword [r14 + B_TOTAL], 3
    mov     dword [r14 + B_AVAIL], 3
    lea     rdi, [r14 + B_TITLE]
    lea     rsi, [sb1t]
    mov     rdx, 63
    call    strncpy
    lea     rdi, [r14 + B_AUTHOR]
    lea     rsi, [sb1a]
    mov     rdx, 63
    call    strncpy


    lea     r14, [r15 + DB_BOOKS + 1 * BOOK_SZ]
    mov     dword [r14 + B_ID],    2
    mov     dword [r14 + B_YEAR],  2018
    mov     dword [r14 + B_TOTAL], 2
    mov     dword [r14 + B_AVAIL], 2
    lea     rdi, [r14 + B_TITLE]
    lea     rsi, [sb2t]
    mov     rdx, 63
    call    strncpy
    lea     rdi, [r14 + B_AUTHOR]
    lea     rsi, [sb2a]
    mov     rdx, 63
    call    strncpy


    lea     r14, [r15 + DB_BOOKS + 2 * BOOK_SZ]
    mov     dword [r14 + B_ID],    3
    mov     dword [r14 + B_YEAR],  2015
    mov     dword [r14 + B_TOTAL], 4
    mov     dword [r14 + B_AVAIL], 4
    lea     rdi, [r14 + B_TITLE]
    lea     rsi, [sb3t]
    mov     rdx, 63
    call    strncpy
    lea     rdi, [r14 + B_AUTHOR]
    lea     rsi, [sb3a]
    mov     rdx, 63
    call    strncpy


    lea     r14, [r15 + DB_BOOKS + 3 * BOOK_SZ]
    mov     dword [r14 + B_ID],    4
    mov     dword [r14 + B_YEAR],  2010
    mov     dword [r14 + B_TOTAL], 2
    mov     dword [r14 + B_AVAIL], 2
    lea     rdi, [r14 + B_TITLE]
    lea     rsi, [sb4t]
    mov     rdx, 63
    call    strncpy
    lea     rdi, [r14 + B_AUTHOR]
    lea     rsi, [sb4a]
    mov     rdx, 63
    call    strncpy


    lea     r14, [r15 + DB_BOOKS + 4 * BOOK_SZ]
    mov     dword [r14 + B_ID],    5
    mov     dword [r14 + B_YEAR],  2009
    mov     dword [r14 + B_TOTAL], 3
    mov     dword [r14 + B_AVAIL], 3
    lea     rdi, [r14 + B_TITLE]
    lea     rsi, [sb5t]
    mov     rdx, 63
    call    strncpy
    lea     rdi, [r14 + B_AUTHOR]
    lea     rsi, [sb5a]
    mov     rdx, 63
    call    strncpy

    mov     dword [r15 + DB_BC], 5


    lea     r14, [r15 + DB_READERS + 0 * READER_SZ]
    mov     dword [r14 + R_ID], 1
    lea     rdi, [r14 + R_NAME]
    lea     rsi, [sr1n]
    mov     rdx, 63
    call    strncpy
    lea     rdi, [r14 + R_EMAIL]
    lea     rsi, [sr1e]
    mov     rdx, 63
    call    strncpy

    lea     r14, [r15 + DB_READERS + 1 * READER_SZ]
    mov     dword [r14 + R_ID], 2
    lea     rdi, [r14 + R_NAME]
    lea     rsi, [sr2n]
    mov     rdx, 63
    call    strncpy
    lea     rdi, [r14 + R_EMAIL]
    lea     rsi, [sr2e]
    mov     rdx, 63
    call    strncpy

    mov     dword [r15 + DB_RC], 2

    pop     r15
    pop     r14
    pop     rbp
    ret


handle_client:
    push    rbp
    mov     rbp, rsp
    sub     rsp, CMD_BUF_SZ + 8     
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, edi
    mov     qword [rbp - 8], 0          

    mov     rdi, r12
    lea     rsi, [str_welcome]
    call    send_str

.loop:
    mov     edi, r12d
    lea     rsi, [rbp - 8 - CMD_BUF_SZ]
    mov     rdx, CMD_BUF_SZ - 1
    call    recv_line
    cmp     rax, 0
    jle     .done

    lea     rbx, [rbp - 8 - CMD_BUF_SZ]


    mov     rdi, rbx
    lea     rsi, [scmd_quit]
    call    cmd_match
    test    eax, eax
    jnz     .do_quit


    mov     rdi, rbx
    lea     rsi, [scmd_help]
    call    cmd_match
    test    eax, eax
    jnz     .do_help


    mov     rdi, rbx
    lea     rsi, [scmd_register]
    call    cmd_match
    test    eax, eax
    jnz     .do_register


    mov     rdi, rbx
    lea     rsi, [scmd_login]
    call    cmd_match
    test    eax, eax
    jnz     .do_login


    mov     rdi, rbx
    lea     rsi, [scmd_list]
    call    cmd_match
    test    eax, eax
    jnz     .do_list


    mov     rdi, rbx
    lea     rsi, [scmd_search]
    call    cmd_match
    test    eax, eax
    jnz     .do_search


    mov     rdi, rbx
    lea     rsi, [scmd_info]
    call    cmd_match
    test    eax, eax
    jnz     .do_info


    mov     rdi, rbx
    lea     rsi, [scmd_reserve]
    call    cmd_match
    test    eax, eax
    jnz     .do_reserve


    mov     rdi, rbx
    lea     rsi, [scmd_return]
    call    cmd_match
    test    eax, eax
    jnz     .do_return


    mov     rdi, rbx
    lea     rsi, [scmd_myloans]
    call    cmd_match
    test    eax, eax
    jnz     .do_myloans


    mov     rdi, rbx
    lea     rsi, [scmd_rate]
    call    cmd_match
    test    eax, eax
    jnz     .do_rate


    mov     rdi, rbx
    lea     rsi, [scmd_reviews]
    call    cmd_match
    test    eax, eax
    jnz     .do_reviews


    mov     rdi, rbx
    lea     rsi, [scmd_review]
    call    cmd_match
    test    eax, eax
    jnz     .do_review

    mov     rdi, r12
    lea     rsi, [err_unknown_cmd]
    call    send_str
    jmp     .loop

.do_quit:
    mov     rdi, r12
    lea     rsi, [str_bye]
    call    send_str
    jmp     .done

.do_help:
    mov     rdi, r12
    lea     rsi, [str_help]
    call    send_str
    jmp     .loop

.do_register:
    lea     rsi, [rbx + 9]         
    mov     edi, r12d
    call    cmd_register
    jmp     .loop

.do_login:
    lea     rdi, [rbx + 6]          
    call    parse_int             
    mov     rdi, rax
    call    find_reader_by_id     
    test    rax, rax
    jz      .login_nf
    mov     r13, rax
    mov     eax, [r13 + R_ID]
    cdqe
    mov     [rbp - 8], rax
    mov     rdi, r12
    lea     rsi, [str_ok_login]
    call    send_str
    mov     rdi, r12
    lea     rsi, [r13 + R_NAME]
    call    send_str
    mov     rdi, r12
    lea     rsi, [str_nl]
    call    send_str
    jmp     .loop
.login_nf:
    mov     rdi, r12
    lea     rsi, [err_no_reader]
    call    send_str
    jmp     .loop

.do_list:
    mov     edi, r12d
    call    cmd_list
    jmp     .loop

.do_search:
    lea     r13, [rbx + 7]          
    mov     edi, r12d
    mov     rsi, r13
    call    cmd_search
    jmp     .loop

.do_info:
    lea     rdi, [rbx + 5]        
    call    parse_int
    mov     edi, r12d
    mov     rsi, rax
    call    cmd_info
    jmp     .loop

.do_reserve:
    cmp     qword [rbp - 8], 0
    je      .need_login
    lea     rdi, [rbx + 8]         
    call    parse_int
    mov     edi, r12d
    mov     rsi, rax
    mov     rdx, [rbp - 8]
    call    cmd_reserve
    jmp     .loop

.do_return:
    cmp     qword [rbp - 8], 0
    je      .need_login
    lea     rdi, [rbx + 7]         
    call    parse_int
    mov     edi, r12d
    mov     rsi, rax
    mov     rdx, [rbp - 8]
    call    cmd_return
    jmp     .loop

.do_myloans:
    cmp     qword [rbp - 8], 0
    je      .need_login
    mov     edi, r12d
    mov     rsi, [rbp - 8]
    call    cmd_myloans
    jmp     .loop

.do_rate:
    cmp     qword [rbp - 8], 0
    je      .need_login
    ; RATE <book_id> <1-5>
    lea     rdi, [rbx + 5]         
    call    parse_int               
    mov     r13, rax
    cmp     byte [rdi], ' '
    jne     .syntax_err
    inc     rdi
    call    parse_int            
    mov     edi, r12d
    mov     rsi, r13
    mov     rdx, rax
    mov     rcx, [rbp - 8]
    call    cmd_rate
    jmp     .loop

.do_review:
    cmp     qword [rbp - 8], 0
    je      .need_login

    lea     rdi, [rbx + 7]         
    call    parse_int
    mov     r13, rax
    cmp     byte [rdi], ' '
    jne     .syntax_err
    inc     rdi
    mov     r14, rdi               
    mov     edi, r12d
    mov     rsi, r13
    mov     rdx, r14
    mov     rcx, [rbp - 8]
    call    cmd_review
    jmp     .loop

.do_reviews:
    lea     rdi, [rbx + 8]         
    call    parse_int
    mov     edi, r12d
    mov     rsi, rax
    call    cmd_reviews
    jmp     .loop

.need_login:
    mov     rdi, r12
    lea     rsi, [err_need_login]
    call    send_str
    jmp     .loop

.syntax_err:
    mov     rdi, r12
    lea     rsi, [err_syntax]
    call    send_str
    jmp     .loop

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    add     rsp, CMD_BUF_SZ + 8
    pop     rbp
    ret


cmd_list:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, edi
    mov     r13, [db_ptr]
    mov     r14d, [r13 + DB_BC]

    test    r14d, r14d
    jz      .empty

    mov     rdi, r12
    lea     rsi, [str_list_hdr]
    call    send_str

    xor     r15d, r15d
.loop:
    cmp     r15d, r14d
    jge     .end_list

    mov     rax, r15
    imul    rax, BOOK_SZ
    lea     rbx, [r13 + DB_BOOKS + rax]

    lea     rdi, [fmt_buf]
    mov     rsi, rbx
    call    format_book

    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str

    inc     r15d
    jmp     .loop

.end_list:
    mov     rdi, r12
    lea     rsi, [str_end]
    call    send_str
    jmp     .ret

.empty:
    mov     rdi, r12
    lea     rsi, [err_no_books]
    call    send_str
    mov     rdi, r12
    lea     rsi, [str_end]
    call    send_str

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_search:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, edi
    mov     r13, rsi               
    mov     r14, [db_ptr]
    mov     r15d, [r14 + DB_BC]

    xor     rbx, rbx                
    xor     ecx, ecx              

.loop:
    cmp     ecx, r15d
    jge     .end_loop

    push    rcx
    mov     rax, rcx
    imul    rax, BOOK_SZ
    lea     r8, [r14 + DB_BOOKS + rax]     


    lea     rdi, [r8 + B_TITLE]
    mov     rsi, r13
    call    strstr_ci                     
    test    rax, rax
    jnz     .found


    lea     rdi, [r8 + B_AUTHOR]            
    mov     rsi, r13
    call    strstr_ci
    test    rax, rax
    jz      .next

.found:
    lea     rdi, [fmt_buf]
    mov     rsi, r8
    call    format_book
    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str
    inc     rbx

.next:
    pop     rcx
    inc     ecx
    jmp     .loop

.end_loop:
    test    rbx, rbx
    jnz     .send_end
    mov     rdi, r12
    lea     rsi, [err_not_found]
    call    send_str
.send_end:
    mov     rdi, r12
    lea     rsi, [str_end]
    call    send_str

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_info:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12d, edi
    mov     r13, rsi

    mov     rdi, r13
    call    find_book_by_id
    test    rax, rax
    jz      .notfound
    mov     rbx, rax

    lea     rdi, [fmt_buf]
    mov     rsi, rbx
    call    format_book
    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str


    cmp     dword [rbx + B_RCOUNT], 0
    je      .no_rat
    lea     rdi, [fmt_buf]
    lea     rsi, [str_rating_lbl]
    call    append_str             
    mov     rdi, rax
    mov     eax, [rbx + B_RSUM]
    xor     edx, edx
    div     dword [rbx + B_RCOUNT]  
    mov     esi, eax
    call    append_int              
    mov     rdi, rax
    lea     rsi, [str_of5]        
    call    append_str              
    mov     byte [rax], 0         
    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str
.no_rat:
    jmp     .ret

.notfound:
    mov     rdi, r12
    lea     rsi, [err_no_book]
    call    send_str

.ret:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_reserve:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, edi
    mov     r13, rsi                
    mov     r14, rdx              


    mov     rdi, r13
    call    find_book_by_id
    test    rax, rax
    jz      .no_book
    mov     rbx, rax                


    cmp     dword [rbx + B_AVAIL], 0
    je      .no_copies


    mov     rdi, r13
    mov     rsi, r14
    call    find_active_loan
    test    rax, rax
    jnz     .already


    mov     r15, [db_ptr]
    mov     ecx, [r15 + DB_LC]
    cmp     ecx, MAX_LOANS
    jge     .db_full

    mov     rax, rcx
    imul    rax, LOAN_SZ
    lea     rdx, [r15 + DB_LOANS + rax]

    mov     eax, [r15 + DB_NLI]
    mov     [rdx + L_ID],     eax
    inc     dword [r15 + DB_NLI]
    mov     eax, r13d
    mov     [rdx + L_BOOK],   eax
    mov     eax, r14d
    mov     [rdx + L_READER], eax
    mov     byte [rdx + L_STATUS], 0

    inc     dword [r15 + DB_LC]


    dec     dword [rbx + B_AVAIL]


    mov     rdi, r14
    call    find_reader_by_id
    test    rax, rax
    jz      .ok
    inc     dword [rax + R_LOANS]

.ok:
    mov     rdi, r12
    lea     rsi, [str_reserved]
    call    send_str
    jmp     .ret

.no_book:
    mov     rdi, r12
    lea     rsi, [err_no_book]
    call    send_str
    jmp     .ret
.no_copies:
    mov     rdi, r12
    lea     rsi, [err_no_copies]
    call    send_str
    jmp     .ret
.already:
    mov     rdi, r12
    lea     rsi, [err_already]
    call    send_str
    jmp     .ret
.db_full:
    mov     rdi, r12
    lea     rsi, [err_db_full]
    call    send_str

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_return:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12d, edi
    mov     r13, rsi
    mov     r14, rdx


    mov     rdi, r13
    mov     rsi, r14
    call    find_active_loan
    test    rax, rax
    jz      .no_loan
    mov     rbx, rax              


    mov     byte [rbx + L_STATUS], 1


    mov     rdi, r13
    call    find_book_by_id
    test    rax, rax
    jz      .no_book
    inc     dword [rax + B_AVAIL]


    mov     rdi, r14
    call    find_reader_by_id
    test    rax, rax
    jz      .ok
    cmp     dword [rax + R_LOANS], 0
    je      .ok
    dec     dword [rax + R_LOANS]

.ok:
    mov     rdi, r12
    lea     rsi, [str_returned]
    call    send_str
    jmp     .ret

.no_loan:
    mov     rdi, r12
    lea     rsi, [err_no_loan]
    call    send_str
    jmp     .ret
.no_book:
    mov     rdi, r12
    lea     rsi, [err_no_book]
    call    send_str

.ret:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_myloans:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, edi
    mov     r13, rsi               
    mov     r14, [db_ptr]
    mov     r15d, [r14 + DB_LC]

    xor     rbx, rbx               
    xor     ecx, ecx

.loop:
    cmp     ecx, r15d
    jge     .end_loop

    push    rcx
    mov     rax, rcx
    imul    rax, LOAN_SZ
    lea     rdx, [r14 + DB_LOANS + rax]


    cmp     byte [rdx + L_STATUS], 0
    jne     .next
    mov     eax, [rdx + L_READER]
    cmp     rax, r13
    jne     .next

   
    mov     eax, [rdx + L_BOOK]
    push    rdx
    mov     rdi, rax
    call    find_book_by_id
    pop     rdx
    test    rax, rax
    jz      .next

    push    rdx
    lea     rdi, [fmt_buf]
    mov     rsi, rax
    call    format_book
    pop     rdx
    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str
    inc     rbx

.next:
    pop     rcx
    inc     ecx
    jmp     .loop

.end_loop:
    test    rbx, rbx
    jnz     .send_end
    mov     rdi, r12
    lea     rsi, [str_no_loans]
    call    send_str
.send_end:
    mov     rdi, r12
    lea     rsi, [str_end]
    call    send_str

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_rate:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12d, edi
    mov     r13, rsi               
    mov     r14, rdx               


    cmp     r14, 1
    jl      .bad_rating
    cmp     r14, 5
    jg      .bad_rating


    mov     rdi, r13
    call    find_book_by_id
    test    rax, rax
    jz      .no_book
    mov     rbx, rax              


    add     [rbx + B_RSUM], r14d
    inc     dword [rbx + B_RCOUNT]


    mov     eax, [rbx + B_RSUM]
    xor     edx, edx
    div     dword [rbx + B_RCOUNT]  
    mov     r13d, eax              

    lea     rdi, [fmt_buf]
    lea     rsi, [str_rated_ok]
    call    append_str           
    mov     rdi, rax
    mov     esi, r13d
    call    append_int             
    mov     rdi, rax
    lea     rsi, [str_of5nl]
    call    append_str              
    mov     byte [rax], 0           

    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str
    jmp     .ret

.bad_rating:
    mov     rdi, r12
    lea     rsi, [err_bad_rating]
    call    send_str
    jmp     .ret
.no_book:
    mov     rdi, r12
    lea     rsi, [err_no_book]
    call    send_str

.ret:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_review:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, edi
    mov     r13, rsi                
    mov     r14, rdx                
    mov     r15, rcx                

    mov     rdi, r13
    call    find_book_by_id
    test    rax, rax
    jz      .no_book

    mov     rbx, [db_ptr]
    mov     ecx, [rbx + DB_RVC]
    cmp     ecx, MAX_REVIEWS
    jge     .db_full

    mov     rax, rcx
    imul    rax, REVIEW_SZ
    lea     rbx, [rbx + DB_REVIEWS + rax]

    mov     [rbx + RV_BOOK],   r13d
    mov     [rbx + RV_READER], r15d
    mov     dword [rbx + RV_RATING], 0  


    lea     rdi, [rbx + RV_TEXT]
    mov     rsi, r14
    mov     rdx, 255
    call    strncpy

    mov     rbx, [db_ptr]
    inc     dword [rbx + DB_RVC]

    mov     rdi, r12
    lea     rsi, [str_review_ok]
    call    send_str
    jmp     .ret

.no_book:
    mov     rdi, r12
    lea     rsi, [err_no_book]
    call    send_str
    jmp     .ret
.db_full:
    mov     rdi, r12
    lea     rsi, [err_db_full]
    call    send_str

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_reviews:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12d, edi
    mov     r13, rsi
    mov     r14, [db_ptr]
    mov     r15d, [r14 + DB_RVC]

    xor     rbx, rbx
    xor     ecx, ecx

.loop:
    cmp     ecx, r15d
    jge     .end_loop

    push    rcx
    mov     rax, rcx
    imul    rax, REVIEW_SZ
    lea     rdx, [r14 + DB_REVIEWS + rax]

    mov     eax, [rdx + RV_BOOK]
    cmp     rax, r13
    jne     .next


    lea     rdi, [fmt_buf]
    lea     rsi, [str_reader_lbl]
    call    append_str
    mov     rdi, rax
    mov     esi, [rdx + RV_READER]
    push    rdx                     
    call    append_int
    pop     rdx                     
    mov     rdi, rax
    mov     esi, ':'
    call    append_char
    mov     rdi, rax
    mov     esi, ' '
    call    append_char
    mov     rdi, rax
    lea     rsi, [rdx + RV_TEXT]
    call    append_str
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str
    inc     rbx

.next:
    pop     rcx
    inc     ecx
    jmp     .loop

.end_loop:
    test    rbx, rbx
    jnz     .send_end
    mov     rdi, r12
    lea     rsi, [str_no_reviews]
    call    send_str
.send_end:
    mov     rdi, r12
    lea     rsi, [str_end]
    call    send_str

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_register:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14


    mov     r12d, edi               
    mov     r13, rsi                

    mov     r14, [db_ptr]
    mov     ecx, [r14 + DB_RC]
    cmp     ecx, MAX_READERS
    jge     .db_full


    mov     eax, ecx
    imul    eax, READER_SZ
    lea     rbx, [r14 + DB_READERS + rax]

    ; R_ID = count + 1
    inc     ecx
    mov     [rbx + R_ID], ecx


    lea     rdi, [rbx + R_NAME]
    mov     rsi, r13
    mov     rdx, 63
    call    strncpy


    mov     byte [rbx + R_EMAIL], 0
    mov     dword [rbx + R_LOANS], 0


    mov     eax, [r14 + DB_RC]
    inc     eax
    mov     [r14 + DB_RC], eax


    lea     rdi, [fmt_buf]
    lea     rsi, [str_reg_ok]
    call    append_str              
    mov     rdi, rax
    mov     esi, [rbx + R_ID]
    push    rbx                     
    call    append_int
    pop     rbx
    mov     rdi, rax
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    mov     rdi, r12
    lea     rsi, [fmt_buf]
    call    send_str
    jmp     .ret

.db_full:
    mov     rdi, r12
    lea     rsi, [err_db_full]
    call    send_str

.ret:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


format_book:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12, rdi                
    mov     r13, rsi                


    mov     rdi, r12
    mov     esi, '['
    call    append_char
    mov     r12, rax

    mov     rdi, r12
    mov     esi, [r13 + B_ID]
    call    append_int
    mov     r12, rax

    mov     rdi, r12
    mov     esi, ']'
    call    append_char
    mov     r12, rax

    mov     rdi, r12
    mov     esi, ' '
    call    append_char
    mov     r12, rax


    mov     rdi, r12
    lea     rsi, [r13 + B_TITLE]
    call    append_str
    mov     r12, rax

    mov     rdi, r12
    lea     rsi, [str_sep]
    call    append_str
    mov     r12, rax


    mov     rdi, r12
    lea     rsi, [r13 + B_AUTHOR]
    call    append_str
    mov     r12, rax

    mov     rdi, r12
    lea     rsi, [str_sep]
    call    append_str
    mov     r12, rax


    mov     rdi, r12
    mov     esi, [r13 + B_YEAR]
    call    append_int
    mov     r12, rax

    mov     rdi, r12
    lea     rsi, [str_sep]
    call    append_str
    mov     r12, rax


    mov     rdi, r12
    mov     esi, [r13 + B_AVAIL]
    call    append_int
    mov     r12, rax

    mov     rdi, r12
    mov     esi, '/'
    call    append_char
    mov     r12, rax

    mov     rdi, r12
    mov     esi, [r13 + B_TOTAL]
    call    append_int
    mov     r12, rax


    cmp     dword [r13 + B_RCOUNT], 0
    je      .no_rat
    mov     rdi, r12
    lea     rsi, [str_sep]
    call    append_str
    mov     r12, rax
    mov     rdi, r12
    lea     rsi, [str_star]
    call    append_str
    mov     r12, rax
    mov     eax, [r13 + B_RSUM]
    xor     edx, edx
    div     dword [r13 + B_RCOUNT]  
    mov     rdi, r12
    mov     esi, eax
    call    append_int              
    mov     r12, rax
.no_rat:
    mov     rdi, r12
    mov     esi, 10
    call    append_char
    mov     byte [rax], 0

    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


find_book_by_id:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12d, edi
    mov     r13, [db_ptr]
    mov     ecx, [r13 + DB_BC]
    xor     rbx, rbx

.loop:
    cmp     rbx, rcx
    jge     .nf

    mov     rax, rbx
    imul    rax, BOOK_SZ
    lea     rax, [r13 + DB_BOOKS + rax]
    cmp     dword [rax + B_ID], r12d
    je      .found

    inc     rbx
    jmp     .loop

.nf:
    xor     eax, eax
    jmp     .ret
.found:
    ; rax уже = указатель
.ret:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret

find_reader_by_id:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13

    mov     r12d, edi
    mov     r13, [db_ptr]
    mov     ecx, [r13 + DB_RC]
    xor     rbx, rbx

.loop:
    cmp     rbx, rcx
    jge     .nf

    mov     rax, rbx
    imul    rax, READER_SZ
    lea     rax, [r13 + DB_READERS + rax]
    cmp     dword [rax + R_ID], r12d
    je      .found

    inc     rbx
    jmp     .loop

.nf:
    xor     eax, eax
    jmp     .ret
.found:
.ret:
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


find_active_loan:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12d, edi
    mov     r13d, esi
    mov     r14, [db_ptr]
    mov     ecx, [r14 + DB_LC]
    xor     rbx, rbx

.loop:
    cmp     rbx, rcx
    jge     .nf

    mov     rax, rbx
    imul    rax, LOAN_SZ
    lea     rax, [r14 + DB_LOANS + rax]

    cmp     byte [rax + L_STATUS], 0
    jne     .next
    cmp     dword [rax + L_BOOK], r12d
    jne     .next
    cmp     dword [rax + L_READER], r13d
    jne     .next
    jmp     .found

.next:
    inc     rbx
    jmp     .loop
.nf:
    xor     eax, eax
    jmp     .ret
.found:
.ret:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


cmd_match:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     rbx, rdi
    mov     r12, rsi

    mov     rdi, r12
    call    strlen
    mov     rcx, rax              

    mov     rdi, rbx
    mov     rsi, r12
    mov     rdx, rcx
    call    strncmp_n
    test    rax, rax
    jnz     .no

    movzx   eax, byte [rbx + rcx]
    cmp     al, ' '
    je      .yes
    cmp     al, 0
    je      .yes
    cmp     al, 10
    je      .yes
    cmp     al, 13
    je      .yes

.no:
    xor     eax, eax
    jmp     .ret
.yes:
    mov     eax, 1
.ret:
    pop     r12
    pop     rbx
    pop     rbp
    ret


atoi:
parse_int:
    xor     eax, eax
.loop:
    movzx   ecx, byte [rdi]
    sub     ecx, '0'
    jl      .done
    cmp     ecx, 9
    jg      .done
    imul    rax, 10
    add     rax, rcx
    inc     rdi
    jmp     .loop
.done:
    ret


strlen:
    xor     eax, eax
.loop:
    cmp     byte [rdi + rax], 0
    je      .done
    inc     rax
    jmp     .loop
.done:
    ret

strncpy:
    push    rcx
    mov     rcx, rdx
    test    rcx, rcx
    jz      .done
.loop:
    movzx   eax, byte [rsi]
    mov     [rdi], al
    test    al, al
    jz      .zero_pad
    inc     rdi
    inc     rsi
    dec     rcx
    jnz     .loop
    jmp     .done
.zero_pad:
    inc     rdi
    dec     rcx
    jz      .done
.pad:
    mov     byte [rdi], 0
    inc     rdi
    dec     rcx
    jnz     .pad
.done:
    pop     rcx
    ret


strncmp_n:
    xor     eax, eax
    test    rdx, rdx
    jz      .done
.loop:
    movzx   ecx, byte [rdi]
    movzx   eax, byte [rsi]
    sub     eax, ecx
    jnz     .done
    test    ecx, ecx
    jz      .done
    inc     rdi
    inc     rsi
    dec     rdx
    jnz     .loop
.done:
    ret


strstr_ci:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rdi
    mov     r13, rsi

    mov     rdi, r13
    call    strlen
    mov     r14, rax               

    test    r14, r14
    jz      .found_start

    mov     rdi, r12
    call    strlen
    mov     r15, rax             

    xor     rbx, rbx              

.outer:
    mov     rax, r15
    sub     rax, rbx
    cmp     rax, r14
    jl      .nf

    xor     rcx, rcx               
.inner:
    cmp     rcx, r14
    jge     .match

    lea     rdx, [rbx + rcx]         
    movzx   eax, byte [r12 + rdx]
    call    to_lower_al
    push    rax
    movzx   eax, byte [r13 + rcx]
    call    to_lower_al
    pop     rdx
    cmp     al, dl
    jne     .no_match
    inc     rcx
    jmp     .inner

.match:
    lea     rax, [r12 + rbx]
    jmp     .ret
.no_match:
    inc     rbx
    jmp     .outer

.nf:
    xor     eax, eax
    jmp     .ret
.found_start:
    mov     rax, r12

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


to_lower_al:
    cmp     al, 'A'
    jl      .done
    cmp     al, 'Z'
    jg      .done
    add     al, 32
.done:
    ret


append_str:
    mov     rax, rdi
.loop:
    movzx   ecx, byte [rsi]
    test    cl, cl
    jz      .done
    mov     [rax], cl
    inc     rax
    inc     rsi
    jmp     .loop
.done:
    ret


append_int:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 24
    push    rbx
    push    r12

    mov     rbx, rdi
    mov     r12, rsi

    test    r12, r12
    jnz     .nonzero
    mov     byte [rbx], '0'
    inc     rbx
    jmp     .done

.nonzero:
    lea     rdi, [rbp - 1]
    mov     byte [rdi], 0
    xor     ecx, ecx
    mov     rax, r12

.digit:
    xor     rdx, rdx
    mov     r8, 10
    div     r8
    add     dl, '0'
    dec     rdi
    mov     [rdi], dl
    inc     ecx
    test    rax, rax
    jnz     .digit


    mov     rsi, rdi
    mov     rdi, rbx
    rep     movsb
    mov     rbx, rdi

.done:
    mov     rax, rbx

    pop     r12
    pop     rbx
    add     rsp, 24
    pop     rbp
    ret


append_char:
    mov     [rdi], sil
    lea     rax, [rdi + 1]
    ret


send_all:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12d, edi
    mov     r13, rsi
    mov     r14, rdx
    xor     rbx, rbx

.loop:
    cmp     rbx, r14
    jge     .done

    mov     eax, SYS_SENDTO
    mov     edi, r12d
    lea     rsi, [r13 + rbx]
    mov     rdx, r14
    sub     rdx, rbx
    xor     r10d, r10d
    xor     r8d, r8d
    xor     r9d, r9d
    syscall
    cmp     rax, 0
    jle     .done
    add     rbx, rax
    jmp     .loop

.done:
    mov     rax, rbx
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
    ret


send_str:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     r12d, edi
    mov     rbx, rsi

    mov     rdi, rbx
    call    strlen
    mov     rdx, rax

    mov     edi, r12d
    mov     rsi, rbx
    call    send_all

    pop     r12
    pop     rbx
    pop     rbp
    ret


recv_line:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8                  
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     r12d, edi
    mov     r13, rsi
    mov     r14, rdx
    xor     rbx, rbx

.loop:
    cmp     rbx, r14
    jge     .done

    mov     eax, SYS_READ
    mov     edi, r12d
    lea     rsi, [rbp - 8]
    mov     edx, 1
    syscall
    cmp     rax, 0
    jl      .err
    je      .done

    movzx   eax, byte [rbp - 8]
    cmp     al, 10                  
    je      .done
    cmp     al, 13                  
    je      .loop

    mov     [r13 + rbx], al
    inc     rbx
    jmp     .loop

.done:
    mov     byte [r13 + rbx], 0
    mov     rax, rbx
    jmp     .ret
.err:
    mov     rax, -1

.ret:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    add     rsp, 8
    pop     rbp
    ret


memset:
    push    rcx
    mov     al, sil
    mov     rcx, rdx
    rep     stosb
    pop     rcx
    ret


print_str:
    push    rbp
    mov     rbp, rsp
    push    rbx

    mov     rbx, rdi
    call    strlen
    mov     edx, eax
    mov     eax, SYS_WRITE
    mov     edi, 1
    mov     rsi, rbx
    syscall

    pop     rbx
    pop     rbp
    ret


segment readable writable


db_ptr      dq 0
srv_fd      dd 0
cli_fd      dd 0
opt_one     dd 1
srv_addr    rb 16
cli_addr    rb 16
cli_alen    dd 16


fmt_buf         rb 512


sb1t  db 'The C Programming Language', 0
sb1a  db 'Kernighan, Ritchie', 0
sb2t  db 'Operating Systems: Three Easy Pieces', 0
sb2a  db 'Arpaci-Dusseau', 0
sb3t  db 'Computer Systems: A Programmer Perspective', 0
sb3a  db 'Bryant, O Hallaron', 0
sb4t  db 'The Linux Programming Interface', 0
sb4a  db 'Michael Kerrisk', 0
sb5t  db 'Assembly Language Step-by-Step', 0
sb5a  db 'Jeff Duntemann', 0


sr1n  db 'Alice Ivanova', 0
sr1e  db 'alice@example.com', 0
sr2n  db 'Bob Petrov', 0
sr2e  db 'bob@example.com', 0


scmd_quit     db 'QUIT', 0
scmd_help     db 'HELP', 0
scmd_login    db 'LOGIN', 0
scmd_list     db 'LIST', 0
scmd_search   db 'SEARCH', 0
scmd_info     db 'INFO', 0
scmd_reserve  db 'RESERVE', 0
scmd_return   db 'RETURN', 0
scmd_myloans  db 'MYLOANS', 0
scmd_rate     db 'RATE', 0
scmd_review   db 'REVIEW', 0
scmd_reviews  db 'REVIEWS', 0
scmd_register db 'REGISTER', 0


str_banner    db '=== Online Library Server v1.0 (port 8080) ===', 10, 0
str_listening db 'Listening...', 10, 0
str_new_conn  db 'New client connected', 10, 0

str_welcome   db '=== Online Library === (HELP для списка команд)', 10, 0

str_help      db 'Commands:', 10
              db '  LOGIN <id>             - войти как читатель', 10
              db '  LIST                   - все книги', 10
              db '  SEARCH <запрос>        - поиск по названию/автору', 10
              db '  INFO <id>              - подробно о книге', 10
              db '  RESERVE <id>           - взять книгу', 10
              db '  RETURN <id>            - вернуть книгу', 10
              db '  MYLOANS                - мои абонементы', 10
              db '  RATE <id> <1-5>        - оценить книгу', 10
              db '  REVIEW <id> <текст>    - оставить отзыв', 10
              db '  REVIEWS <id>           - отзывы о книге', 10
              db '  REGISTER <имя>         - зарегистрироваться', 10
              db '  QUIT                    - отключиться', 10, 0

str_bye       db 'Goodbye!', 10, 0

str_list_hdr  db '--- Каталог библиотеки ---', 10, 0
str_end       db 'END', 10, 0
str_nl        db 10, 0
str_sep       db ' | ', 0
str_star      db '*', 0
str_rating_lbl db 'Rating: ', 0
str_of5       db '/5', 10, 0
str_of5nl     db '/5', 10, 0
str_ok_prefix  db 'OK ', 0
str_ok_login  db 'OK Logged in as: ', 0
str_reserved  db 'OK Book reserved successfully', 10, 0
str_returned  db 'OK Book returned successfully', 10, 0
str_rated_ok  db 'OK Rating saved. Avg: ', 0
str_review_ok  db 'OK Review saved', 10, 0
str_reg_ok     db 'OK Registered as reader #', 0
str_reader_lbl db 'Reader#', 0
str_no_loans  db 'OK No active loans', 10, 0
str_no_reviews db 'OK No reviews yet', 10, 0

err_mmap      db 'ERROR: mmap failed', 10, 0
err_sock      db 'ERROR: socket failed', 10, 0
err_bind      db 'ERROR: bind failed', 10, 0
err_listen    db 'ERROR: listen failed', 10, 0
err_unknown_cmd db 'ERR Unknown command. Type HELP.', 10, 0
err_no_reader db 'ERR Reader not found', 10, 0
err_no_book   db 'ERR Book not found', 10, 0
err_no_copies db 'ERR No copies available', 10, 0
err_already   db 'ERR You already have this book', 10, 0
err_db_full   db 'ERR Database full', 10, 0
err_no_loan   db 'ERR No active loan for this book', 10, 0
err_need_login db 'ERR Please LOGIN first', 10, 0
err_syntax    db 'ERR Syntax error', 10, 0
err_bad_rating db 'ERR Rating must be 1-5', 10, 0
err_not_found db 'OK No books found', 10, 0
err_no_books  db 'OK Library is empty', 10, 0
