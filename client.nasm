; by Benjamin, Monik, Hasan, Yu Jin
; ISS Program, SAIT
; 
; x86-64, NASM

; *******************************
; Functionality of the program:
; 
; *******************************

section .text
global _start

_start:


    jmp _exit

_exit:
    mov rax, 60
    mov rdi, 0
    syscall


section .data


section .bss
