; By Team x86
; Date: 2022-12-10
; Course: ITSC204 lab4
; Function: TCP connection to designated server
;           send message to server and receive payload 
;           store payload to heap
;           sort payload using quick sort method
;           write the payload and result to a file 


;*****************************
struc sockaddr_in_type
; defined in man ip(7) because it's dependent on the type of address
    .sin_family:        resw 1
    .sin_port:          resw 1
    .sin_addr:          resd 1
    .sin_zero:          resd 2          ; padding       
endstruc

;*****************************

NULL            equ 0x00
MAP_SHARED      equ 0x01
MAP_PRIVATE     equ 0x02
MAP_FIXED       equ 0x10
MAP_ANONYMOUS   equ 0x20
PROT_NONE       equ 0x00
PROT_READ       equ 0x01
PROT_WRITE      equ 0x02
PROT_EXEC       equ 0x04
MSG_DONTWAIT    equ 0x40
MSG_WAITALL     equ 0x100
malloc_size     equ 0x400
count           equ 0x99

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

    number: db "100", 0xA ; command sent to server
    number_l: equ $ - number

    mesg1: db "-----BEGINNING OF RANDOM DATA SECTION-----", 0xA,0xA
    mesg1_l: equ $ - mesg1

    mesg2: db 0XA,0xA, "-----BEGINNING OF MANIPULATED DATA SECTION USING QUICK SORT-----", 0xA,0xA
    mesg2_l: equ $ - mesg2

    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0xDF27        ;(DEFAULT, passed on stack) port in hex and big endian order, 10209 -> 0xE127
            at sockaddr_in_type.sin_addr,    dd 0xB886EE8C       ;(DEFAULT) 00 -> any address, address 140.238.134.184 -> 0xB886EE8C 

        iend
    sockaddr_in_l:  equ $ - sockaddr_in

    space: db 0xA
    space_l: equ $ - space

section .bss

    ; global variables
    file_fd                  resq 1             ; file opened file descriptor
    socket_fd:               resq 1             ; socket file descriptor        
    message_buf_l            resq 4             ; length of message recieved from server
    mem_map_ptr              resq 1             ; store memory pointer for allocated memory, used to store data recieved from server


section .text
    global _start
 
_start:

    call _malloc.allocate    ; allocating memory 

    call _network.init  ; netowrk in intillaized 

    call _network.connection    ; connecting to the server

    call _network.send   ; sending message to the server

    call _network.recieve   ; recieving message from the server 




    call _file.create         ; opening a file name data.txt


    push mesg1_l
    push mesg1
    call _file.write
    add rsp, 0x10   ; clear arg entry from stack

    call _file.append

    

    push 0x100
    push mem_map_ptr
    call _file.write        ; writing data recieved from the server to the file
    add rsp, 0x10   ; clear arg entry from stack

    call _file.append

    push mesg2_l
    push mesg2
    call _file.write

    ;call _loop1              ; storing data in array

    ; pass pointer to array by r8 throughout _quickSort
    xor r8,r8
    lea r8, [mem_map_ptr]

    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push 99 ; high (arg2)    *** length of (array - 1) here
    push 0             ; low (arg1)
    call _quickSort
    add rsp, 0x10   ; clear arg entry from stack
    pop rbx
    pop rcx
    pop rdx

    push 0x100
    push mem_map_ptr
    call _file.write        ; writing data recieved from the server to the file
    add rsp, 0x10   ; clear arg entry from stack


    call _malloc.free       ; free memory allocated 
    call _file.close        ; closing the file 
    jmp _exit
        

_loop1:

    mov rcx, 0x0

    .rep:

    ;lea r8, [message_buf + rcx]

    cmp rcx, 0x100
    jg .end
    mov rax, 1
    mul rcx
    mov rbx, rax
    lea rax, [mem_map_ptr + rbx]
    mov [rax], r8
    inc rcx

    jmp .rep


    .end:
        ret


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
        ret

    .send:      
        ; sending message to server using sendto system call

        mov rax, 0x2C
        mov rdi,  [socket_fd]
        mov rsi, number
        mov rdx, number_l
        mov r10, MSG_DONTWAIT
        mov r8, sockaddr_in
        mov r9, sockaddr_in_l
        syscall


        cmp rax, 0x0
        jl _message_sent_f
        call _message_sent
        ret

    .recieve:  
        ; recieving data from the server using revfrom syscall

        mov rax, 0x2D
        mov rdi, [socket_fd]
        mov rsi,  mem_map_ptr   
        mov rdx,  0x100
        mov r10, MSG_WAITALL
        mov r8, 0x00
        mov r9, 0x00
        syscall
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

        ; amended callee epilogue
        pop rsi
        pop rdi
        mov rsp, rbp ; deallocate local variable
        pop rbp     
        ret

        ; *** epilogue with issue, it would remove one more entry in stack, causing critical error***
        ; pop rsi
        ; pop rdi
        ; pop rbp
        ; ret 0x10                                ; clean up the stack upon return - not strictly following C Calling Convention 


   
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

        ; amended callee epilogue
        pop rsi
        pop rdi
        mov rsp, rbp ; deallocate local variable
        pop rbp     
        ret

        ; *** epilogue with issue, it would remove one more entry in stack, causing critical error***
        ; pop rsi
        ; pop rdi
        ; pop rbp
        ; ret 0x10                                ; clean up the stack upon return - not strictly following C Calling Convention  

    .append:
        ; using lseek() syscall to change file offset to append data

        ; prologue
        push rbp
        mov rbp, rsp
        push rdi
        push rsi

       
        mov rax, 0x8
        mov rdi, [file_fd]
        mov rsi, 0x0                        ; data to write to file
        mov rdx, 1                                         
        syscall

    ; [rbp + 0x10] -> buffer pointer


    ; amended callee epilogue
        pop rsi
        pop rdi
        mov rsp, rbp ; deallocate local variable
        pop rbp     
        ret

        ; *** epilogue with issue, it would remove one more entry in stack, causing critical error***
        ; pop rsi
        ; pop rdi
        ; pop rbp
        ; ret 0x10                                ; clean up the stack upon return - not strictly following C Calling Convention



    .close:                                 ; close the file

        mov rax, 0x3
        mov rdi, [file_fd]                      
        syscall
        ret


_malloc:

    .allocate:
    ; malloc (mmap syscall)
    ; returns pointer to allocated memory on heap in rax
    mov rax, 0x9
    mov rdi, NULL       
    mov rsi, malloc_size      
    mov rdx, PROT_WRITE
    mov r10, MAP_ANONYMOUS
    or r10, MAP_PRIVATE
    mov r8, 0x00
    mov r9, 0x00
    syscall
    mov [mem_map_ptr], rax
    ret

    .free:
    ; free (munmap syscall)
    ; returns 0x00 in rax if succesful
    mov rax, 0xb
    mov rdi, [mem_map_ptr]
    mov rsi, malloc_size
    syscall


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


_quickSort:
; Inspired by https://www.geeksforgeeks.org/quick-sort/
; nasm function to quick sort data 

    ; callee prologue
    push rbp
    mov rbp, rsp
    sub rsp, 0x08 ; allocate place for 1 local variable
    push rsi
    push rdi
    


    ; if low >= high, end function
    mov rbx, [rbp + 0x10]
    mov rcx, [rbp + 0x18]
    cmp rbx, rcx
    jae .end

    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push qword [rbp + 0x18] ; high (arg2)
    push qword [rbp + 0x10] ; low (arg1)
    call _partition
    add rsp, 0x10   ; clear arg entry from stack
    mov qword [rbp - 0x08], rax ; store to local variable, the pivot location returned
    pop rbx
    pop rcx
    pop rdx

    ; load pivot + 1
    xor r9, r9
    mov r9, [rbp - 0x08]
    inc r9

    ; recursive call to self to sort all partition after pivot
    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push qword[rbp + 0x18] ; high (arg1)
    push r9                ; pivot + 1 (arg0)
    call _quickSort
    add rsp, 0x10   ; clear arg entry from stack
    pop rbx
    pop rcx
    pop rdx

    ; load pivot - 1
    xor r9, r9
    mov r9, [rbp - 0x08]
    dec r9

    ; recursive call to self to sort all partition before pivot
    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push qword [rbp + 0x10] ; low (arg1)
    push r9                 ; pivot - 1 (arg0)
    call _quickSort
    add rsp, 0x10   ; clear arg entry from stack
    pop rbx
    pop rcx
    pop rdx


    .end:
        ; callee epilogue
        pop rdi
        pop rsi
        mov rsp, rbp ; deallocate local variable
        pop rbp     
        ret


_partition:

    ; callee prologue
    push rbp
    mov rbp, rsp
    sub rsp, 0x10 ; allocate place for 2 local variables
    push rsi
    push rdi
    push r9
    push r10


    ; initialize local variables
    mov rbx, [rbp + 0x18] ;
    mov qword [rbp - 0x10], rbx ; move high to j counter variable
    inc rbx
    mov qword [rbp - 0x08], rbx ; move high + 1 to i counter variable


    xor rbx, rbx
    xor rcx, rcx
    ; pivot is at first element of range of the partition set
    ; pivot value is stored in rbx
    mov rcx, [rbp + 0x10]
    lea rbx, [r8 + rcx * 1]

    xor rdx, rdx
    ; load low + 1 to rdx as loop end condition 
    mov rdx, [rbp + 0x10]
    inc rdx

    .loop:

        ; if j < low + 1, end loop
        cmp [rbp + 0x10], rdx
        jb .loop_end

        xor r10, r10
        xor rcx, rcx
        ; load address of array element indexed with j (arg1)
        mov rcx, [rbp - 0x10]
        lea r10, [r8 + rcx * 4]

        xor r9, r9
        xor rcx, rcx
        ; if arr[j] > pivot, do sorting operation
        mov r9b , [r10]
        mov cl, [rbx]
        cmp r9b, cl
        jae .sorting

        ; else decrement to counter j and repeat loop
        dec qword [rbp - 0x10] 
        jmp .loop

        .sorting:
            dec qword [rbp - 0x08] ; decrement index i counter

            xor r9, r9
            xor rcx, rcx
            ; load address of array element indexed with i (arg0)
            lea r9, [r8]
            mov rcx, [rbp - 0x08]
            lea r9, [r9 + rcx * 1]


            ; Caller C calling convention
            push rdx
            push rcx
            push rbx
            call _swap
            ;add rsp, 0x10   ; clear arg entry from stack
            pop rbx
            pop rcx
            pop rdx

            ; decrement to counter j and repeat loop
            dec qword [rbp - 0x10] 
            jmp .loop

    .loop_end:
        dec qword [rbp - 0x08] ; i - 1

        xor r9, r9
        xor rcx, rcx
        ; load address of array element indexed with i - 1 (arg0)
        mov rcx, [rbp - 0x08]
        lea r9, [r8 + rcx * 1]

        xor r10, r10
        ; load address of array element of pivot (arg1)
        lea r10, [rbx]

        ; Caller C calling convention
        push rdx
        push rcx
        push rbx
        call _swap
        ;add rsp, 0x10   ; clear arg entry from stack
        pop rbx
        pop rcx
        pop rdx

        xor rax, rax
        mov rax, [rbp - 0x08] ;return i - 1


    ; callee epilogue
    pop r10
    pop r9
    pop rdi
    pop rsi
    mov rsp, rbp ; deallocate local variable
    pop rbp     
    ret

_swap:

; callee prologue
    push rbp
    mov rbp, rsp
    push rsi
    push rdi

    xor rcx, rcx
    mov cl, [r9] ; content of address 1 is stored here

    xor rdx, rdx
    mov dl, [r10] ; address 2

    mov byte [r9], dl ; address 1 content <- address 2 content
    mov byte [r10], cl ; address 2 content <- address 1 content

    ; callee epilogue
    pop rdi
    pop rsi
    mov rsp, rbp ; deallocate local variable
    pop rbp     
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




_exit:

    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall