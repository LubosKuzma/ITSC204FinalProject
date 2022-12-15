; 64-bit cocktail sort

section .data
    ; file to read from
    filename db "output.txt", 0
    ; flags for sys_open syscall
    O_RDONLY equ 0

section .bss
    ; buffer to hold array
    buffer resq 100

section .text
    global _start

_start:
    ; open file
    mov rax, 2
    mov rdi, filename
    mov rsi, O_RDONLY
    syscall

    ; read array from file into buffer
    mov rbx, rax
    mov rax, buffer
    mov rdi, rbx
    mov rsi, buffer
    mov rdx, 100
    syscall

    ; set up registers
    mov rax, buffer
    mov rbx, 100
    mov rcx, 1
    dec rbx

sort_loop:
    ; swap direction if at beginning or end of array
    cmp rcx, 0
    jz sort_down
    cmp rcx, rbx
    jz sort_up

sort_next:
    ; compare current and next element
    mov rdx, [rax + rcx * 8]
    cmp rdx, [rax + (rcx + 1) * 8]
    jle sort_continue

    ; swap elements if out of order
    xchg rdx, [rax + (rcx + 1) * 8]
    mov [rax + rcx * 8], rdx

sort_continue:
    ; move to next element
    inc rcx
    jmp sort_loop

sort_down:
    ; move down array
    dec rcx
    jmp sort_next

sort_up:
    ; move up array
    inc rcx
    jmp sort_next