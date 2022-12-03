;v1.03
SECTION .text
global  _start
 
_start:
    .Print_start:
    mov     rsi, 511            ;create file mod
    mov     rdi, filename       ;filename
    mov     rax, 0x55           ;creat syscall
    syscall
    cmp     rax, 0              ;if rax = 0, the file had exist.
    jz     .Print_No_file
    mov     [Handle], rax       ;save our file descriptor 
    jmp     .Print_IN_file      ;jump to print in file

    .Print_No_file:
    mov     rax, file_error
    call    strlen_cal
    mov     rdi, 0
    mov     rdx, rax
    mov     rsi, file_error     ;print "This file already exist, Please try again" in screen
    mov     rax, 1
    jmp     .Print_start

    .Print_IN_file:
    mov     rax, Nosort_notice  
    mov     r8, Nosort_notice
    call    strlen_cal
    call    print               ;print "This is beginning of No sort data:" in file

    ;mov     rax,               ;add nosort data pointer or register in there
    ;mov     r8,                ;add nosort data pointer or register in there
    ;call    strlen_cal
    ;call    print

    mov     rax, Sort_notice    
    mov     r8, Sort_notice
    call    strlen_cal      
    call    print               ;print "This is beginning of sort data:" in file

    ;mov     rax,               ;add sort data pointer or register in there
    ;mov     r8,                ;add sort data pointer or register in there
    ;call    strlen_cal
    ;call    print

exit:
    mov     rax, 60
    mov     rdi, 0
    syscall

print:
    mov     rdi, [Handle]
    mov     rdx, rax
    mov     rsi, r8
    mov     rax, 1
    syscall
    ret
strlen_cal:                     
    push    rbx             
    mov     rbx, rax       
    .nextchar:
    cmp     byte [rax], 0   
    jz      strlen_cal.finished        
    inc     rax            
    jmp     strlen_cal.nextchar        
    strlen_cal.finished:
    sub     rax, rbx		
    pop     rbx             
    ret                     
SECTION .data
filename db 'TeamNASM.txt', 0x0    ; the filename to create
file_error:  db "This file already exist, Please try again", 0xA, 0x0
Nosort_notice: db "This is beginning of No sort data:", 0xA, 0x0
Sort_notice: db "This is beginning of sort data:", 0x0
Handle dq 10