
section     .text

global _my_printf

;rsi = pointer to buffer
;nasm -f macho64 printf.asm -o printf.o
;gcc printf.o main.c -o app -Wl,-no_pie -g

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
        push r11                ;-------------------------------------------- callee caller safe saved

        mov rbp, rsp
        add rbp, 32              ; skip rbp, r

        xor rsi, rsi
        mov rax, rdi            ; rax = pointer to format str
        xor rdi, rdi
        call _read_args
        call _print_buf

        pop r11                ;--------------------------------------------
        pop r12                ;>
        pop r15                ;>>   Recover r11, r12, r15, rbp
        pop rbp                ;--------------------------------------------
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
        je _print_spesificator ; specifier
        call _print_standart_char ; standard std::
        jmp Next_symbol

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
        jne not_percent             ; print '%'
        call _print_standart_char
        jmp Next_symbol
not_percent:

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
        ret
        ;jmp Next_symbol
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
;Print %d
;DAMEGED: RAX, R12, R11
;IN:    RAX = number
;============================================================================
_print_dec_num:
        push rbx
        push rcx
        push rdx

        xor rcx, rcx
        xor rbx, rbx
        mov r10, 10
        mov r11, symbols
        mov rbx, end_buf

        mov eax, eax
        mov rdx, rax
        and rdx, sign_bit       ;0x80000000 ;1 << 31
        je while_not_zero_2

        neg eax
        push rax
        mov rax, '-'
        call _print_symbol
        pop rax

while_not_zero_2:
        xor rdx, rdx
        div r10
        add rdx, r11            ;rdx = num simbol
        dec rbx                 ;rdx--
        mov r12b, [rdx]
        mov [rbx], r12b         ;set symbol in buf
        inc rcx                 ;

        cmp rax, 0
        jne while_not_zero_2

Next_num_2:                       ;-------------------------------------------
        mov rax, [rbx]          ;>
        call _print_symbol      ;>> Print number to output_buf
        inc rbx                 ;>
        loop Next_num_2           ;-------------------------------------------



        pop rdx
        pop rcx
        pop rbx
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print %x %o %b
;DAMEGED: RAX, R10
;IN:    RAX = number
;       CL = shift count
;       R9  = mask
;============================================================================
_print_not_dec_num:
        push rbx
        push rcx
        push rdx
        push r9

        xor r10, r10
        xor rbx, rbx
        mov r11, symbols
        mov rbx, end_buf

while_not_zero:
        xor rdx, rdx
        mov rdx, rax            ;rdx = rax
        shr rax, cl             ;shift number to cl
        and rdx, r9             ;reset to zero high bits
        add rdx, r11            ;rdx = num simbol
        dec rbx                 ;rbx--
        mov r12b, [rdx]
        mov [rbx], r12b         ;set symbol in buf
        inc r10                 ;

        cmp rax, 0
        jne while_not_zero

        mov rcx, r10

Next_num:                       ;-------------------------------------------
        mov rax, [rbx]          ;>
        call _print_symbol      ;>> Print number to output_buf
        inc rbx                 ;>
        loop Next_num           ;-------------------------------------------

        pop r9
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
        mov cl, 1
        mov r9, 1

        call _print_not_dec_num
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print %o
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = number
;============================================================================
_print_oct_num:

        mov cl, 3
        mov r9, 7

        call _print_not_dec_num
        ret
;============================================================================



;----------------------------------------------------------------------------
;Print %x
;DAMEGED: RAX, RDX, R12, R11
;IN:    RAX = number
;============================================================================
_print_hex_num:
        mov cl, 4
        mov r9, 15

        call _print_not_dec_num
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print symbol
;DAMEGED: None
;IN:    RAX = ASCII code symbol
;============================================================================
_print_symbol:
        push rdi

        cmp rsi, size_buf
        jne Not_clean
        call _clean_buf
Not_clean:

        mov rdi, output_buf
        add rdi, rsi
        inc rsi                 ;rsi++
        mov [rdi], rax          ;set simbol in buf

        pop rdi
        ret
;============================================================================


;----------------------------------------------------------------------------
;Print buf
;IN: NONE
;DAMAGED: NONE
;============================================================================
_print_buf:
        push rdx
        push rdi
        push rax
        push rsi

        mov rax, 0x2000004      ; write64bsd (rdi, rsi, rdx) ... r10, r8, r9
        mov rdi, 1              ; stdout
        mov rsi, output_buf
        mov rdx, [rsp]          ; strlen

        push rcx
        push r11
        syscall
        pop r11
        pop rcx

        pop rsi
        pop rax
        pop rdi
        pop rdx

        ret
;============================================================================


;----------------------------------------------------------------------------
;Clean buffer
;IN: RSI = size of buffer
;DAMAGED: RSI, RCX
;============================================================================
_clean_buf:
        push rax
        call _print_buf

        mov rcx, size_buf
        xor rsi, rsi
Next:                           ;-------------------------------------------
        mov rax, 0              ;>
        call _print_symbol      ;>> full buffer by '0'
        loop Next               ;-------------------------------------------
        pop rax
        ret
;============================================================================


section     .data

start_buf   db 0xb
value_buf   db 100 dup('0')
end_buf     db 0
output_buf  db 500 dup('0')

section     .rodata

symbols     db '0123456789ABCDEF'
negg        db '-'
size_buf    equ 500
sign_bit    equ 0x80000000

jump_table  dq _print_binary_num
            dq _print_char
            dq _print_dec_num
            dq 'o' - 'd' - 1 dup(_print_standart_char)
            dq _print_oct_num
            dq 's' - 'o' - 1 dup(_print_standart_char)
            dq _print_str
            dq 'x' - 's' - 1 dup(_print_standart_char)
            dq _print_hex_num
