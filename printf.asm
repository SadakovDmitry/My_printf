global my_printf

section     .text

global _my_printf

;----------------------------------------------------------------------------
;Call my_printf
;============================================================================
_my_printf:
        pop r10

        push r9                 ;--------------------------------------------
        push r8                 ;>
        push rcx                ;>>>   Save r9, r8, rcx, rdx, rbp
        push rdx                ;>>
        push rsi                ;>
        push rbp                ;--------------------------------------------

        mov rbp, rsp
        add rbp, 8             ; +rbp, +r10

        mov rax, rdi
        call _read_args

        pop rbp                 ;--------------------------------------------
        pop rsi                 ;>
        pop rdx                 ;>>
        pop rcx                 ;>>>  Recover r9, r8, rcx, rdx, rbp
        pop r8                  ;>
        pop r9                  ;--------------------------------------------

        push r10
        ret
;============================================================================


_read_args:
        push rbx
        push rcx

        ;mov rbx, 40
        xor rbx, rbx
        xor rcx, rcx

Next_symbol:
        cmp [rax], byte 0
        je exit
        cmp byte [rax], '%'
        je spesificator
        jmp _print_standart_char


;----------------------------------------------------------------------------
;Jmp to func in jump table
;IN: RAX = pointer to char symbol after '%'
;DAMAGED = R15
;============================================================================
spesificator:
        inc rax                     ;skip '%'
        xor r15, r15
        mov byte r15b, [rax]        ; r15b = [rax]
        cmp r15b, '%'               ; if rax = '%'
        je _print_standart_char     ; print '%'

        push rax
        mov rax, [rbp + rbx * 8]    ; rax = new argument
        inc rbx                     ; next argument

        lea rdx, [(r15 - 'b') * 8]  ;----------------------------------------
        mov r15, jump_table         ;>
        add rdx, r15                ;>>   jmp to correct functin in jmp_table
        call [rdx]                  ;----------------------------------------

        pop rax
        inc rax                     ;next symbol

        jmp Next_symbol
;============================================================================


;----------------------------------------------------------------------------
;Print standart char
;DAMEGED: RAX = pointer to char symbol
;============================================================================
_print_standart_char:
        push rax
        mov rax, [rax]
        call _print_symbol
        pop rax
        inc rax
        jmp Next_symbol
;============================================================================

;----------------------------------------------------------------------------
;Print %c
;DAMEGED: RAX = arg
;============================================================================
_print_char:
        call _print_symbol
        ret
;============================================================================

;----------------------------------------------------------------------------
;Print %s
;DAMEGED: RAX, RDX
;============================================================================
_print_str:
        mov rdx, rax

Next_symbol_in_str:
        cmp [rdx], byte 0
        je end_str
        mov rax, [rdx]
        call _print_symbol
        inc rdx
        jmp Next_symbol_in_str
        end_str:

        ret
;============================================================================


;----------------------------------------------------------------------------
;Print num
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = number
;       R10 = sistem count
;============================================================================
_print_num:
        push rax
        push rbx
        push rcx
        push rdx

        xor rcx, rcx
        xor rbx, rbx
        mov r11, simbols
        mov rbx, end_buf
        cmp rax, 2147483647
        jb without_minus

        neg eax
        push rax
        mov rax, '-'
        call _print_symbol
        pop rax

without_minus:

while_not_zero:
        xor rdx, rdx
        div r10
        add rdx, r11
        dec rbx
        mov byte r12b, [rdx]
        mov byte [rbx], r12b
        inc rcx

        cmp rax, 0
        jne while_not_zero

        mov rax, 0x2000004 ; write64bsd (rdi, rsi, rdx) ... r10, r8, r9
        mov rdi, 1         ; stdout
        mov rsi, rbx
        mov rdx, rcx       ; strlen
        syscall            ; print number


        pop rdx
        pop rcx
        pop rbx
        pop rax
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print %b
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = argument
;============================================================================
_print_binary_num:
        mov r10, 2
        call _print_num
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print %o
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = number
;============================================================================
_print_oct_dec:
        mov r10, 8
        call _print_num
        ret
;============================================================================



;----------------------------------------------------------------------------
;Print %x
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = number
;============================================================================
_print_hex_dec:
        mov r10, 16
        call _print_num
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print %d
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = number
;============================================================================
_print_dec_num:
        mov r10, 10
        call _print_num
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print symbol
;DAMEGED: None
;IN:    RAX = ASCII code symbol
;============================================================================
_print_symbol:
        push rax
        push rdx
        push rsi
        push rdi

        push rax

        mov rax, 0x2000004 ; write64bsd (rdi, rsi, rdx) ... r10, r8, r9
        mov rdi, 1         ; stdout
        mov rsi, rsp
        mov rdx, 1         ; strlen

        push rcx
        push r11
        syscall
        pop r11
        pop rcx

        pop rax

        pop rdi
        pop rsi
        pop rdx
        pop rax
        ret
;============================================================================

;----------------------------------------------------------------------------
;EXIT
;============================================================================
exit:
        pop rcx
        pop rbx
        mov rax, 0x2000001
        xor rdi, rdi
        syscall
;============================================================================



section     .data

simbols     db '0123456789ABCDEF'
value_buf   db 100 dup('0')
end_buf     db 0
negg        db '-'

jump_table  dq _print_binary_num
            dq _print_char
            dq _print_dec_num
            dq 'o' - 'd' - 1 dup(_print_standart_char)
            dq _print_oct_dec
            dq 's' - 'o' - 1 dup(_print_standart_char)
            dq _print_str
            dq 'x' - 's' - 1 dup(_print_standart_char)
            dq _print_hex_dec
