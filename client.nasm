; by Benjamin, Monik, Hasan, Yu Jin
; ISS Program, SAIT
; 
; x86-64, NASM

; *******************************
; Functionality of the program:
; 
; *******************************

; Values for malloc
NULL            equ 0x00
MAP_SHARED      equ 0x01
MAP_PRIVATE     equ 0x02
MAP_FIXED       equ 0x10
MAP_ANONYMOUS   equ 0x20
PROT_NONE       equ 0x00
PROT_READ       equ 0x01
PROT_WRITE      equ 0x02
PROT_EXEC       equ 0x04

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

    call _client

    sub rax, 0x1
    push rax
    call _sort
    add rsp, 0x8

    jmp _exit

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


_client:
    .prompt:

        push prompt_msg_l                   ; C Calling Convention to prompt user
        push prompt_msg                     ; to input their desired number of bytes
        call _print


        ; mov rax, 0x01                       ; write syscall
        ; mov rdi, 0x01                       ; FD 1 into RDI
        ; mov rsi, prompt_msg                 ; prompt_msg buffer into RSI
        ; mov rdx, prompt_msg_l               ; prompt_msg buffer length into RDX
        ; syscall

    .read:
        mov rax, 0x00                       ; read syscall
        mov rdi, 0x00                       ; to read the user input into
        mov rsi, msg_buf                    ; a dedicated buffer
        mov rdx, 0x04                       
        syscall
        
    .write:
        
        mov rax, 0x01                       ; write syscall
        mov rdi, qword[socket_fd]           ; to write the user input buffer
        mov rsi, msg_buf                    ; into the socket created earlier
        mov rdx, 0x04                       
        syscall

        mov rax, 35                         ; sleep syscall serves to delay program execution
        mov rdi, delay                      ; by little to allow the sending of bytes
        mov rsi, 0                          ; to be completed before the next read
        syscall                             ; reaches the end of the file

    .read_from_the_socket:

        mov rax, 0x00                       ; read syscall
        mov rdi, qword[socket_fd]           ; to retrieve the user input value
        mov rsi, random_array               ; from socket, to submit to the sorting algorithm
        mov rdx, 0x500                      
        syscall
              

_sort:
    push rbp                            ; Prologue
    mov rbp, rsp


    ; LOOP 1 
    ; Find the max value in the array, go from 0 to the size of the recieved array
    mov r8, 0x0                         ; Set the counter to zero
    mov bl, byte [random_array]                ; Set the first value as the max (bl is the temp max variable to reduce mov's)
    .MaxLoop:
    cmp bl, byte [random_array + r8]           ; Compare the current arry value to the max
    jg .MaxLoopSkip                     ; If less than or equal to the max then skip

    mov bl, byte [random_array + r8]           ; Else set new max value stored to bl

    .MaxLoopSkip:
    cmp r8, [rbp + 0x10]                ; Compare against total number of elements in array (size of array was passed via stack)
    jge .MaxLoopEnd                     
    inc r8
    jmp .MaxLoop
    .MaxLoopEnd:
    push rbx                             ; Pass the max value (in bl) to malloc function


    ; MEMORY CREATION FOR COUNT ARRAY
    ; Dynamically create an array "count" of the size of the maximum value in the array
    call _memAllocation
    mov r15, rax                        ; Save the return value from mmap into r15 for direct use
    xor rax, rax                        ;r15 will be used to reference the newly created count array that is the size the max value in the original array


    ; LOOP 2
    ; Increment the count of occurences in the count array at each values position respective position in the array (eg 4 -> count[4]++)
    mov r8, 0x0                         ; Set counter to zero
    mov rbx, 0x0
    mov r9, [rbp + 0x10]                ; Load r9 with the number of characters
    dec r9                              ; Subtract 1 from r9 cause array starts from zero
    .CountLoop:
    mov bl, byte [random_array + r8]    ; Get current value from the main array
    mov al, byte [r15 + rbx]            ; Use current value to access its literal index in the count array (# of occurences for each val at their respective locations)
    inc rax                             ; Increase the count of the number of occurences of the current value by 1
    mov [r15 + rbx], al                 ; Replace old value with incremented occurences count value
    
    cmp r8, r9                          ; Check to see if the end of the array has been reached
    jge .CountLoopEnd                   ; End if yes, increment and repeat if no
    inc r8  
    jmp .CountLoop
    .CountLoopEnd:


    ; LOOP 3
    ; Perform running count of count array (add every the previous index to the current index)
    mov r8, 0x1                         ; Counter, start at 1 because we will be adding the previous value to the current value
    .RunningCountLoop:                  
    mov al, byte [r15 + r8]             ; Get the current number of occurences at the given index in count array
    mov bl, byte [r15 + r8 -1]          ; Get the number of occurences at the previous index
    add al, bl                          ; Add the values together
    mov [r15 + r8], al

    cmp r8, [rbp - 0x8]                 ; Compare against the maximum value in found in the array from earlier
    jge .RunningCountLoopEnd
    inc r8                              ; Increment the counter 
    jmp .RunningCountLoop               ; Repeat
    .RunningCountLoopEnd:


    ; LOOP 4
    ; Go back through the array, go to each values position in the count array and put it in the output array at the sum position held in the count array
    mov r8, [rbp + 0x10]                ; start at the end of the array
    dec r8
    .InsertionLoop:
    mov al, byte [random_array + r8]    ; Load the value from the current array position
    mov bl, byte [r15 + rax]            ; Use the array value to access its corresponding cummulative value in the count array
    mov [output + rbx - 1], al          ; Insert this value into the output array at the index of the cumulative value from above
    dec bl                              ; Decrement the cumulative value
    mov [r15 + rax], bl                 ; Return decremented cumulative to count array

    cmp r8, 0x0                         ; if counter is zero (at last element) end the loop, else decrement and repeat
    jle .InsertionLoopEnd
    
    dec r8
    jmp .InsertionLoop
    .InsertionLoopEnd:

    push r15
    call _memFree


    add rsp, 0x10                        ; Remove rbx (max value) from the stack that was passed earlier and r15 (created count array)
    mov rsp, rbp                        ; Epilogue
    pop rbp
    ret

_memAllocation:
    push rbp                            ; Prologue
    mov rbp, rsp

    mov rax, 0x9            ; Mmap syscall (malloc)
    mov rdi, NULL       
    mov rsi, [rbp + 0x10]   ; Load max value that was passed via stack   
    mov rdx, PROT_EXEC
    or rdx, PROT_READ
    or rdx, PROT_WRITE
    mov r10, MAP_ANONYMOUS
    or r10, MAP_PRIVATE
    mov r8, 0x00
    mov r9, 0x00
    syscall

    mov rsp, rbp                        ; Epilogue
    pop rbp
    ret

_memFree:
    push rbp                ; Prologue
    mov rbp, rsp

    mov rax, 0xb             ; Free syscall
    mov rdi, [rbp + 0x10]    ; Array to de-allocate
    mov rsi, [rbp + 0x18]    ; Size to de-allocate (max value that was loaded onto stack earlier)
    syscall

    mov rsp, rbp            ; dealocating the stack
    pop rbp

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

_Print_start:
    push rbp                            ;Prologue
    mov rbp, rsp
    
    .Creat_file:
    mov     rsi, 511                    ;create file mod
    mov     rdi, filename               ;filename
    mov     rax, 0x55                   ;creat syscall
    syscall
    cmp     rax, 0                      ;if rax = 0, the file had exist.
    jz      .Open_file
    cmp     rax, 0                      ;if rax <0, the file create error
    jl      .Creat_file_error
    mov     [Handle], rax               ;save our file descriptor 
    jmp     .Print_IN_file              ;jump to print in file

    .Creat_file_error                   ;check the create is error or not 
    mov     rax, 0x1    
    mov     rdi, 1
    mov     rsi, Creat_file_error
    mov     rdx, Creat_file_error_L     ;print "This file create error, Please try again"
    syscall
    jmp     _exit                       

    .Open_file:
    mov     rax, 0x2                    ;open syscall
    mov     rdi, filename               ;open the file if the file have existed
    mov     rsi, 0x2
    mov     rdi, 0x2                    
    syscall
    mov     [Handle], rax               ;save our file descriptor 
    jmp     .Print_start

    .Print_IN_file:
    mov     rdx, Nosort_notice_L  
    mov     rsi, Nosort_notice
    call    print                       ;print "This is beginning of No sort data:" in file

    mov     rdx, [rbp + 0x10]           ;Our length of array is saved in [rbp+0x10]
    mov     rsi, random_array           ;Our sort array is saved in random_array
    call    print

    mov     rdx, Sort_notice_L          
    mov     rsi, Sort_notice            
    call    print                       ;print "This is beginning of sort data:" in file

    mov     rdx, [rbp + 0x10]           ;Our length of array is saved in [rbp+0x10]
    mov     rsi, output                 ;Our sort array is saved in output
    call    print
    
    mov     rsp, rbp                    ; dealocating the stack
    pop     rbp
    ;jmp _exit                          ;if we need to jump to exit function

    print:
    mov     rdi, [Handle]
    mov     rdx, rdx
    mov     rsi, rsi
    mov     rax, 1
    syscall
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

    connect_f_msg:   db "Socket failed to be connected.", 0xA, 0x0
    connect_f_msg_l: equ $ - connect_f_msg

    connect_t_msg:   db "Socket connected.", 0xA, 0x0
    connect_t_msg_l: equ $ - connect_t_msg

    prompt_msg:    db "Enter any value between (0x)100 and (0x)4FF", 0xA, 0x00
    prompt_msg_l: equ $ - prompt_msg

    delay dq 1, 000000000

    filename: db 'TeamNASM.txt', 0x0    ; the filename to create

    Creat_file_error:  db "This file create error, Please try again", 0xA, 0x0
    Creat_file_error_L: equ $ - Creat_file_error

    Sort_notice: db "This is beginning of No sort data:", 0xA, 0x0
    Nosort_notice_L: equ $ - Sort_notice

    Sort_notice: db "This is beginning of sort data:", 0x0
    Sort_notice_L equ $ - Sort_notice

    Handle dq 10






    sockaddr_in: 
        istruc sockaddr_in_type 

            at sockaddr_in_type.sin_family,  dw 0x02            ;AF_INET -> 2 
            at sockaddr_in_type.sin_port,    dw 0xDE27          ;port in hex and big endian order, 10206 -> 0xDE27 
            at sockaddr_in_type.sin_addr,    dd 0xB886EE8C      ;address 140.238.134.184 -> 0xB886EE8C

        iend
    sockaddr_in_l:  equ $ - sockaddr_in

section .bss
    socket_fd:               resq 1             ; socket file descriptor
    read_buffer_fd           resq 1             ; file descriptor for read buffer
    chars_received           resq 1             ; number of characters received from socket
    msg_buf:                 resb 4             ; message buffer
    random_array:            resb 0x500         ; reserve 1024 bytes
    output: resb 0x500                          ; Space for output array in _sort