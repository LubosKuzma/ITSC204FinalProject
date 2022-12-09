section .data
    arr: db 1, 4, 3, 5, 2, 7, 6, 8, 9
    arr_len: equ $ - arr

section .text
    global _start

_start:

    mov rdx, arr_len
    mov rcx, arr
    mov rax, 0x1
    mov rdi, 0x1
    syscall 
    jmp _exit
    ; 1. how to print an array. 
    ; 2. how to go through the arr after gnome sort and convert to ascii. Then print the sorted data.

ascii_bias_convert:                               
    cmp al, 0x39                   
    jge skip                        ; If == 0x39 or > then jump to skip
    sub al, 0x30                    ; If != then subtract 0x39 from it
    ret                             
    skip:
    sub al, 0x7                     ; If byte is == or > 0x39, then subtract 0x7 from it
                                    ; this is to get hex values 3a-3f
    sub al, 0x30                    ; substract 0x30 to get correct value
    ret


gnomeSort:
    ; n is number of elements in array
    ; arr is pointer to array
    ; index is used to track current index

    ; saving the registers
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov rbp, rsp                            ; set up rbp as frame pointer
    mov rbx, 0                              ; set up rbx as index 

        .sortingLoop:                       ; loop until index == n
            cmp rbx, [rdi]
            je .sortingLoopEnd
            cmp rbx, 0                      ; check if index == 0
            je .checkIndexZero
            mov r12, [rsi + rbx * 8]        ; get arr[index]
            mov r13, [rsi + (rbx - 1) * 8]  ; get arr[index - 1]
            cmp r12, r13                    ; compare arr[index] and arr[index - 1]
            jl .swapElements
            inc rbx                         ; increment index
            jmp .sortingLoop

        .checkIndexZero:
            mov r12, [rsi + rbx * 8]        ; get arr[index]
            mov r13, [rsi + (rbx - 1) * 8]  ; get arr[index - 1]
            cmp r12, r13                    ; compare arr[index] and arr[index - 1]
            jl .swapElements
            inc rbx                         ; increment index
            jmp .sortingLoop

        .swapElements:
            mov r14, r12                    ; save arr[index] in r14
            mov r15, r13                    ; save arr[index - 1] in r15
            mov [rsi + rbx * 8], r15        ; swap elements
            mov [rsi + (rbx - 1) * 8], r14
            dec rbx                         ; decrement index
            jmp .sortingLoop                ; jump to loop

        .sortingLoopEnd:                    ; restore registers
            pop r15
            pop r14
            pop r13
            pop r12
            pop rbx
            pop rbp
            ret

_exit:
    mov rax, 0x3C       ; sys_exit
    mov rdi, 0x00       ; return code  
    syscall
    ret
