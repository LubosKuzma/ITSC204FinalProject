;making a structure in assembly just like we do it in c 
;*****************************
struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1 ;tells us which family are we reffering to 
    .sin_port:          resw 1 ;for port number in bytes 
    .sin_addr:          resd 1 ;for ip adress in bytes 
    .sin_zero:          resd 2 ; padding(not in use right now )      
endstruc ;struct end 

NULL equ 0x00
MAP_SHARED equ 0x01
MAP_PRIVATE equ 0x02
MAP_FIXED equ 0x10
MAP_ANONYMOUS equ 0x20
PROT_NONE equ 0x00
PROT_READ equ 0x01
PROT_WRITE equ 0x02
PROT_EXEC equ 0x04
malloc_size equ 0x400

;*****************************
SIGPIPE equ 0xD
SIG_IGN equ 0x1
NULL    equ 0x0

 

MSG_DONTWAIT equ 0x40
MSG_WAITALL equ 0x100 
;this is important this tells the client that it must run till this much bytes are recived/send


section .bss
    ;global variables 
    msg_biffer:               resb 1024 ; number of bytes to read(i guess) more than this will result in buffer overflow
    socket_fd:                resq 1    ; socket file descriptor
    chars_received           resq 1     ; number of characters received from socket
    openfile_fd:            resq 1     
    rec_buffer:              resb 0x101 ;record buffer that will eventually save thedata from the heap
    

 
section .text
global _start: 

_start:


    push rbp ;pushing the base pointer 
    mov rbp, rsp ;copying the stack pointer to the base poiner 
    

 

        ; socket, based on IF_INET to get tcp
        mov rax, 0x29          ; socket syscall(creating a socket)
        mov rdi, 0x02          ; int domain - AF_INET = 2, AF_LOCAL = 1 (2 because we are dealing with internet socket)
        mov rsi, 0x01          ; int type - SOCK_STREAM = 1
        mov rdx, 0x00          ; int protocol is 0
        syscall     
        ;after this syscall the rax register willl have the file discripter 
        ;now always check the rax register must be 3 or more cannot be (0,1,2)
        cmp rax, 0x00           ;compairing to check if it is zero or not 
        jl _socket_failed                 ; jump if negative (printing socket failed)
        mov [socket_fd], rax              ; else save the socket fd to basepointer
        call _socket_created               ;printing socket connected 
    
        mov rax, 0x2A                       ; connetction syscall
        mov rdi, qword [socket_fd]          ; socket file discripter 
        mov rsi, sockaddr_in                ; sockaddr struct pointer
        mov rdx, sockaddr_in_l              ; address length 
        syscall
        cmp rax, 0x00   ;compairig the value of the file descripter
        jl _connection_failed   ;jump if the value is lower than 0 and printing connection failed 
        call _connection_created ;else priting connection established 
  
  ;setting up malloc for dynamically allocating the memory during the run time 
  

            ;(void*) malloc(size_t size)
            ;returns the pointer to the base address of the first byte of the size

   ; malloc (mmap syscall)
; returns pointer to allocated memory on heap in rax
    mov rax, 0x9
    mov rdi, NULL
    mov rsi, malloc_size
    mov rdx, PROT_WRITE
    or rdx, PROT_READ
    mov r10, MAP_ANONYMOUS
    or r10, MAP_PRIVATE
    mov r8, 0x00
    mov r9, 0x00
    syscall
    mov [rec_buffer], rax

 
    ;basically this is the syscall that sends our input to the server 
    mov rax, 0x2C                        ; sendmsg syscall
    mov rdi, [socket_fd]                 ; int file descripter
    mov rsi, send_command                ;** int type - SOCK_STREAM = 1 wih the command that we'll be giving 
    mov rdx, send_command_l              ;** int protocol is 0
    mov r10, MSG_WAITALL                 ;waite till we send all the bytes  
    mov r8, sockaddr_in                  ;socket addredd 
    mov r9, sockaddr_in_l                ;length of socket address 
    syscall
  
    ; using receivefrom syscall
    mov rax, 0x2d ;recieve sysall 
    mov rdi, [socket_fd] ;socket file descripter
    mov rsi, [rec_buffer]; buffer to save the recieved characters 
    mov rdx, 0x100           ; must match the requested number of bytes to recieve
    mov r10, MSG_WAITALL     ; important
    mov r8, 0x00    
    mov r9, 0x00
    syscall

    call _print

 ;printing the values to the main screen 
    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, [rec_buffer]
    mov rdx, 0x100 
    syscall
  
    ;opening a file to write the output to 
    mov rax, 0x2 ;opening syscall
    mov rdi, filename ;int *fd
    mov rsi, 0x222 ;intflags
    mov rdx, 0777 ;mods 
    syscall

    mov [openfile_fd], rax ;saving the file fd  

;writing the output into the file
    mov rax, 0x1 
    mov rdi, [openfile_fd]
    mov rsi, [rec_buffer]
    mov rdx, malloc_size
    syscall

    ;closing the file opened 
    mov rax,0x3 ;closing syscall 
    mov rdi, [openfile_fd]




;freeing up the memory for reaalocation 
    ;freeing up the memory from the heap does not mean that it will delete
    ;the memory form the stack .
    ;it will be on the stack but if we wish to access it .
    ; it will be unpridictable. 

; free (munmap syscall)
; returns 0x00 in rax if succesful
    mov rax, 0xb
    mov rdi, [rec_buffer]
    mov rsi, malloc_size
    syscall
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


section .data

 


    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    connect_f_msg:   db "connection failed .", 0xA, 0x0
    connect_f_msg_l: equ $ - connect_f_msg

    connect_t_msg:   db "connection created .", 0xA, 0x0
    connect_t_msg_l: equ $ - connect_t_msg

    send_command:   db "100", 0xA   ; DO NOT TERMINATE WITH 0x00
    send_command_l: equ $ - send_command

    filename db "output.txt"

;passing the values to the variables(so called) in the struct that we initialized before
    sockaddr_in: 
            istruc sockaddr_in_type 

 

                at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 ;
                at sockaddr_in_type.sin_port,    dw 0x901F  ;0xDB27        ;(DEFAULT, passed on stack) port in hex and big endian order, 10203 -> 0xDB27
                at sockaddr_in_type.sin_addr,    dd 0x0100007F  ;0xB886EE8C   ;(DEFAULT) 00 -> any address, address - 140.238.134.184 -> 0xA81BD8A620 (here the adress of the server we wil be connecting to)

 

            iend
        sockaddr_in_l:  equ $ - sockaddr_in

 

 
