;extern printf
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

    filename: db "sortoutput", 0x00
    test: db 0xA

    NULL          equ 0x00
    MAP_SHARED    equ 0x01
    MAP_PRIVATE   equ 0x02
    MAP_FIXED     equ 0x10
    MAP_ANONYMOUS equ 0x20
    PROT_NONE     equ 0x00
    PROT_READ     equ 0x01
    PROT_WRITE    equ 0x02
    PROT_EXEC     equ 0x04

    malloc_size   equ 100 
    

        sockaddr_in: 
        istruc sockaddr_in_type 
            at sockaddr_in_type.sin_family,  dw 0x02     ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0xDB27      ;(DEFAULT, passed on stack) port in hex and big endian order, 8080 -> 0x901F
            at sockaddr_in_type.sin_addr,    dd 0xB886EE8C  ; (DEFAULT) 00 -> any address, address 127.0.0.1 -> 0x0100007F
        iend
    sockaddr_in_l:  equ $ - sockaddr_in

section .bss
    rec_buffer:              resb 0x101
    socket_fd:               resq 1             ; socket file descriptor
    heap_ptr:                resq 1
    digitSpace resb 100
    digitSpacePos resb 8

section .text
    global _start
_start:
    push rbp
    mov rbp, rsp

    call _malloc

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
    mov rdi, [socket_fd]                ; int fd
    mov rsi, send_command               ; int type - SOCK_STREAM = 1
    mov rdx, send_command_l             ; int protocol is 0
    mov r10, MSG_DONTWAIT
    mov r8, sockaddr_in
    mov r9, sockaddr_in_l
    
    syscall
  
    ; using receivefrom syscall
    mov rax, 0x2D
    mov rdi, [socket_fd]
    mov rsi, [heap_ptr]
    mov rdx, 0x100                      ; must match the requested number of bytes
    mov r10, MSG_WAITALL                ; important
    mov r8, 0x00
    mov r9, 0x00
    syscall
    .rec:                        ; setup break in gdb by "b _send_rec.rec" to examine the buffer
    call _filecreate
    call _fileopen
    call _writefile
    call _killfile


    ;write to screen
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, [heap_ptr]
    mov rdx, 0x100
    syscall

    mov rax, 0x00
    call _loop
    


    call _free
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


_malloc:
    mov rax, 0x9
    mov rdi, NULL
    mov rsi, malloc_size
    mov rdx, PROT_WRITE
    or rdx, PROT_READ
    or rdx, PROT_WRITE
    mov r10, MAP_ANONYMOUS
    or r10, MAP_PRIVATE
    mov r8, 0x00
    mov r9, 0x00
    syscall
    mov[heap_ptr], rax
    ret

_free: 
    mov rax, 0xb
    mov rdi, [heap_ptr]
    mov rsi, malloc_size
    syscall
    ret

_filecreate:
    mov rax, 0x55       ;syscall create file
    mov rdi, filename   ;ARG 0
    mov rsi, 0777o       ;ARG 1
    syscall
    ret
_fileopen:
    mov rax, 0x2
    mov rdi, filename
    mov rsi, 66
    mov rdx, 0777o
    syscall
    ret
_writefile:

    mov rdi, rax
    mov rax, 0x1
    mov rsi, [heap_ptr]
    mov rdx, 0x100
    syscall
    ret

_killfile:
    mov rax, 0x3
    mov rdi, filename
    syscall
    ret

_loop:
    inc rbx
    cmp rbx, 0x100
    jge _exit
    
    mov rcx, [heap_ptr]
    mov r8, [rcx + rbx]

    mov rax, 0x1 ;print
    mov rdi, 0x1
    mov rsi, r8
    mov rdx, 0x1
    syscall

    mov rsi, test
    mov rdi, 0x1
    mov rax, 0x1
    syscall

    cmp rbx, 0x100
    jle _loop

 

_exit:
    ;call _network.close
    ;call _network.shutdown
    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
