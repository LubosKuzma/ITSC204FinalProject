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
    .sin_family: resw 1
    .sin_port: resw 1
    .sin_addr: resd 1
    .sin_zero: resd 2
endstruc

section .data

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    bind_f_msg:   db "Socket failed to bind.", 0xA, 0x0
    bind_f_msg_l: equ $ - bind_f_msg

    bind_t_msg:   db "Socket bound.", 0xA, 0x0
    bind_t_msg_l: equ $ - bind_t_msg

    listen_f_msg:   db "Failed to start listening.", 0xA, 0x0
    listen_f_msg_l: equ $ - listen_f_msg

    listen_t_msg:   db "Listening.", 0xA, 0x0
    listen_t_msg_l: equ $ - listen_t_msg

    buffer_closed_msg:   db "Buffer closed.", 0xA, 0x0
    buffer_closed_msg_l: equ $ - buffer_closed_msg

    socket_closed_msg:   db "Socket closed.", 0xA, 0x0
    socket_closed_msg_l: equ $ - socket_closed_msg

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

    ; global variables
    peer_address_length:     resd 1             ; when Accept is created, the connecting peer will populate this with the address length
    msg_buf:                 resb 1024          ; message buffer
    random_byte:             resb 1             ; reserve 1 byte
    socket_fd:               resq 1             ; socket file descriptor
    read_buffer_fd           resq 1             ; file descriptor for read buffer
    chars_received           resq 1             ; number of characters received from socket

section .text
    global _start

_start:
    push rbp
    mov rbp, rsp

    call _network.init
    call _network.listen
    call _network.accept
    
    ;.net_read_loop:
    
        ; write Enter message to socket
        ;push qword [read_buffer_fd] ; get the fd global variable into local variable 
        ;push enter_msg_l
        ;push enter_msg
        ;call _write_text_to_socket
        
        ;call _network.read
        ;call _print_network_buffer
        
        ; check for valid commands
        ;push qword [chars_received] 
        ;push msg_buf
        ;call _read_command
        ; if command is 'exit' then exit
        ;cmp eax, 0x01
        ;jz _exit

        ; if command is anything else, perform ascii to hex conversion
        ; ascii to hex
        ;push qword [read_buffer_fd]
        ;push msg_buf
        ;call _ascii_to_hex
        ;add rsp, 0x10                       ; clean up

        ;push rax                            ; pass argument from previous function to the next function
        ;call _print_random
        ;add rsp, 0x8                        ; clean up stack  

        ;jmp _start.net_read_loop

.retry:
    call _network_accept

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
        ret

    .listen:
        ; listen
        ; int listen(int sockfd, int backlog);
        mov rax, 0x32                       ; listen syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, 0x03                       ; maximum backlog of 3 connections
        syscall

        cmp rax, 0x00
        jl _listen_failed
        call _listen_created
        ret

    .accept:
        ; accept
        ; int accept(int sockfd, struct sockaddr *restrict addr,
        ; socklen_t *restrict addrlen);
        mov rax, 0x2B                       ; accept syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, sockaddr_in                ; sockaddr struc pointer
        mov rdx, peer_address_length        ; populated with peer address length
        syscall

        mov qword [read_buffer_fd], rax     ; save new fd of buffer
        ret

    .read:
        mov rax, 0x00                       ; read syscall
        mov rdi, qword [read_buffer_fd]     ; read buffer fd
        mov rsi, msg_buf                    ; buffer pointer where message will be saved
        mov rdx, 1024                       ; message buffer size
        syscall
        
        mov qword [chars_received], rax     ; save number of received chars to global
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

    .shutdown:
        mov rax, 0x30                       ; close syscall
        mov rdi, qword [socket_fd]          ; sfd
        mov rsi, 0x2                        ; shuwdown RW
        syscall
        
        cmp rax, 0x0
        jne _network.shutdown.return
        call _buffer_closed
        .shutdown.return:
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
    ret 0x10                                ; clean up the stack upon return - not strictly following C Calling

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

_print_network_buffer:
    ; print network buffer
    push qword [chars_received]             ; length of message from stack
    push msg_buf                            ; message buffer pointer
    call _print
    ret

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

_listen_failed:
    ; print listen failed
    push listen_f_msg_l
    push listen_f_msg
    call _print
    jmp _exit

_listen_created:
    ; print listen created
    push listen_t_msg_l
    push listen_t_msg
    call _print
    ret

_buffer_closed:
    ; print buffer closed
    push buffer_closed_msg_l
    push buffer_closed_msg
    call _print
    ret

_socket_closed:
    ; print socket closed
    push socket_closed_msg_l
    push socket_closed_msg
    call _print
    ret

_exit:
    call _network.close
    call _network.shutdown

    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall