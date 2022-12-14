; Course: ITSC 204 -- Final Project (TCP Client)
; Team GCC: Adeela Nassar, Karen Penzo, and Victor Cauad
; Program: Information System Security, SAIT
; Instructor: Lubos Kuzma
; Date: December, 12 / 2022
; Purpose of program: Connect to the server and request for a certain number of bytes,
; which will be sorted using the insertion method and written to a file as both random and sorted bytes.

; Data definitions
struc sockaddr_in_type
    .sin_family resw 1
    .sin_port   resw 1
    .sin_addr   resd 1
    .sin_zero   resd 2
endstruc

MSG_DONTWAIT equ 0x40
MSG_WAITALL equ 0x100

; For malloc function
NULL            equ 0x00
MAP_SHARED      equ 0x01
MAP_PRIVATE     equ 0x02
MAP_FIXED       equ 0x10
MAP_ANONYMOUS   equ 0x20
PROT_NONE       equ 0x00
PROT_READ       equ 0x01
PROT_WRITE      equ 0x02
PROT_EXEC       equ 0x04
malloc_size     equ 0x600

section .data

    socket_t_msg:   db "Socket created.", 0xA, 0x0
    socket_t_msg_l: equ $ - socket_t_msg

    socket_f_msg:   db "Socket failed to be created.", 0xA, 0x0
    socket_f_msg_l: equ $ - socket_f_msg

    connection_f_msg:   db "Connection failed.", 0xA, 0x0
    connection_f_msg_l: equ $ - connection_f_msg

    connection_t_msg:   db "Connection created.", 0xA, 0x0
    connection_t_msg_l: equ $ - connection_t_msg

    byte_msg: db "Enter number of bytes to request from server (100 - 5FF): ", 0x00
    byte_msg_l: equ $ - byte_msg

    file_name: db 'output.txt', 0x00
    file_name_l: equ $ - file_name

    file_f_msg: db "File failed to be created", 0xA, 0x00
    file_f_msg_l: equ $ - file_f_msg

    write_t: db "Requested bytes were written to file: output.txt", 0xA, 0x00
    write_t_len: equ $ - write_t

    write_f: db "Requested bytes failed to be written to file: output.txt", 0xA, 0x00
    write_f_len: equ $ - write_f

    file_msg1: db 0xA, "-----------BEGINNING OF RANDOM DATA------------", 0xA, 0x00
    file_msg1_l: equ $ - file_msg1

    file_msg2: db 0xA, 0xA, "-----------BEGINNING OF MANIPULATED DATA------------", 0xA, 0x00
    file_msg2_l: equ $ - file_msg2

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ; AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0x901F          ; port: 10201 equals D927 in big endian
            at sockaddr_in_type.sin_addr,    dd 0x00            ; IP address: 140.238.134.184

        iend
    sockaddr_in_l: equ $ - sockaddr_in

section .bss
    ; global variables
    array_ptr: resq 0x600                       ; buffer to store the byte from server               
    socket_fd:  resq 1                          ; socket file descriptor
    output_fd: resb 1                           ; output.txt file descriptor
    byte_buffer: resb 4                         ; buffer for the user entered bytes
    byte_length: resb 4                

section .text
    global _start

_start:
    call _socket_and_connection                 ; create socket and connection
    call _malloc                                ; allocate heap memory space for array_ptr using mmap syscall
    call _get_input                             ; Get user to enter number of bytes to request from server
    call _get_length                            ; Convert the byte length entered from ascii to hex and remove the '\n'
    mov [byte_length], rbx                      ; save the length of byte request to buffer byte_length
    call _send_rec                              ; send a request to server for the data and receive data in array_ptr
    call _file                                  ; create and write data to file: random and sorted
    call _free                                  ; free heap space allocated to array_ptr
    call _close_socket                        
    
    jmp _exit

_socket_and_connection:
    ; Prologue
    push rbp
    mov rbp, rsp

    ; Initialize socket
    mov rax, 0x29                               ; socket syscall
    mov rdi, 0x02                               ; int domain - AF_INET = 2, AF_LOCAL = 1
    mov rsi, 0x01                               ; int type - SOCK_STREAM = 1
    mov rdx, 0x00                               ; int protocol is 0
    syscall     
    cmp rax, 0x00
    jl _socket_failed                           ; if rax < 0, socket not created
    mov [socket_fd], rax                        ; save the socket file descriptor to buffer
    call _socket_created

    ; int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    mov rax, 0x2A                               ; connect syscall
    mov rdi, qword [socket_fd]                  ; socket file descriptor
    mov rsi, sockaddr_in                        ; get server IP address and port number
    mov rdx, sockaddr_in_l                      ; address length
    syscall
    cmp rax, 0x00                               
    jl _connection_failed                       ; if rax < 0, connection failed to be created
    call _connection_created
    
    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret

_get_input:
    ; Prologue
    push rbp
    mov rbp, rsp

    ; ask to enter number of bytes   
    mov rax, 0x01                               ; Write syscall
    mov rdi, 0x01                               ; stdout fd    
    mov rsi, byte_msg
    mov rdx, byte_msg_l
    syscall

    ; Get user input for number of bytes
    mov rax, 0x00                               ; Read syscall
    mov rdi, 0x00                               ; stdin fd
    mov rsi, byte_buffer
    mov rdx, 0x04
    syscall

    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret

_get_length:
    ; Prologue
    push rbp
    mov rbp, rsp

    ; Take the user entered number and remove the '\n' from buffer
    ; and convert ascii to hex to get proper length
    mov r8, [byte_buffer]
    mov [byte_length], r8                           ; saves user input to byte_length
    xor r8, r8                                      ; Clear register
    .loop:
        lea rcx, [byte_length + r8]                 ; Take the byte at address of byte_length + index
        mov al, byte [rcx]                          ; move the byte to al
        cmp al, 0xA                                 ; compare to see if byte is newline character
        je .end                                     ; If so, then end the loop
        call _ascii_to_hex                          ; Convert byte to hex
        or rbx, rax                                 ; rbx now has the byte
        shl rbx, 4                                  ; Shift rbx to the left by 1 byte inorder to load the next byte
        inc r8                                      ; Increment index       
        jmp .loop                                   ; Keep looping until '\n' is found
        
        .end:
            shr rbx, 4                              ; At the end, shift right to get the correct length

            ; Epilogue
            mov rsp, rbp
            pop rbp
            ret

_ascii_to_hex:

    cmp al, 0x39
    jge skip
    sub al, 0x30
    ret

    skip:
    sub al, 0x7
    sub al, 0x30
    ret          
 
_send_rec:
    ; Prologue
    push rbp
    mov rbp, rsp

    mov rax, 0x2C                           ; sendmsg syscall
    mov rdi, [socket_fd]                    ; socket file descriptor
    mov rsi, byte_buffer                    ; number of bytes requested
    mov rdx, 0x04                           ; length of message
    mov r10, MSG_DONTWAIT
    mov r8, sockaddr_in
    mov r9, sockaddr_in_l
    syscall

    mov rax, 0x2D                           ; receivefrom syscall
    mov rdi, [socket_fd]                    ; socket file descriptor
    mov rsi, array_ptr                      ; save the bytes into buffer
    mov rdx, [byte_length]                  ; length of bytes to be saved
    mov r10, MSG_WAITALL                
    mov r8, 0x00
    mov r9, 0x00
    syscall
    .rec:                                  ; setup break in gdb by "b _send_rec.rec" to examine the buffer
    ; your array_ptr will now be filled with 0x100 bytes
    
    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret

_file:
    ; Prologue
    push rbp
    mov rbp, rsp

    ; Create and open new output file
    mov   rax, 0x2                          ; Open syscall
    mov   rdi, file_name                    ; File name (output.txt)
    mov   rsi, 0x441                        ; O_CREAT| O_WRONLY | O_APPEND
    mov   edx, 0q666                        ; octal permissions in case O_CREAT has to create it
    syscall
    cmp rax, 0x00                           ; If rax < 0, file not created
    jl _file_not_created
    mov [output_fd], rax                    ; save file descriptor to buffer

    mov rsi, file_msg1                      ; message to write ("beginning of random data")  
    mov rdx, file_msg1_l                    ; length of message 
    call _write_to_file  

    mov [byte_length], rbx
    mov rsi, array_ptr                      ; write the random byte to file
    mov rdx, [byte_length]                  ; length of array_ptr
    call _write_to_file
    
    mov rsi, file_msg2                      ; message to write ("beginning of manipulated data")  
    mov rdx, file_msg2_l                    ; length of message 
    call _write_to_file 

    call _insertion_sort                    ; Call function to sort bytes in buffer
    mov rsi, array_ptr                      ; write the sorted bytes to file
    mov rdx, [byte_length]                  ; length of array_ptr
    call _write_to_file
    cmp rax, 0x00                           ; If rax is less than 0, data not written to file
    jl _write_fail
    call _write_success

    ; Close file
    mov rax, 0x3                            ; close syscall
    mov rdi, qword [output_fd]              ; file descriptor   
    syscall

    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret

_write_to_file:
    ; Prologue
    push rbp
    mov rbp, rsp

    mov	rax, 0x01                           ; sys_write
    mov	rdi, [output_fd]                    ; file descriptor
    syscall

    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret

_insertion_sort:
    ; Prologue
    push rbp
    mov rbp, rsp

    xor r8, r8                              ; r8 = i (intialize)
    xor r9, r9                              ; r9 = j (intialize)
    xor rax, rax                            ; rax = key (initialize)
    mov r11, [byte_length]                  ; array_ptr length (n)

    mov r8, 0x01                            ; i = 1

    ; for (i = 1; i < n; i++)
    _for_loop:
        cmp r8, r11                         ; if i >= n, stop the loop
        jge end_for_loop

        lea rcx, [array_ptr+r8]             ; Get byte at position array_ptr[i]
        mov al, byte [rcx]                  ; key = al
        mov r9, r8                          ; j = i
        dec r9                              ; decrement j by 1

        ; while(j >= 0 && array_ptr[j] > key)
        _while_loop:
            cmp r9, 0x00                    ; if j < 0, then stop this loop
            jl end_while_loop
            lea rcx, [array_ptr+r9]         ; Get byte at position array_ptr[j]
            mov dl, byte [rcx]              ; dl = array_ptr[j]
            cmp dl, al                      ; if array_ptr[j] <= key, stop this loop
            jle end_while_loop
          
            mov [array_ptr+r9+1], byte dl   ; If not, then move byte at array_ptr[j+1] to position array_ptr[j]         
            dec r9                          ; Decrement j by 1

            jmp _while_loop                 ; Keep looping until j < 0 and array_ptr <= key

        end_while_loop:
            mov [array_ptr+r9+1], byte al   ; When the while loop ends, the key is moved to position array_ptr[j+1] 
            inc r8                          ; i is incremented by 1
            jmp _for_loop                   ; Loop for next position in array

    end_for_loop:
        ; Epilogue
        mov rsp, rbp
        pop rbp
        ret

_malloc:
    ; Prologue
    push rbp
    mov rbp, rsp

    ; returns pointer to allocated memory on heap in rax
    mov rax, 0x9
    mov rdi, NULL       
    mov rsi, malloc_size      
    mov rdx, PROT_NONE
    mov r10, MAP_ANONYMOUS
    or r10, MAP_PRIVATE
    mov r8, 0x00
    mov r9, 0x00
    syscall
    mov [array_ptr], rax

    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret

_free:
    ; Prologue
    push rbp
    mov rbp, rsp

    ; free (munmap syscall)
    ; returns 0x00 in rax if succesful
    mov rax, 0xb
    mov rdi, [array_ptr]
    mov rsi, malloc_size
    syscall

    ; Epilogue
    mov rsp, rbp
    pop rbp
    ret

_print:
    ; Prologue
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

    ; Epilogue
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
    ; print connection created
    push connection_t_msg_l
    push connection_t_msg
    call _print
    ret

_file_not_created:
    ; print file was not created
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
    ; Write to stdout that bytes were not written to file
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
