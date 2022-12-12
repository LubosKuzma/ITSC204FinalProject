;making a structure in assembly just like we do it in c 
;*****************************
struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1 ;tells us which family are we reffering to 
    .sin_port:          resw 1 ;for port number in bytes 
    .sin_addr:          resd 1 ;for ip adress in bytes 
    .sin_zero:          resd 2 ; padding(not in use right now )      
endstruc ;struct end 

 

;*****************************
SIGPIPE equ 0xD
SIG_IGN equ 0x1
NULL    equ 0x0

 

MSG_DONTWAIT equ 0x40
MSG_WAITALL equ 0x100
section .bss
    ;global variables 
    msg_biffer:               resb 1024 ; number of bytes to read(i guess) more than this will result in buffer overflow
    server_live:              resq 1    ; T/F is server connected
    socket_fd:                resq 1    ; socket file descriptor
    random_byte:             resb 1     ; reserve 1 byte
    chars_received           resq 1     ; number of characters received from socket
    openfile_fd:            resq 1      ;file discripter for the file that we will be opening to save the bytes 
    rec_buffer:              resb 0x101

 

section .text
global _start: 

 

_start:

 

     ; set the SIGPIPE signal to ignore
    mov rdi, rsp
    push SIG_IGN        ; new action -> SIG_IGN 
    mov rsi, rsp        ; pointer to action struct
    mov edx, NULL       ; old action -> NULL
    mov edi, SIGPIPE    ; SIGPIPE    
    mov rax, 0xD        ; rt_sigaction syscall
    mov r10, 0x8        ; size of struc (8 bytes)
    syscall

 

    add rsp, 0x8        ; restore stack

 

    push rbp ;pushing the base pointer 
    mov rbp, rsp ;copying the stack pointer to the base poiner 
    call _network.init
    call _send_rec

 


section .data

 


    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

 

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

 

    listen_f_msg:   db "Failed to start listening.", 0xA, 0x0
    listen_f_msg_l: equ $ - listen_f_msg

 

    listen_t_msg:   db "Listening.", 0xA, 0x0
    listen_t_msg_l: equ $ - listen_t_msg

 

    connect_f_msg:   db "Socket failed to bind.", 0xA, 0x0
    connect_f_msg_l: equ $ - connect_f_msg

 

    connect_t_msg:   db "Socket bound.", 0xA, 0x0
    connect_t_msg_l: equ $ - connect_t_msg

 

    send_command:   db "100", 0xA   ; DO NOT TERMINATE WITH 0x00
    send_command_l: equ $ - send_command
;passing the values to the variables(so called) in the struct that we initialized before
    sockaddr_in: 
            istruc sockaddr_in_type 

 

                at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 ;
                at sockaddr_in_type.sin_port,    dw 0xDB27          ;(DEFAULT, passed on stack) port in hex and big endian order, 10203 -> 0xDB27
                at sockaddr_in_type.sin_addr,    dd 0xB886EE8C    ;(DEFAULT) 00 -> any address, address - 140.238.134.184 -> 0xA81BD8A620 (here the adress of the server we wil be connecting to)

 

            iend
        sockaddr_in_l:  equ $ - sockaddr_in

 

 

_network:
    .init:
        ; socket, based on IF_INET to get tcp
        mov rax, 0x29          ; socket syscall(creating a socket)
        mov rdi, 0x02          ; int domain - AF_INET = 2, AF_LOCAL = 1 (2 because we are dealing with internet socket)
        mov rsi, 0x01          ; int type - SOCK_STREAM = 1
        mov rdx, 0x00          ; int protocol is 0
        syscall     
        ;after this syscall the rax register willl have the file discripter 
        ;now always check the rax register must be 3 or more cannot be (0,1,2)
        cmp rax, 0x00           ;compairing to check if it is zero or not 
        jl _socket_failed                 ; jump if negative
        mov [socket_fd], rax              ; else save the socket fd to basepointer
        call _socket_created
    
        mov rax, 0x2A                       ; connetction syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, sockaddr_in                ; sockaddr struct pointer
        mov rdx, sockaddr_in_l              ; address length 
        syscall
        cmp rax, 0x00
        jl _connection_failed
        call _connection_created

 

_send_rec:
    ; based on sendto syscall
    mov rax, 0x2C                       ; sendmsg syscall
    mov rdi, [socket_fd]                       ; int fd
    mov rsi, send_command                      ; int type - SOCK_STREAM = 1
    mov rdx, send_command_l                       ; int protocol is 0
    mov r10, MSG_DONTWAIT
    mov r8, sockaddr_in
    mov r9, sockaddr_in_l
    syscall
  
    ; using receivefrom syscall
    mov rax, 0x2D
    mov rdi, [socket_fd]
    mov rsi, rec_buffer
    mov rdx, 0x100                      ; must match the requested number of bytes
    mov r10, MSG_WAITALL                ; important
    mov r8, 0x00
    mov r9, 0x00
    syscall
    .rec:                               
    ; setup break in gdb by "b _send_rec.rec" to examine the buffer
    ; your rec_buffer will now be filled with 0x100 bytes
    
    jmp _exit

 

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
    ret 0x10                                ; clean up the stack upon return - not strictly following C Calling Convention

 


_exit:
    ;call _network.close
    ;call _network.shutdown

 

    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall

 

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

 

_connection_failed:
    ; print connection failed
    push connect_f_msg_l
    push connect_f_msg
    call _print
    jmp _exit

 

_connection_created:
    ; print connection created
    push connect_t_msg_l
    push connect_t_msg
    call _print
    ret