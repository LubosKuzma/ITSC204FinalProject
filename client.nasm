


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

    message_sent: db "Message sent to server.", 0xA, 0x0
    message_sent_l: equ $ - message_sent

    message_sent_f: db "Failed to send message to server.", 0xA, 0x0
    message_sent_f_l: equ $ - message_sent_f


    filename: db "Data.txt",0x0
    filename_l: equ $ - filename

    banner: db "Enter number between 100 and 4FF to retrieve data from server: ", 0x00
    banner_l: equ $ - banner



    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0xE127        ;(DEFAULT, passed on stack) port in hex and big endian order, 10209 -> 0xE127
            at sockaddr_in_type.sin_addr,    dd 0xB886EE8C       ;(DEFAULT) 00 -> any address, address 140.238.134.184 -> 0xB886EE8C 

        iend
    sockaddr_in_l:  equ $ - sockaddr_in

    

section .bss

    ; global variables
    file_fd                  resq 1             ; file opened file descriptor
    socket_fd:               resq 1             ; socket file descriptor
    client_fd                resq 1             ; client file descriptor
    message_buf              resb 1024          ; store data recieved from server
    number                   resq 4             ; number sent to server
    message_buf_l            resq 4             ; length of message recieved from server


section .text
    global _start
 
_start:


    call _network.init  ; netowrk in intillaized 

    call _network.connection    ; connecting to the server

    push banner_l 
    push banner
    call _print         ; printing banner 

    push 0x4
    push number
    call _read          ; taking input from the user for data to be retrieved from server

    call _network.send   ; sending message to the server

    call _network.recieve   ; recieving message from the server 

    call _network.recieve

    mov [message_buf_l], rax   ; storing number of bytes of data recieved from server to variabel

    call _file.create         ; opening a file name data.txt

    push qword[message_buf_l]
    push message_buf
    call _file.write        ; writing data recieved from the server to the file


    call _network.close     ; closing the socket
    call _file.close        ; closing the file 
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

    .connection:        
        ; connecting to the server
        mov rax, 0x2A                       ; connect syscall
        mov rdi, qword [socket_fd]          ; sfd 
        mov rsi, sockaddr_in                ; sockaddr struct pointer
        mov rdx, sockaddr_in_l              ; sockaddr length
        syscall
        cmp rax, 0x00                       ; checking if connection successful

        jl _connection_failed               ; failed
        call _connection_success            ; successful
        mov [client_fd], rax
        ret

    .send:      
        ; sending message to server

        mov rax, 0x1
        mov rdi, qword [socket_fd]
        mov rsi, number
        mov rdx, 0x4
        syscall

        cmp rax, 0x0
        jl _message_sent_f
        call _message_sent
        ret

    .recieve:  
        ; recieving data from the server

        mov rax, 0x0
        mov rdi, qword [socket_fd]
        mov rsi,  message_buf   
        mov rdx,   1024
        syscall
        ret

    .close:  ; closing the socket
        
        mov rax, 0x3
        mov rdi, qword[client_fd]
        syscall
        call _socket_closed
        ret


_file:  

    .create:                                  ; creating file
   
        mov rax, 0x55
        mov rdi, filename
        mov rsi, 511                           ; (permissions) read and write to owner, read to all                 
        syscall
        
        cmp rax, 0x0
        jle _file_notCreated
        mov [file_fd], rax                      ; moving file descriptor for the file to file_fd
        call _file_created
        ret

 

    .write:                                 ; write to the file

        ; prologue
        push rbp
        mov rbp, rsp
        push rdi
        push rsi

       
        mov rax, 0x1
        mov rdi, [file_fd]
        mov rsi, [rbp + 0x10]                          ; data to write to file
        mov rdx, [rbp + 0x18]                        ; lenght of the data                    
        syscall

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length

        ; epilogue
        pop rsi
        pop rdi
        pop rbp
        ret 0x10                                ; clean up the stack upon return - not strictly following C Calling Convention


   
    .read:                                  ; read from the file

        ; prologue
        push rbp
        mov rbp, rsp
        push rdi
        push rsi


        mov rax, 0x0
        mov rdi, [file_fd]
        mov rsi, [rbp + 0x10]                         ; buffer to store data read from file
        mov rdx, [rbp + 0x18]                         ; length of data to read from file                        
        syscall 

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length

        ; epilogue
        pop rsi
        pop rdi
        pop rbp
        ret 0x10   

    .close:                                 ; close the file

        mov rax, 0x3
        mov rdi, [file_fd]                      
        syscall
        ret






_read:
        
    ; prologue
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    ; [rbp + 0x10] -> buffer pointer
    ; [rbp + 0x18] -> buffer length

    mov rax, 0x0
    mov rdi, 0x0
    mov rsi, [rbp + 0x10]
    mov rdx, [rbp + 0x18]
    syscall


    ; epilogue
    pop rsi
    pop rdi
    pop rbp
    ret 0x10

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

_connection_failed:
     ; print connection failed
     push connection_f_msg_l
     push connection_f_msg
     call _print
     jmp _exit

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
    jmp _exit

_file_created:
    ; print file Created
    push fileCre_t_msg_l
    push fileCre_t_msg
    call _print
    ret

_message_sent:
    ;print message sent to server
    push message_sent_l
    push message_sent
    call _print 
    ret

_message_sent_f:
    ;print message sent to server
    push message_sent_f_l
    push message_sent_f
    call _print 
    ret


_socket_closed:
    ; print socket closed
    push socket_closed_msg_l
    push socket_closed_msg
    call _print
    ret



_exit:

    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
