;------------------------------------------------------------------------------------------
;Team MOV: Vincent, Jinbin, and Kanwar
;
;Your server IP - 140.238.134.184
;Your port – 10205
;
;To test, type in “nc <ip> <port>” in your VM
;The task – you will sort the received data from lowest to highest using gnome sort
;------------------------------------------------------------------------------------------
;Portions of the code have been taken from test_server_lh_8080.nasm created by Lubos Kuzma.
;------------------------------------------------------------------------------------------
;2022-11-30: this is unfinished and is not currently working.

struc sockaddr_in_type
    .sin_family: resw 1
    .sin_port: resw 1
    .sin_addr: resd 1
    .sin_zero: resd 2
endstruc

; network is big endianess. You must flip byte order. 

sockaddr_in:
    istruc sockaddr_in_type
        at sockaddr_in_type_sin_family, dw 0x02 
        ; the bottom two are to be set with the port and server you were given to connect to.
        at sockaddr_in_type_sin_port, dw 0x901f ; this is dedault port 8080. 0x901f flipped = 0x1f90. Change it so it has the port of your server
        at sockaddr_in_type_sin_addr. dd 0x00   ; reorder the bytes so that it matches your ip address that you were given. 
    iend
sockaddr_in_length: equ $ - sockaddr_in

section .bss
    ;global variables
    socket_fd: resq 1
    read_buffer_fd: resq 1
    chars_recieved: resq 1
    client_live: resq 1

section .text
    global _start

_start:
    push rbp
    mov rbp, rsp

    mov qword [client_live], 0x00 ; setting client_live to false to start with. 

    add rsp, 0x8 ; restore stack

call _network.init
call _network.listen

.retry:
    call _network_accept

_network:
    .init:
        mov rax, 0x29
        mov rdi, 0x02
        mov rsi, 0x01
        mov rdx, 0x00
        syscall
        cmp rax, 0x00 ; if it is 00 it will give error code meaning it failed. Should return socket fd
        jl _socket_failed ; jump if negitive
        mov [socket_fd], rax
        call _socket_created

        ;bind address and port
        mov rax, 0x31 ;bind syscall
        mov rdi, qword [socket_fd]
        mov rsi, sockaddr_in
        mov rdx, sockaddr_in_length
        syscall
        cmp rax, 0x00
        jl _bind_failed
        call _bind_created
        ret

    .listen:
    mov rax, 0x32 ; listen syscall
    mov rdi, qword [socket_fd]
    mov rsi, 0x03
    syscall

    cmp rax, 0x00
    jl _listen_failed
    call _listen_created
    ret

    .accept:
        mov rax, 0x28 ; accept syscall
        mov rdi, qword [socket_fd]
        mov rsi, sockaddr_in
        mov rdx, peer_address_length
        syscall

        mov qword [read_buffer_fd], rax
        mov qword [client_live], 0x1
        ret

    .read:
        mov rax, 0x00 ; read syscall
        mov rdi, qword [read_buffer_fd]
        mov rsi, msg_buf
        mov rdx, 1024
        syscall
    
    mov qword [chars_recieved], rax
    ret

    .close:
        mov rax, 0x3                        ; close syscall
        mov rdi, qword [read_buffer_fd]     ; read buffer fd
        syscall
        
        cmp rax, 0x0
        jne _network.close.return
        call _socket_closed
        
        .close.return:
        ret

_write_text_to_socket:
        
    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length
    ; [rbp + 0x20] -> fd of the socket

    mov rax, 0x1
    mov rdi, [rbp + 0x20]
    mov rsi, [rbp + 0x10]
    mov rdx, [rbp + 0x18]
    syscall

    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret 0x18 ; clean up the stack upon return - not strictly following C Calling Convention    

