; by Benjamin, Monik, Hasan, Yu Jin
; ISS Program, SAIT
; 
; x86-64, NASM

; *******************************
; Functionality of the program:
; 
; *******************************


;*****************************
struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1
    .sin_port:          resw 1
    .sin_addr:          resd 1
    .sin_zero:          resd 2          ; padding       
endstruc

;*****************************


section .text
global _start

_start:
    call _network.init
    call _network.connect 

    call _network.read
    call _network.write
    call _network.read_from_the_socket
    












_network:
    .init:
        ; socket, based on IF_INET to get tcp
        mov rax, 0x29                       ; socket syscall
        mov rdi, 0x02                       ; int domain - AF_INET = 2
        mov rsi, 0x01                       ; int type - SOCK_STREAM = 1
        mov rdx, 0x00                       ; int protocol is 0
        syscall   

        cmp rax, 0x00
        jl _socket_failed                   ; jump if negative
        mov [socket_fd], rax                ; save the socket fd 
        call _socket_created
        ret

    .connect:
        mov rax, 0x2A                       ; connect syscall
        mov rdi, qword[socket_fd]           ; (sfd) socket file descriptor
        mov rsi, sockaddr_in                ; sockaddr struct pointer           
        mov rdx, sockaddr_in_l              ; address length 
        syscall 

        cmp rax, 0x00
        jl _connect_failed                  ; jump if negative
        call _connect_created
        ret



    .read:
        mov rax, 0x00                       ; read syscall
        mov rdi, 0x00                       ; read buffer fd
        mov rsi, msg_buf                    ; buffer pointer where message will be saved
        mov rdx, 0x03                       ; message buffer size
        syscall
        
        ret
        
    .write:
        
        mov rax, 0x01                       ; write syscall
        mov rdi, qword[socket_fd]           ; socket file desctriptor
        mov rsi, qword[msg_buf]             ; store message buffer pointer into rsi
        mov rdx, 0x03                       ; store message buffer length into rdx
        syscall

        ret

    .read_from_the_socket:

        mov rax, 0x00                       ; read syscall
        mov rdi, qword[socket_fd]           ; read socket fd into rdi
        mov rsi, random_byte                ; move random_byte buffer into rsi
        mov rdx, 1024                       ; move random_byte length into rdx
        syscall
        
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

_connect_failed:
    ; print connect failed
    push connect_f_msg_l
    push connect_f_msg
    call _print
    jmp _exit

_connect_created:
    ; print connect created
    push connect_t_msg_l
    push connect_t_msg
    call _print
    ret      

_exit:
    mov rax, 60
    mov rdi, 0
    syscall


section .data

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    connect_f_msg:   db "Connect failed to be created.", 0xA, 0x0
    connect_f_msg_l: equ $ - connect_f_msg

    connect_t_msg:   db "Connect created.", 0xA, 0x0
    connect_t_msg_l: equ $ - connect_t_msg    







    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0xDE27          ;port in hex and big endian order, 10206 -> 0xDE27 
            at sockaddr_in_type.sin_addr,    dw 0xB886EE8C      ;address 140.238.134.184 -> 0xB886EE8C

        iend
    sockaddr_in_l:  equ $ - sockaddr_in




section .bss
    socket_fd:               resq 1             ; socket file descriptor
    read_buffer_fd           resq 1             ; file descriptor for read buffer
    chars_received           resq 1             ; number of characters received from socket
    msg_buf:                 resb 3             ; message buffer
    random_byte:             resb 1024          ; reserve 1024 bytes