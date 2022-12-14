; Author: Nathaniel Pawluk
; Date: December 11th, 2022
; Course: ITSC204
; Details: Client side of server connection + data manipulation + save to file
; Much of the code is also labeled as it came from C

; struct for sock addr
struc sockaddr_in_type
    .sin_family:        resw 1
    .sin_port:          resw 1
    .sin_addr:          resd 1
    .sin_zero:          resd 2
endstruc

section .text
    global _start

_start:	
	;if((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0){
	;printf("FAILED TO CREATE SOCKET");
	;return -1;}

    mov rax, 0x29   ; Socket(
    mov rdi, 0x02   ; AF_INET,
    mov rsi, 0x01   ; SOCK_STREAM,
    mov rdx, 0x00   ; 0)
    syscall
    cmp rax, 0x00           ; if return of socket < 0
    jl _socket_fail         ; creation of socket failed
    mov [socket_fd], rax    ; save sock file descriptor to socket_fd

    mov rax, 0x2A               ; connect(
    mov rdi, qword [socket_fd]  ; sockfd,
    mov rsi, sockaddr_in        ; (struct sockaddr*)&server_addr,
    mov rdx, sockaddr_in_l      ; sizeof(server_addr))
    syscall
    cmp rax, 0x00               ; if return of connect < 0
    jl _connect_fail            ; the connection failed

    ;send(sockfd, bytes, strlen(bytes), 0)

    mov rax, 0x2C                ; send(
    mov rdi, qword [socket_fd]   ; socket_fd,
    mov rsi, message_to_send     ; "120\n"
    mov rdx, message_to_send_len ; 4
    mov r10, 0x00                ; flags (none)
    syscall

    ;printf("Message sent!\n")

    mov rax, 0x01
    mov rdi, 0x01
    mov rsi, sent
    mov rdx, sent_len
    syscall

    ; Set up new breakpoint

    mov rax, 0xc        ; brk syscall
    mov rdi, 0x0        ; Return the current break point
    syscall    

    mov [array_ptr], rax; Save returned base address to array_ptr

    mov rdi, rax        ; Load break point into rdi
    add rdi, 0x200      ; Increment breakpoint by 100,000 bytes
    mov rax, 0xc        ; Call brk
    syscall

	;printf("Waiting for response\n")

    mov rax, 0x01
    mov rdi, 0x01
    mov rsi, waiting
    mov rdx, waiting_len
    syscall

    ; recv(sockfd, buffer, strlen(buffer), 0, (struct sockaddr*_&server_addr, sizeof(server_addr))

    mov rax, 0x2D           ; recvfrom
    mov rdi, [socket_fd]    ; sockfd
    mov rsi, [array_ptr]    ; buffer
    mov rdx, 0x120          ; buffer size
    mov r10, 0x100          ; flags
    mov r8, 0x0             ; parameter not needed 
    mov r9, 0x0             ; parameter not needed
    syscall

	; fp = open("output.txt", "w")

    mov rax, 0x2        ; open(
    mov rdi, filename   ; "output.txt",
    mov rsi, 0102o      ; "rw")
    mov rdx, 0666o      ; file permissions (r/w)
    syscall

    cmp rax, 0x00       ; if failed to create file
    jl _file_error

    mov [fp], rax       ; save file descriptor under (F)ile (P)ointer

    ;write(fp, first_section, first_section_len)

    mov rax, 0x01                   ; write(
    mov rdi, [fp]                   ; fp,
    mov rsi, first_section          ; "BEGINNING OF RECEIVED DATA"
    mov rdx, first_section_len      ; strlen(first_section)
    syscall

    ;write(fp, buffer, buffer_len)

    mov rax, 0x01           ; write(
    mov rdi, [fp]           ; fp,
    mov rsi, [array_ptr]    ; &array_ptr, -- Space created by brk
    mov rdx, 0x120          ; 120 bytes
    syscall

    ; insertionSort(array_ptr)

    push rdx
    push rcx
    push rbx
    push [array_ptr]
    call _insertion_sort
    add rsp, 0x08
    pop rbx
    pop rcx
    pop rdx

    ; write(fp, second_section, second_section_len)

    mov rax, 0x01
    mov rdi, [fp]
    mov rsi, second_section
    mov rdx, second_section_len
    syscall

    ; write(fp, buffer, buffer_len)

    mov rax, 0x01
    mov rdi, [fp]
    mov rsi, [array_ptr]
    mov rdx, 0x120
    syscall

    ;close(clientfd);

    mov rax, 0x03
    mov rdi, [socket_fd]
    syscall

    ;close(fp)
    mov rax, 0x03
    mov rdi, [fp]
    syscall

    jmp _exit

_insertion_sort:
    ; i = rax
    ; len(array) = rbx
    ; key = cl
    ; j = rdx
    ; array[j] = r8b
    ; array_ptr = r9
    push rbp
    mov rbp, rsp

    push rdi
    push rsi

    mov r9, [rbp - 0x08]

    mov rax, 0x1          ; al = i
    mov rbx, 0x120        ; bl = len(array)
    mov rcx, 0x0          ; clear registers
    mov rdx, 0x0 
    mov r8, 0x0

    .forloop:
    cmp rax, rbx          ; for i in range(1, len(array))
    jg .end
    
    mov cl, byte [r9 + rax]   ; key = array[i]

    mov rdx, rax  ; j = i - 1
    sub rdx, 0x1

    .whileloop:
    cmp rdx, 0x00            ; while j >= 0
    jl .end_of_forloop
    mov r8b, byte [r9 + rdx] 
    cmp rcx, r8              ; and key > array[j]
    jle .end_of_forloop
    mov byte [r9 + rdx + 1], r8b ; array[j + 1] = array[j]
    sub rdx, 0x1             ; j -= 1
    jmp .whileloop

    .end_of_forloop:
    inc rdx
    mov byte [r9 + rdx], cl ; array[j + 1] = key
    inc rax
    jmp .forloop

    .end:
    pop rsi
    pop rdi
    mov rsp, rbp
    pop rbp
    ret

_print:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi

    mov rax, 0x1
    mov rdi, 0x1
    mov rsi, [rbp + 0x10]
    mov rdx, [rbp + 0x18]
    syscall

    pop rsi
    pop rdi
    pop rbp
    ret

_socket_fail:
    push rdx 
    push rcx
    push rbx
    push socket_failed_len
    push socket_failed
    call _print
    add rsp, 0x10
    pop rbx
    pop rcx
    pop rdx
    jmp _exit

_connect_fail:
    push rdx 
    push rcx
    push rbx
    push connection_failed_len
    push connection_failed
    call _print
    add rsp, 0x10
    pop rbx
    pop rcx
    pop rdx
    jmp _exit

_file_error:
    push rdx 
    push rcx
    push rbx
    push file_fail_len
    push file_fail
    call _print
    add rsp, 0x10
    pop rbx
    pop rcx
    pop rdx
    jmp _exit

_exit:
    mov rax, 0x3C
    mov rdi, 0x00
    syscall

section .bss
    socket_fd: resq 1
    client_fd: resq 1
    ;to_send: resb 4
    buffer: resb 1024
    buffer_len: resq 1
    array_ptr resq 1

section .data
    socket_failed: db "FAILED TO CREATE SOCKET", 0xA, 0x0
    socket_failed_len: equ $ - socket_failed
    connection_failed: db "FAILED TO CONNECT", 0xA, 0x0
    connection_failed_len: equ $ - connection_failed
    message_to_send: db "120", 0xA
    message_to_send_len: equ $ - message_to_send
    sent: db "MESSAGE SENT", 0xA, 0x0
    sent_len: equ $ - sent
    waiting: db "WAITING FOR RESPONSE", 0xA, 0x0
    waiting_len: equ $ - waiting
    filename: db "output.txt", 0x0
    fp: dq 0
    file_fail: db "FAILED TO CREATE FILE", 0x0
    file_fail_len: equ $ - file_fail
    first_section: db "BEGINNING OF RECEIVED DATA", 0xA
    first_section_len: equ $ - first_section
    second_section: db 0xA, "BEGINNING OF SORTED DATA", 0xA
    second_section_len: equ $ - second_section    

    sockaddr_in:
        istruc sockaddr_in_type

            at sockaddr_in_type.sin_family, dw 0x02
            at sockaddr_in_type.sin_port,   dw 0xE027       ; Port 10208
            at sockaddr_in_type.sin_addr,   dd 0xB886EE8C   ; 140.238.134.184

        iend
    sockaddr_in_l: equ $ - sockaddr_in