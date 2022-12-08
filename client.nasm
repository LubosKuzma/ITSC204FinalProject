; ITSC204 - Final Project Client Side
; based on socket networking system calls
; x86-64 Linux
; Created by Jinbin Han
; Team MOV: Vincent, Jinbin, and Kanwar
; SADT, SAIT
; on December 2022
; This program is a client side of a socket networking system.

%include "socket.nasm"

section .data

section .bss

section .text

global _start

_start:
    push rbp
    mov rbp, rsp

    call _init_socket                   ; initialize socket
    call _send_rec                      ; send and receive data

    ;Just a test print recieve data from server
    mov rax, 0x01                       ; write syscall
    mov rdi, 0x01                       ; fd - 1 for stdout
    mov rsi, rec_buffer                 ; buffer
    mov rdx, 0x100                      ; must match the requested number of bytes
    syscall

    ;If the server sends a message to the client can be received by the client correctly
    ;store the massaget to a file

    
    
    
    


    

    jmp _exit






