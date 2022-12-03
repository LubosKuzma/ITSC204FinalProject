;v1.01
section .text
globle _start
_start:
    _file:                              ;file function
        
        .create:
            mov rax, 0x55               ;create call
            mov rdi, Nfilename          ;file name
            mov rsi, 511                ;give all premission
            syscall
            push rax                    ;save file descriptor in stack
            cmp rax                     ;if rax = 0, the file create successful            
            jz _file.create_notice
            jmp _file.create_failed

        .create_failed:
            mov rax, 0x1
            mov rdi, 0
            mov rsi, file_error_S
            mov rdx, file_error_L
            jmp _file.create

        .create_notice:
            mov rax, 0x1                ;write call
            mov rdi, 0                  
            mov rsi, file_haved_S       ;print(This file has created)
            mov rdx, file_haved_L
            syscall

        
        .nosort_notice: 
            pop rdi
            mov rax, 0x1                ;write syscall
            mov rdi, rdi                ;file descriptor
            mov rsi, nosort_notice_S    ;print(This is beginning of the no sort data)
            mov rdx, nosort_notice_L
            syscall
            
        .write.nosort:
            mov rdx,                    ;our number of bytes to write
            mov rcx,                    ;our receive byte (No ranked) pointer
            mov rdi, rdi                 ;our file descriptor
            mov rax, 0x1                ;write syscall
            syscall

        .sort_notice:                   
            mov rax, 0x1                ;write syscall
            mov rdi, rdi                  ;file descriptor
            mov rsi, sort_notice_S      ;print(This is beginning of the sort data)
            mov rdx, sort_notice_L
            syscall

        .write_sort:
            mov rdx,                    ;our number of bytes to write
            mov rcx,                    ;our receive byte (ranked) pointer
            mov rdi, rdi                 ;file descriptor
            mov rax, 0x1                ;write syscall
            syscall
        
        .close:
            mov rax, 0x3
            mov rdi, 1
            syscall

        

section .data:
    Nfilename: db "No_rank_file", 0x0
    file_haved_S: db "This file has created", 0xA, 0x0
    file_haved_L: equ $ - file_haved_S
    nosort_notice_S: db "This is beginning of No sort data:", 0xA, 0x0
    nosort_notice_L: equ $ - nosort_notice_S
    sort_notice_S: db "This is beginning of No sort data:", 0xA, 0x0
    sort_notice_L: equ $ - sort_notice_S
    file_error_S:  db "This file already exist, Please try again", 0xA, 0x0
    file_error_L: equ $ - file_error_S
