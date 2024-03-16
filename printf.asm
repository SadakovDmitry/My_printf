global my_printf

section     .text

global _my_printf

;----------------------------------------------------------------------------
;Call my_printf
;============================================================================
_my_printf:
        pop r11                 ; r11 = ret adress

        push r9                 ;--------------------------------------------
        push r8                 ;>
        push rcx                ;>>>   Push arguments
        push rdx                ;>>
        push rsi                ;--------------------------------------------
        push rbp                ;--------------------------------------------
        push r15                ;>
        push r12                ;>>   Save r11, r12, r15, rbp
        push r11                ;--------------------------------------------

        mov rbp, rsp
        add rbp, 32              ; skip rbp, r

        mov rax, rdi            ; rax = pointer to format str
        call _read_args

        push r11                ;--------------------------------------------
        push r12                ;>
        push r15                ;>>   Recover r11, r12, r15, rbp
        push rbp                ;--------------------------------------------
        add rsp, 40             ; skip r9, r8, rcx, rdx, rsi

        jmp r11                 ; ret
;============================================================================


;----------------------------------------------------------------------------
;Print Arguments
;IN: RAX = pointer to start format string
;DAMAGED: NONE
;============================================================================
_read_args:
        push rbx
        xor rbx, rbx            ;zero arg

Next_symbol:
        cmp [rax], byte 0
        je Stop
        cmp byte [rax], '%'
        je _print_spesificator
        jmp _print_standart_char

Stop:
        pop rbx
        ret
;============================================================================


;----------------------------------------------------------------------------
;Jmp to func in jump table
;IN: RAX = pointer to char symbol after '%'
;DAMAGED = R15, RAX
;============================================================================
_print_spesificator:
        inc rax                     ; skip '%'
        xor r15, r15
        mov byte r15b, [rax]        ; r15b = [rax]
        cmp r15b, '%'               ; if rax = '%'
        je _print_standart_char     ; print '%'

        push rax                    ; save rax
        mov rax, [rbp + rbx * 8]    ; rax = new argument
        inc rbx                     ; next argument

        lea rdx, [(r15 - 'b') * 8]  ;----------------------------------------
        mov r15, jump_table         ;>
        add rdx, r15                ;>>   jmp to correct functin in jmp_table
        call [rdx]                  ;----------------------------------------

        pop rax                     ; reload rax
        inc rax                     ; next symbol

        jmp Next_symbol
;============================================================================


;----------------------------------------------------------------------------
;Print standart char
;DAMEGED: RAX
;IN: RAX = pointer to char symbol
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
;DAMEGED: NONE
;IN: RAX = registrs
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
        push rbx
        push rcx
        push rdx

        xor rcx, rcx
        xor rbx, rbx
        mov r11, simbols
        mov rbx, end_buf

        mov rdx, rax
        and rdx, 1 << 31  ;0x80000000
        je while_not_zero

        neg eax
        push rax
        mov rax, '-'
        call _print_symbol
        pop rax

while_not_zero:
        xor rdx, rdx
        div r10
        add rdx, r11
        dec rbx                 ;rdx--
        mov r12b, [rdx]
        mov [rbx], r12b         ;set simbol in buf
        inc rcx                 ;

        cmp rax, 0
        jne while_not_zero

        mov rax, 0x2000004      ; write64bsd (rdi, rsi, rdx) ... r10, r8, r9
        mov rdi, 1              ; stdout
        mov rsi, rbx
        mov rdx, rcx            ; strlen
        syscall                 ; print number


        pop rdx
        pop rcx
        pop rbx
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
_print_oct_num:
        mov r10, 8
        call _print_num
        ret
;============================================================================



;----------------------------------------------------------------------------
;Print %x
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = number
;============================================================================
_print_hex_num:
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
        ret
;============================================================================


section     .rodata

simbols     db '0123456789ABCDEF'
start_buf   db 0
value_buf   db 100 dup('0')
end_buf     db 0
negg        db '-'
output_str  db 500 dup('0')

jump_table  dq _print_binary_num
            dq _print_char
            dq _print_dec_num
            dq 'o' - 'd' - 1 dup(_print_standart_char)
            dq _print_oct_num
            dq 's' - 'o' - 1 dup(_print_standart_char)
            dq _print_str
            dq 'x' - 's' - 1 dup(_print_standart_char)
            dq _print_hex_num
