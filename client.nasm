

SIGPIPE equ 0xD
SIG_IGN equ 0x1
NULL    equ 0x0

;*****************************
struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1
    .sin_port:          resw 1
    .sin_addr:          resd 1
    .sin_zero:          resd 2          ; padding       
endstruc

;*****************************


section .data

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    bind_f_msg:   db "Socket failed to bind.", 0xA, 0x0
    bind_f_msg_l: equ $ - bind_f_msg

    bind_t_msg:   db "Socket bound.", 0xA, 0x0
    bind_t_msg_l: equ $ - bind_t_msg

    connection_t_msg: db "Connected to the Server.", 0xA, 0x0
    connection_t_msg_l: equ $ - connection_t_msg

    connection_f_msg: db "Connection Failed.", 0xA, 0x0
    connection_f_msg_l: equ $ - connection_f_msg

    socket_closed_msg:   db "Socket closed.", 0xA, 0x0
    socket_closed_msg_l: equ $ - socket_closed_msg

    fileCre_f_msg: db "Failed to Create file.", 0xA, 0x0
    fileCre_f_msg_l: equ $ - fileCre_f_msg

    fileCre_t_msg: db "File Created.", 0xA, 0x0
    fileCre_t_msg_l: equ $ - fileCre_t_msg
    
    filename: db "Data.txt",0x0
    filename_l: equ $ - filename

    ; list of commands

    cmd_1_exit: db "exit", 0x0A
    cmd_1_exit_l: equ $ - cmd_1_exit

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0x1E72         ;(DEFAULT, passed on stack) port in hex and big endian order, 10209 -> 0x1E72
            at sockaddr_in_type.sin_addr,    dd 0x8B68EEC8       ;(DEFAULT) 00 -> any address, address 140.238.134.184 -> 0x8B68EEC8 

        iend
    sockaddr_in_l:  equ $ - sockaddr_in

    

section .bss

    ; global variables
    file_fd                  resq 1             ; file opened file descriptor
    socket_fd:               resq 1             ; socket file descriptor


section .text
    global _start
    extern sigaction
 
_start:
    push rbp
    mov rbp, rsp


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


    call _network.init  ; netowrk in intillaized 

    call _network.connection    ; connecting to the server

    call _file.open

   ; call _file.write

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
        ret

    .connection:        ;  working
        ; connecting to the server
        mov rax, 0x2A                       ; connect syscall
        mov rdi, qword [socket_fd]          ; sfd 
        mov rsi, sockaddr_in                ; sockaddr struct pointer
        mov rdx, sockaddr_in_l              ; sockaddr length
        syscall
        cmp rax, 0x00                       ; checking if connection successful
        jl _connection_failed               ; failed
        call _connection_success            ; successful
        ret

    .send:      ; still working on

        mov rax, 0x2E
        mov rdi, qword [socket_fd]
        mov rsi, []
        mov rdx, 
        syscall

    .recieve:  ; still working on

        mov rax, 0x2F
        mov rdi, qword [soket_fd]
        mov rsi,    
        mov rdx,
        syscall


_file:  ; working 

    .create:                                  ; creating file
   
        mov rax, 0x55
        mov rdi, filename
        mov rsi, 0777                           ; read, write and execution to all                 
        syscall
        
        cmp rax, 0x0
        jle _file_notCreated
        mov [file_fd], rax                      ; moving file descriptor for the file to file_fd
        call _file_created
        ret

 

    .write:                                 ; write to the file
       
        mov rax, 0x1
        mov rdi, [file_fd]
        mov rsi,                            ; data to write to file
        mov rdx,                            ; lenght of the data                    
        syscall
        ret
   
    .read:                                  ; read from the file
        
        mov rax, 0x0
        mov rdi, [file_fd]
        mov rsi,                            ; buffer to store data read from file
        mov rdx,                            ; length of data to read from file                        
        syscall 
        ret

    .close:                                 ; close the file

        mov rax, 0x3
        mov rdi, [file_fd]                      
        syscall
        ret


_Array:                                     ; array to store the data from server


_QuickSort:                                 ; to sort data in decreasing order 



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

_connection_failed:
     ; print connection failed
     push connection_f_msg_l
     push connection_f_msg
     call _print
     ret

_connection_success:
     ; print connection successfully created
     push connection_t_msg_l
     push connection_t_msg
     call _print
     ret

_file_notCreated:
    ; print file not Created
    push fileCre_f_msg_l
    push fileCre_f_msg
    call _print
    ret

_file_created:
    ; print file Created
    push fileCre_t_msg_l
    push fileCre_t_msg
    call _print
    ret




_exit:


    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
