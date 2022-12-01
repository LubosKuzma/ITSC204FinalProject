;; Data definitions
struc sockaddr_in_type
    .sin_family resw 1
    .sin_port   resw 1
    .sin_addr   resd 1
    .sin_zero   resd 2
endstruc

section .bss
    sock resw 2
    client resw 2
    echobuf resb 256
    read_count resw 2

section .data

    sock_err_msg        db "Failed to initialize socket", 0x0a, 0x00
    sock_err_msg_len    equ $ - sock_err_msg

    connect_err_msg        db "Failed to connect socket", 0x0a, 0x00
    connect_err_msg_len    equ $ - connect_err_msg

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0x27D9          ;(DEFAULT, passed on stack) port in hex and big endian order, 8080 -> 0x901F
            at sockaddr_in_type.sin_addr,    dd 0xb886ee8c            ;(DEFAULT) 00 -> any address, address 127.0.0.1 -> 0x0100007F

        iend
    sockaddr_in_l: equ $ - sockaddr_in

 section .text
    global _start

 ;; Client main entry point
_start:
    push rbp
    mov rbp, rsp
;; Initialize socket value to 0, used for cleanup 
mov      word [sock], 0

;; Initialize socket
call     _socket

;; Performs a sys_socket call to initialise a TCP/IP socket. 
;; Stores the socket file descriptor in the sock variable
_socket:
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

;; Check if socket was created successfully
cmp        rax, 0
jle        _socket_fail

;; Store the new socket descriptor 
mov        [sock], rax

ret

;; Performs sys_close on the socket in rdi
_close_sock:
mov     rax, 3        ; SYS_CLOSE
syscall

ret

;; Error Handling code
;; _*_fail loads the rsi and rdx registers with the appropriate
;; error messages for given system call. Then call _fail to display the
;; error message and exit the application.
_socket_fail:
   mov     rsi, sock_err_msg
   mov     rdx, sock_err_msg_len
   call    _fail
;; Calls the sys_write syscall, writing an error message to stderr, then 
;; exits
;; the application. rsi and rdx must be loaded with the error message and
;; length of the error message before calling _fail
_fail:
mov        rax, 1 ; SYS_WRITE
mov        rdi, 2 ; STDERR
syscall

mov        rdi, 1
call       _exit

 ;; Exits cleanly, checking if the listening or client sockets need to be 
 ;; closed
 ;; before calling sys_exit
_exit:
mov        rax, [sock]
cmp        rax, 0
je         .client_check
mov        rdi, [sock]
call       _close_sock

.client_check:
mov        rax, [client]
cmp        rax, 0
je         .perform_exit
mov        rdi, [client]
call       _close_sock

.perform_exit:
mov        rax, 60
mov        rdi, 0
syscall
