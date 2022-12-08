; Vincent Lo
; 2022-11-24
; This is unfinished code

;step one. See if you can print all numbers in the array.
    ; load the register with the array data
    ; interate through the array, convert each element of the array to ascii and print.

section .data
    array: db 1, 4, 3, 5, 2, 7, 6, 8, 9
    array_len: equ $ - array

section .text
    global _start

_start:

; iterate through the array and convert each element of the array to ascii.
;interation:
    ;mov rsi, [array]
    ;mov al, [rsi]
    ;call ascii_bias_convert
    ;inc rsi
    

; function for ascii bias
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

; function to print
write:
    mov rax, 0x1
    mov rdi, 0x1
    syscall
    ret

; exit function
_exit:
    mov rax, 0x3C
    mov rdi, 0x00
    syscall

section .bss
