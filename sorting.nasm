section .text
global _start

_start:
    mov rdi, filename
    mov rsi, 0102o
    mov rdx, 0666o
    mov rax, 2
    syscall

    mov [fd], rax
    mov rdx, len
    mov rsi, msg
    mov rdi, [fd]
    mov rax, 1
    syscall

    mov rdi, [fd]
    mov rax, 3
    syscall

    mov rax, 60
    syscall

section .data
    msg db 'Hello World', 0xa
    len equ $ - msg
    filename db 'output.txt', 0
    lenfilename equ $ - filename
    fd dq 0