;format macho64

;extrn printf
global my_printf

section     .text

;section printf executable
global _my_printf
;----------------------------------------------------------------------------
;Call my_printf
;============================================================================
_my_printf:
        pop r10

        push r9
        push r8
        push rcx
        push rdx
        push rsi

        mov rax, rdi
        call _read_args

        pop rsi
        pop rdx
        pop rcx
        pop r8
        pop r9

        push r10
        ret
;============================================================================


_read_args:
        push rbx
        push rcx

        mov rbx, 32
        xor rcx, rcx

Next_simbol:
        cmp [rax], byte 0
        je exit
        cmp byte [rax], '%'
        je spesificator
        jmp _print_standart_char

spesificator:
        inc rax
        xor r15, r15
        mov byte r15b, [rax]
        cmp r15b, '%'
        je _print_standart_char

        lea rdx, [(r15 - 'b') * 8]  ;choose func in jump table
        mov r15, jump_table
        add rdx, r15
        jmp [rdx]

        inc rcx         ;shift stack
        add rbx, 8
        inc rax         ;next simbol
        jmp Next_simbol


;----------------------------------------------------------------------------
;Print standart char
;DAMEGED: AX
;============================================================================
_print_standart_char:
        push rax
        mov rax, [rax]
        call _print_simbol
        pop rax
        inc rax
        jmp Next_simbol
;============================================================================

;----------------------------------------------------------------------------
;Print %c
;DAMEGED: AX
;============================================================================
_print_char:
        push rax
        mov rax, [rsp + rbx]
        call _print_simbol
        pop rax
        inc rax

        inc rcx         ;shift stack
        add rbx, 8
        jmp Next_simbol
;============================================================================

_print_binary_num:
_print_dec_num:
_print_oct_dec:
_print_str:
_print_hex_dec:

_print_simbol:
        push rax
        push rdx
        push rsi
        push rdi

        push rax

        mov rax, 0x2000004 ; write64bsd (rdi, rsi, rdx) ... r10, r8, r9
        mov rdi, 1         ; stdout
        mov rsi, rsp
        mov rdx, 1         ; strlen
        syscall

        pop rax

        pop rdi
        pop rsi
        pop rdx
        pop rax
        ret

exit:
        pop rcx
        pop rbx
        mov rax, 0x2000001
        xor rdi, rdi
        syscall




section     .data

jump_table  dq _print_binary_num
            dq _print_char
            dq _print_dec_num
            dq 'o' - 'd' - 1 dup(_print_standart_char)
            dq _print_oct_dec
            dq 's' - 'o' - 1 dup(_print_standart_char)
            dq _print_str
            dq 'x' - 's' - 1 dup(_print_standart_char)
            dq _print_hex_dec
