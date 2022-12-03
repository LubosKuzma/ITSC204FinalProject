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

    call _client.prompt
    call _client.read
    call _client.write
    call _client.read_from_the_socket
    push rax

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
        mov rax, 0x01                       ; write syscall
        mov rdi, 0x01                       ; FD 1 into RDI
        mov rsi, prompt_msg                 ; prompt_msg buffer into RSI
        mov rdx, prompt_msg_l               ; prompt_msg buffer length into RDX
        syscall

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
        mov rsi, msg_buf                    ; store message buffer pointer into rsi
        mov rdx, 0x03                       ; store message buffer length into rdx
        syscall

        mov rax, 35                         ; sleep syscall
        mov rdi, delay
        mov rsi, 0
        syscall

        ret

    .read_from_the_socket:

        mov rax, 0x00                       ; read syscall
        mov rdi, qword[socket_fd]           ; read socket fd into rdi
        mov rsi, random_array               ; move random_array buffer into rsi
        mov rdx, 0x500                      ; move random_array length into rdx
        syscall
        
        push rax
        ret       

_sort:
    ; NEEDS  TO BE PASSED THE NUMBER OF CHARACTERS ON THE STACk (minus one for newline) 

    push rbp                            ; Prologue
    mov rbp, rsp

    add rsp, 0x8                        ;[rbp - 0x08] = local variable for the max value in the array

    ; LOOP 1 
    ; Find the max value in the array, 0 to the size of the array
    mov r8, 0x0                         ; Set the counter to zero
    mov bl, byte [array]                ; Set the first value as the max (bl is the temp max variable to reduce mov's)
    .MaxLoop:
    cmp bl, byte [array + r8]               ; Compare the current arry value to the max
    jg .MaxLoopSkip                    ; If less than or equal to the max then skip

    mov bl, byte [array + r8]          ; Else set new max value stored to bl

    .MaxLoopSkip:
    cmp r8, [rbp + 0x10]                ; Compare against number of elements in array (passed via stack)
    jge .MaxLoopEnd                     ; If 
    inc r8
    jmp .MaxLoop
    .MaxLoopEnd:
    mov [rbp - 0x8], bl                 ; Save the highest value to local variable (max variable)
    

    ; Dynamically create an array "count" of the size of the maximum value in the array

    ; **TODO**


    ; LOOP 2
    ; Increment the count of occurences in the count array at each values position respective position in the array (eg 4 -> count[4]++)
    mov r8, 0x0                         ; Set counter to zero
    mov rbx, 0x0
    mov r9, [rbp + 0x10]                ; Load r9 with the number of characters
    dec r9                              ; Subtract 1 from r9 cause array starts from zero
    .CountLoop:
    mov bl, byte [array + r8]           ; Get current value from the main array
    mov al, byte [count + rbx]          ; Use current value to access its literal index in the count array (# of occurences for each val at their respective locations)
    inc rax                             ; Increase the count of the number of occurences of the current value by 1
    mov [count + rbx], al               ; Replace old value with incremented occurences count value
    
    cmp r8, r9                          ; Check to see if the end of the array has been reached
    jge .CountLoopEnd                   ; End if yes, increment and repeat if no
    inc r8  
    jmp .CountLoop
    .CountLoopEnd:

    ; LOOP 3
    ; Perform running count of count array (add every the previous index to the current index)
    mov r8, 0x1                         ; Counter, start at 1 because we will be adding the previous value to the current value
    .RunningCountLoop:                  
    mov al, byte [count + r8]           ; Get the current increment position in count array
    mov bl, byte [count + r8 -1]        ; Repeat 
    add al, bl
    mov [count + r8], al

    cmp r8, [rbp - 0x8]                 ; Compare against the maximum value in found in the array from earlier
    jge .RunningCountLoopEnd
    inc r8                              ; Increment the counter 
    jmp .RunningCountLoop               ; Repeat
    .RunningCountLoopEnd:

    ; LOOP 4
    ; Go back through the array, go to each values position in the count array and put it in the output array at the sum position held in the count array
    mov r8, [rbp + 0x10]                 ; start at the end of the array
    dec r8
    .InsertionLoop:
    mov al, byte [array + r8]           ; Load the value from the current array position
    mov bl, byte [count + rax]          ; Use the array value to access its corresponding cummulative value in the count array
    mov [output + rbx - 1], al          ; Insert this value into the output array at the index of the cumulative value from above
    dec bl                              ; Decrement the cumulative value
    mov [count + rax], bl               ; Return decremented cumulative to count array

    cmp r8, 0x0                         ; if counter is zero (at last element) end the loop, else decrement and repeat
    jle .InsertionLoopEnd
    
    dec r8
    jmp .InsertionLoop
    .InsertionLoopEnd:

    mov rsp, rbp                        ; Epilogue
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
    msg_buf:                 resb 3             ; message buffer
    random_array:            resb 0x500         ; reserve 1024 bytes
    count: resb 0x100                           ; Space for count array in _sort
    output: resb 0x100                          ; Space for output array in _sort