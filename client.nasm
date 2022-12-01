;; Data definitions
struc sockaddr_in_type
    .sin_family resw 1
    .sin_port   resw 1
    .sin_addr   resd 1
    .sin_zero   resd 2
endstruc

section .bss
    ; global variables
    socket_fd:               resq 1             ; socket file descriptor

section .data

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    bind_f_msg:   db "Socket failed to bind.", 0xA, 0x0
    bind_f_msg_l: equ $ - bind_f_msg

    bind_t_msg:   db "Socket bound.", 0xA, 0x0
    bind_t_msg_l: equ $ - bind_t_msg

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0xD927          ;(DEFAULT, passed on stack) port in hex and big endian order, 8080 -> 0x901F
            at sockaddr_in_type.sin_addr,    dd 0xb886ee8c       ;(DEFAULT) 00 -> any address, address 127.0.0.1 -> 0x0100007F

        iend
    sockaddr_in_l: equ $ - sockaddr_in

section .text
    global _start

_start:
    ; Initialize socket value to 0, used for cleanup 
    mov      word [socket_fd], 0

    ; Initialize socket
    call     _socket
    jmp _close_sock

_socket:
    push rbp
    mov rbp, rsp
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

    ; bind, use sockaddr_in struct
    ;       int bind(int sockfd, const struct sockaddr *addr,
    ;            socklen_t addrlen);
    mov rax, 0x31                       ; bind syscall
    mov rdi, qword [socket_fd]          ; sfd
    mov rsi, sockaddr_in                ; sockaddr struct pointer
    mov rdx, sockaddr_in_l              ; address length 
    syscall
    cmp rax, 0x00
    jl _bind_failed
    call _bind_created

    ; epilogue
    mov rsp, rbp
    pop rbp
    ret

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

_socket_failed:
    ; print socket failed
    push socket_f_msg_l
    push socket_f_msg
    call _print
    jmp _exit

_socket_created:
    ; print socket created
    push socket_t_msg_l
    push socket_t_msg
    call _print
    ret

_bind_failed:
    ; print bind failed
    push bind_f_msg_l
    push bind_f_msg
    call _print
    jmp _exit

_bind_created:
    ; print bind created
    push bind_t_msg_l
    push bind_t_msg
    call _print
    ret

; Performs sys_close on the socket in rdi
_close_sock:
    mov     rax, 3        ; SYS_CLOSE
    syscall

_exit:
    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
