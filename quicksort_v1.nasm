section .text
global _start

_start:


    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push [count] ; high (arg2)    *** length of (array - 1) here
    push 0           ; low (arg1)
    push arr_ptr     ; pointer to array (arg0)
    call _quickSort
    add rsp, 0x18   ; clear arg entry from stack
    pop rbx
    pop rcx
    pop rdx


_quickSort:


    ; callee prologue
    push rbp
    mov rbp, rsp
    sub rsp, 0x08 ; allocate place for 1 local variable
    push rsi
    push rdi
    push r8

    ; if low >= high, end function
    cmp [rbp + 0x18], [rbp + 0x20]
    jae .end

    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push [rbp + 0x20] ; high (arg2)
    push [rbp + 0x18] ; low (arg1)
    push [rbp + 0x10] ; pointer to array (arg0)
    call _partition
    add rsp, 0x18   ; clear arg entry from stack
    mov qword [rbp - 0x08], rax ; store to local variable, the pivot location returned
    pop rbx
    pop rcx
    pop rdx

    ; load pivot + 1
    xor r8, r8
    mov r8, [rbp - 0x08]
    inc r8

    ; recursive call to self to sort all partition after pivot
    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push [rbp + 0x20] ; high (arg2)
    push r8           ; pivot + 1 (arg1)
    push [rbp + 0x10] ; pointer to array (arg0)
    call _quickSort
    add rsp, 0x18   ; clear arg entry from stack
    pop rbx
    pop rcx
    pop rdx

    ; load pivot - 1
    xor r8, r8
    mov r8, [rbp - 0x08]
    dec r8

    ; recursive call to self to sort all partition before pivot
    ; Caller C calling convention
    push rdx
    push rcx
    push rbx
    push r8           ; high (arg2)
    push [rbp + 0x18] ; pivot - 1 (arg1)
    push [rbp + 0x10] ; pointer to array (arg0)
    call _quickSort
    add rsp, 0x18   ; clear arg entry from stack
    pop rbx
    pop rcx
    pop rdx


    .end:
        ; callee epilogue
        pop r8
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
    push r8
    push r9
    push r10


    ; initialize local variables
    mov rbx, [rbp + 0x20]
    mov qword [rbp - 0x10], rbx ; move high to j counter variable
    inc rbx
    mov qword [rbp - 0x08], rbx ; move high + 1 to i counter variable


    xor rbx, rbx
    xor rcx, rcx
    ; pivot is at first element of range of the partition set
    ; pivot value is stored in rbx
    lea rbx, [rbp + 0x10]
    mov rcx, [rbp + 0x18]
    lea rbx, [rbx + rcx * 4]

    xor r8, r8
    ; load low + 1 to r8 as loop end condition 
    mov r8, [rbp + 0x18]
    inc r8

    .loop:

        ; if j < low + 1, end loop
        cmp [rbp - 0x10], r8
        jb .loop_end

        xor r10, r10
        xor rcx, rcx
        ; load address of array element indexed with j (arg1)
        lea r10, [rbp + 0x10]
        mov rcx, [rbp - 0x10]
        lea r10, [r10 + rcx * 4]

        ; if arr[j] > pivot, do sorting operation
        cmp [r10], [rbx]
        jae .sorting

        ; else decrement to counter j and repeat loop
        dec [rbp - 0x10] 
        jmp .loop

        .sorting:
            dec [rbp - 0x08] ; decrement index i counter

            xor r9, r9
            xor rcx, rcx
            ; load address of array element indexed with i (arg0)
            lea r9, [rbp + 0x10]
            mov rcx, [rbp - 0x08]
            lea r9, [r9 + rcx * 4]


            ; Caller C calling convention
            push rdx
            push rcx
            push rbx
            push r10      ; array element address indexed with j (arg1)
            push r9       ; array element address indexed with i (arg0)
            call _swap
            add rsp, 0x10   ; clear arg entry from stack
            pop rbx
            pop rcx
            pop rdx

            ; decrement to counter j and repeat loop
            dec [rbp - 0x10] 
            jmp .loop

    .loop_end:
        dec [rbp - 0x08] ; i - 1

        xor r9, r9
        xor rcx, rcx
        ; load address of array element indexed with i - 1 (arg0)
        lea r9, [rbp + 0x10]
        mov rcx, [rbp - 0x08]
        lea r9, [r9 + rcx * 4]

        xor r10, r10
        ; load address of array element of pivot (arg1)
        lea r10, [rbx]

        ; Caller C calling convention
        push rdx
        push rcx
        push rbx
        push r10      ; array element address of pivot (arg1)
        push r9       ; array element address indexed with i - 1 (arg0)
        call _swap
        add rsp, 0x10   ; clear arg entry from stack
        pop rbx
        pop rcx
        pop rdx

        xor rax, rax
        mov rax, [rbp - 0x08] ;return i - 1


    ; callee epilogue
    pop r10
    pop r9
    pop r8
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

    xor rbx, rbx
    xor rcx, rcx
    lea rbx, [rbp + 0x10] ; address 1
    mov rcx, [rbx] ; content of address 1 is stored here

    xor rdx, rdx
    lea rdx, [rbp + 0x18] ; address 2

    mov [rbx], [rdx] ; address 1 content <- address 2 content
    mov [rdx], rcx ; address 2 content <- address 1 content

    ; callee epilogue
    pop rdi
    pop rsi
    mov rsp, rbp ; deallocate local variable
    pop rbp     
    ret
