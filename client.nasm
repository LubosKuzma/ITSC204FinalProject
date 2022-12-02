;; Data definitions
struc sockaddr_in_type
    .sin_family resw 1
    .sin_port   resw 1
    .sin_addr   resd 1
    .sin_zero   resd 2
endstruc

MSG_DONTWAIT equ 0x40
MSG_WAITALL equ 0x100

section .data

    send_command:   db "100", 0xA   ; DO NOT TERMINATE WITH 0x00
    send_command_l: equ $ - send_command

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    connection_f_msg:   db "Connection failed.", 0xA, 0x0
    connection_f_msg_l: equ $ - connection_f_msg

    connection_t_msg:   db "Connection created.", 0xA, 0x0
    connection_t_msg_l: equ $ - connection_t_msg

    file_name: db 'output.txt', 0x00
    file_name_l: equ $ - file_name

    file_f_msg: db "File failed to be created", 0xA, 0x00
    file_f_msg_l: equ $ - file_f_msg

    write_t: db "Requested bytes were written to file: output.txt", 0xA, 0x00
    write_t_len: equ $ - write_t

    write_f: db "Requested bytes failed to be written to file: output.txt", 0xA, 0x00
    write_f_len: equ $ - write_f

    file_msg1: db "-----------BEGINNING OF RANDOM DATA------------", 0xA, 0x00
    file_msg1_l: equ $ - file_msg1

    file_msg2: db 0xA, "-----------BEGINNING OF MANIPULATED DATA------------", 0xA, 0x00
    file_msg2_l: equ $ - file_msg2

    ;print_statement: db "%d", 0xA, 0x00

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0x901F          ;(DEFAULT, passed on stack) port in hex and big endian order, 8080 -> 0x901F
            at sockaddr_in_type.sin_addr,    dd 0x00            ;(DEFAULT) 00 -> any address, address 127.0.0.1 -> 0x0100007F

        iend
    sockaddr_in_l: equ $ - sockaddr_in

section .bss
    ; global variables
    rec_buffer: resb 0x101
    socket_fd:  resq 1                  ; socket file descriptor
    output_fd: resb 1

section .text
    ;default rel
    ;global main
    global _start
    ;extern printf

;main:
_start:
    call _socket
    call _send_rec
    call _file
    call _close_socket
    
    jmp _exit

_socket:
    ; Initialize socket, based on IF_INET to get tcp
    mov rax, 0x29                       ; socket syscall
    mov rdi, 0x02                       ; int domain - AF_INET = 2, AF_LOCAL = 1
    mov rsi, 0x01                       ; int type - SOCK_STREAM = 1
    mov rdx, 0x00                       ; int protocol is 0
    syscall     
    cmp rax, 0x00
    jl _socket_failed                   ; jump if negative
    mov [socket_fd], rax                ; save the socket fd to basepointer
    call _socket_created

    ; int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    mov rax, 0x2A                        ; connect syscall
    mov rdi, qword [socket_fd]
    mov rsi, sockaddr_in
    mov rdx, sockaddr_in_l
    syscall
    cmp rax, 0x00
    jl _connection_failed
    call _connection_created
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
    ret

_file:
    ; Create new output file
    mov rax, 0x55        ; creat() syscall
    mov rdi, file_name   ; File name
    mov rsi, 0777        ; file mode (read, write and execute)
    syscall
    cmp rax, 0x00
    jl _file_not_created
    mov [output_fd], rax

    ; Write to file
    mov	rsi, file_msg1          ;message to write 
    mov	rdx, file_msg1_l          ;number of bytes
    call _write_to_file
    cmp rax, 0x00
    jl _write_fail
    call _append

    mov	rsi, rec_buffer          ;message to write 
    mov	rdx, 0x100           ;number of bytes
    call _write_to_file
    cmp rax, 0x00
    jl _write_fail
    call _write_success
    call _append
    
    mov	rsi, file_msg2          ;message to write 
    mov	rdx, file_msg2_l          ;number of bytes
    call _write_to_file
    call _append

    call _insertion_sort
    mov	rsi, rec_buffer          ;message to write 
    mov	rdx, 0x100           ;number of bytes
    call _write_to_file
    call _append

    ; Close file
    mov rax, 0x3                        ; close syscall
    mov rdi, qword [output_fd]     
    syscall
    ret

_write_to_file:
    mov	rax, 0x01            ;system call number (sys_write)
    mov	rdi, [output_fd]     ;file descriptor
    syscall
    ret

_append:
    mov   rax, 2
    mov   rdi, file_name
    mov   rsi, 0x441        ; O_CREAT| O_WRONLY | O_APPEND
    mov   edx, 0q666        ; octal permissions in case O_CREAT has to create it
    syscall
    mov   r8, rax      ; save the file descriptor
    ret

_insertion_sort:
    ; Epilogue
    push rbp
    mov rbp, rsp

    xor r8, r8                      ; r8 = i (intialize)
    xor r9, r9                      ; r9 = j (intialize)
    xor r10, r10                    ; r10 = key (initialize)
    mov rsi, rec_buffer             ; rsi = array[]
    mov rax, 0x100                  ; array length (n)

    mov r8, 0x01                    ; i = 1

    ; for (i = 1; i < n; i++)
    _for_loop:
        cmp r8, rax                 ; if i >= n, stop the loop
        jge end_for_loop

        mov r10, [rsi+r8]           ; key = array[i]
        mov r9, r8                  ; j = i - 1;
        dec r9

        ; Move elements of array[0..i-1], that are greater than key,
        ; to one position ahead of their current position
        ; while(j >= 0 && array[j] > key)
        _while_loop:
            cmp r9, 0x00            ; if j < 0, then stop this loop
            jl end_while_loop
            cmp [rsi+r9], r10       ; if array[j] <= key, stop this loop
            jle end_while_loop

            mov r11, [rsi+r9+1]     ; array[j+1] = array[j]
            mov [rsi+r9], r11
            
            sub r9, 1               ; j = j-1

        end_while_loop:
            mov [rsi+r9+1], r10

            inc r8
            jmp _for_loop

    end_for_loop:
    ; Prologue
    mov rsp, rbp
    pop rbp
    ret


;_printf:
;    push rbp                    ; prologue
;    mov rbp, rsp
;    mov rdi, print_statement    ; load print_statement
;    mov rsi, [rec_buffer]       ; 
;    mov rax, 0                  ; clear rax
;    call printf wrt ..plt       ; call printf function
;    mov rsp, rbp                ; epilogue
;    pop rbp
;    ret 

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

_connection_failed:
    ; print connection failed
    push connection_f_msg_l
    push connection_f_msg
    call _print
    jmp _exit

_connection_created:
    push connection_t_msg_l
    push connection_t_msg
    call _print
    ret

_file_not_created:
    push file_f_msg_l
    push file_f_msg
    call _print
    jmp _exit

_write_success:
    ; Write to stdout that bytes are writen to file
    push write_t_len
    push write_t
    call _print
    ret

_write_fail:
    push write_f_len
    push write_f
    call _print
    jmp _exit

_close_socket:
    ; Close socket
    mov rax, 0x3                        ; close syscall
    mov rdi, qword [socket_fd]     
    syscall
    ret

_exit:
    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
