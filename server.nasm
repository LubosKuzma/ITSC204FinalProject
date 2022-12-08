;------------------------------------------------------------------------------------------
;ITSC204 - Final Project Gnome Sort
;Team MOV: Vincent, Jinbin, and Kanwar
;SAIT
;Client server:
;Your server IP - 140.238.134.184
;Your port – 10205
;
;Notes:
;To test, type in “nc <ip> <port>” in your VM
;The task – you will sort the received data from lowest to highest using gnome sort
;------------------------------------------------------------------------------------------
;Portions of the code have been taken from test_server_lh_8080.nasm created by Lubos Kuzma.
;------------------------------------------------------------------------------------------
;2022-11-30: this is unfinished and is not currently working.

struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1
    .sin_port:          resw 1
    .sin_addr:          resd 1
    .sin_zero:          resd 2          ; padding       
endstruc

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

; network is big endianess. You must flip byte order. 
; port flipped = 0xDD27
; address flipped = 0xA81B81D8A620

sockaddr_in:
    istruc sockaddr_in_type
        at sockaddr_in_type_sin_family, dw 0x02 
        ; the bottom two are to be set with the port and server you were given to connect to.
        at sockaddr_in_type_sin_port, dw 0xDD27 ; 0xDD27 is port 10205
        at sockaddr_in_type_sin_addr. dd 0xA81B81D8A620  ; ip address: 140.238.134.184
    iend
sockaddr_in_length: equ $ - sockaddr_in

    
section .bss
    rec_buffer:              resb 0x101
    socket_fd:               resq 1             ; socket file descriptor

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
        mov [socket_fd], rax                 ; save the socket fd to basepointer
        call _socket_created
        .connect:
        ; connect, based on connect(2) syscall
        mov rax, 0x2a                       ; connect syscall
        mov rdi, qword [socket_fd]                ; int socketfd
        mov rsi, sockaddr_in                       
        mov rdx, sockaddr_in_l                     
        syscall     
        cmp rax, 0x00
        jl _connect_failed
        call _connect_created
        ret

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
    .rec:                               ; setup break in gdb by "b _send_rec.rec" to examine the buffer
    ; your rec_buffer will now be filled with 0x100 bytes
    
    jmp _exit
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
_connect_failed:
    ; print bind failed
    push con_f_msg_l
    push con_f_msg
    call _print
    jmp _exit
_connect_created:
    ; print bind created
    push con_t_msg_l
    push con_t_msg
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

_ascii_to_hex:
    ; takes the first 8 bytes of the buffer in ascii form
    ; returns hex representation in RAX
    ; follows C Call Convention

    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length
    
    xor rbx, rbx        ; clear counter
    xor rcx, rcx        ; clear rcx
    .loop:
        mov rdx, qword [rbp + 0x10]
        mov al, byte [rdx + rbx] ; load ascii payload
        ; skip conversion if loaded less than 0x30 (non ASCII)
        cmp rax, 0x30
        jl .end_loop
        ; if letter, subtract 0x37
        cmp rax, 0x40
        jg .letter 
        sub rax, 0x30
        jmp .end_bias
    .letter:
        sub rax, 0x37
        jmp .end_bias

    .end_bias:
        or rcx, rax
        shl rcx, 0x04
    .end_loop:
        inc rbx
        cmp rbx, 0x08
        jnz .loop

        shr rcx, 0x4
        mov rax, rcx

    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret
    
_exit:
    ;call _network.close
    ;call _network.shutdown
    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
