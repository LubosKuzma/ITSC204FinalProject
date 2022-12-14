;Group Intel: Mateo Manzano, Saef Al-absawi, Ahmad Sultani
;Port: 10204 = 0xDC27
;Server IP: 140.238.134.184 = 0xB886EE8C

;*****************************
struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1
    .sin_port:          resw 1
    .sin_addr:          resd 1
    .sin_zero:          resd 2          ; padding       
endstruc
;*****************************
MSG_DONTWAIT equ 0x40
MSG_WAITALL equ 0x100
section .data

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg
    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg
    con_f_msg:   db "Socket failed to connect.", 0xA, 0x0
    con_f_msg_l: equ $ - con_f_msg
    con_t_msg:   db "Socket connected.", 0xA, 0x0
    con_t_msg_l: equ $ - con_t_msg
    bind_t_msg:   db "Socket bound.", 0xA, 0x0
    bind_t_msg_l: equ $ - bind_t_msg
    bind_f_msg:   db "Socket failed to bind.", 0xA, 0x0
    bind_f_msg_l: equ $ - bind_f_msg

 

        sockaddr_in: 
        istruc sockaddr_in_type 
            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0x901F          ;OUR GROUP PORT IS 0xDC27 BUT WE WERE NOT ABLE TO MAKE IT WORK WITH IT
            at sockaddr_in_type.sin_addr,    dd 0x0100007F      ;OUR GROUP SERVER IP IS 0xB886EE8C BUT WE WERE NOT ABLE TO MAKE IT WORK WITH IT
        iend
    sockaddr_in_l:  equ $ - sockaddr_in

 

section .bss
    rec_buffer:              resb 0x100
    socket_fd:               resq 1             ; socket file descriptor
    send_command:            resb 0x4           ; reserve 0x4 bytes for send command instruction 
    buf:                     resb 0x20          ; reserve 0x20 bytes for buffer 

 

section .text
    global _start
_start:
    push rbp
    mov rbp, rsp
    call _network.init
    call _send_rec

 

    jmp _exit
_network:
        .init:
                                            ; socket, based on IF_INET to get tcp
        mov rax, 0x29                       ; socket syscall
        mov rdi, 0x02                       ; int domain - AF_INET = 2, AF_LOCAL = 1
        mov rsi, 0x01                       ; int type - SOCK_STREAM = 1
        mov rdx, 0x00                       ; int protocol is 0
        syscall     
        cmp rax, 0x00
        jl _socket_failed                   ; jump if negative
        mov [socket_fd], rax                ; save the socket fd to basepointer
        call _socket_created
        .connect:
        ; connect, based on connect(2) syscall
        mov rax, 0x2a                       ; connect syscall
        mov rdi, qword [socket_fd]          ; int socketfd
        mov rsi, sockaddr_in                       
        mov rdx, sockaddr_in_l                     
        syscall     
        cmp rax, 0x00
        jl _connect_failed
        call _connect_created
        ret

 

_send_rec:
    
 

    mov rax, 0x0                      
    mov rdi, 0x0
    mov rsi, send_command             ;move send_command instruction with 0x4 bytes reserved to rsi register
    mov rdx, 0x4
    syscall



    ; based on sendto syscall
    mov rax, 0x2C                     ; sendmsg syscall
    mov rdi, [socket_fd]              ; int fd
    mov rsi, send_command             ; int type - SOCK_STREAM = 1
    mov rdx, 0x4                      ; int protocol is 0
    mov r10, MSG_DONTWAIT
    mov r8, sockaddr_in
    mov r9, sockaddr_in_l

    syscall

    ; using receivefrom syscall
    mov rax, 0x2D
    mov rdi, [socket_fd]
    mov rsi, rec_buffer
    mov rdx, 0x100                    ; must match the requested number of bytes
    mov r10, MSG_WAITALL              ; important
    mov r8, 0x00
    mov r9, 0x00
    syscall
    .rec:                             ; setup break in gdb by "b _send_rec.rec" to examine the buffer
                                      ; your rec_buffer will now be filled with 0x100 bytes

 

    mov rax, 0x1                      ; move 0x1 to 64 bytes register rax 
    mov rdi, 0x1
    mov rsi, rec_buffer               ; request movement of rec_buffer instruction to rsi register with reserved 0x100 bytes
    mov rdx, 0x100
    syscall                           ; system call

    jmp _exit

_socket_failed:                       ; failed socket signal
    push socket_f_msg_l               ; request 'socket failed to created' message
    push socket_f_msg
    call _print                       ; print 'socket failed to created' message
    jmp _exit                         ; jump exit if not accomplish

_socket_created:                      ; successful socket signal
    push socket_t_msg_l               ; request 'socket created' message
    push socket_t_msg
    call _print                       ; print 'socket created' message
    ret                               ; return if accomplish

_connect_failed:                      ; failed socket connection signal
    push con_f_msg_l                  ; request 'socket failed to connect' message
    push con_f_msg
    call _print                       ; print 'socket failed to created' message
    jmp _exit                         ; jump exit if not accomplish

_connect_created:                     ; succesful socket connection signal
    push con_t_msg_l                  ; request 'socket connected' message
    push con_t_msg
    call _print                       ; print 'socket connected' message
    ret                               ; return if accomplish

_bind_failed:                         ; failed socket binding signal
    push bind_f_msg_l                 ; request 'socket failed to bind' message
    push bind_f_msg
    call _print                       ; print 'socket failed to bind' message
    jmp _exit                         ; jump exit if not accomplish

_bind_created:                        ; succesful socket binding signal
    push bind_t_msg_l                 ; request 'socket bind' message
    push bind_t_msg 
    call _print                       ; print 'socket bind' message      
    ret                               ; return if accomplish  

 

_print:
    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length

    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, [rbp + 0x10]
    mov rdx, [rbp + 0x18]
    syscall
    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret 0x10 

_exit:
    ;call _network.close
    ;call _network.shutdown
    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall