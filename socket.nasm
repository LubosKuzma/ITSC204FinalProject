; ITSC204 - Final Project Client Side
; based on socket networking system calls
; x86-64 Linux
; Created by Jinbin Han
; Team MOV: Vincent, Jinbin, and Kanwar
; SADT, SAIT
; on December 2022

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
    send_command:   db "100", 0xA   ; DO NOT TERMINATE WITH 0x00
    send_command_l: equ $ - send_command
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
            at sockaddr_in_type.sin_port,    dw 0x901F          ;(DEFAULT, passed on stack) port in hex and big endian order, 8080 -> 0x901F
            at sockaddr_in_type.sin_addr,    dd 0x0100007F      ;(DEFAULT) 00 -> any address, address 127.0.0.1 -> 0x0100007F
        iend
    sockaddr_in_l:  equ $ - sockaddr_in
section .bss
    rec_buffer: resb 0x101               ; 0x100 + 1 for null terminator  ; 0x100 is the max size of the buffer
    socket_fd: resq 1                    ; 0x8 bytes for the socket file descriptor

section .text


; global _start


_init_socket:

    ; create a socket
    mov rax, 0x29                       ; socket syscall
    mov rdi, 0x02                       ; int domain - AF_INET = 2, AF_LOCAL = 1
    mov rsi, 0x01                       ; int type - SOCK_STREAM = 1
    mov rdx, 0x00                       ; int protocol - 0 for default
    syscall  
    ;judge if the socket is created successfully
    ;if result is nagative then jump to error, otherwise save the file descriptor to 
    cmp rax, 0x00
    jl _socket_created_failed          ; jump to socket created failed
    mov [socket_fd],rax                ; save the file descriptor to socket_fd
    call _socket_created_successfully

    ; connect to the server
    mov rax, 0x2A                       ; connect syscall
    mov rdi, [socket_fd]                ; int sockfd
    mov rsi, sockaddr_in                ; struct sockaddr *addr
    mov rdx, sockaddr_in_l                       ; socklen_t addrlen
    syscall
    ;judge if the socket is connected successfully
    ;if result is nagative then jump to error, otherwise save the file descriptor to
    cmp rax, 0x00
    jl _socket_connected_failed         ; jump to socket connected failed
    call _socket_connected_successfully ; jump to socket connected successfully

    ; call _send_rec                      ; send and receive data


    ; call _exit
    ret

_send_rec:
    ; based on sendto syscall
    mov rax, 0x2C                       ; sendmsg syscall
    mov rdi, [socket_fd]                ; int fd - socket file descriptor
    mov rsi, send_command               ; int type - SOCK_STREAM = 1
    mov rdx, send_command_l             ; int protocol is 0
    mov r10, MSG_DONTWAIT               ; flags - MSG_DONTWAIT = 0x40, MSG_WAITALL = 0x100
    mov r8, sockaddr_in                 ; dest_addr - struct sockaddr *dest_addr
    mov r9, sockaddr_in_l               ; addrlen - socklen_t addrlen
    syscall
    ; using receivefrom syscall
    mov rax, 0x2D                       ; receivefrom syscall
    mov rdi, [socket_fd]                ; int sockfd - socket file descriptor
    mov rsi, rec_buffer                 ; buffer
    mov rdx, 0x100                      ; must match the requested number of bytes
    mov r10, MSG_WAITALL                ; flags - MSG_DONTWAIT = 0x40, MSG_WAITALL = 0x100
    mov r8, 0x00                        ; src_addr - struct sockaddr *src_addr
    mov r9, 0x00                        ; addrlen - socklen_t *addrlen
    syscall
    .rec:                               ; setup break in gdb by "b _send_rec.rec" to examine the buffer
    ; your rec_buffer will now be filled with 0x100 bytes
    ;print the buffer
    ; mov rax, 0x01                       ; write syscall
    ; mov rdi, 0x01                       ; fd - 1 for stdout
    ; mov rsi, rec_buffer                 ; buffer
    ; mov rdx, 0x100                      ; must match the requested number of bytes
    ; syscall
    ; ret
    ret
    ; jmp _exit

_socket_created_failed:
    ; print socket failed
    push socket_f_msg_l
    push socket_f_msg
    call _print
    jmp _exit

_socket_created_successfully:
    ; print socket created
    push socket_t_msg_l
    push socket_t_msg
    call _print
    ret
_socket_connected_failed:
    ; print bind failed
    push con_f_msg_l
    push con_f_msg
    call _print
    jmp _exit
_socket_connected_successfully:
    ; print bind created
    push con_t_msg_l
    push con_t_msg
    call _print
    ret
_print:
    ; prologue
    push rbp                        ; save the base pointer
    mov rbp, rsp                    ; set the base pointer to the stack pointer
    push rdi                        ; save the first argument
    push rsi                        ; save the second argument
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
    mov rax, 60
    mov rdi, 0
    syscall


