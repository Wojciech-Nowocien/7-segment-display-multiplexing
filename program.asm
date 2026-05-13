; Created by:   Wojciech "wojti" Nowocień

; Project:      Counting from 00 to 99 on Arduino Leonardo using display multiplexing
; License:      UNLICENSED

; I use double 7-segment display with common cathode and I assumed that segments are conected to appropiate Arduino PINs:
; A - 0
; B - 1
; C - 2
; D - 3
; E - 4
; F - 6
; G - 12
; first cathode  - A5 (PF0), called later "left"
; second cathode - A4 (PF1), called later "right"

; Why that PINs? Because I want to use only one PORT register (DDRD in this case) for easily screen cleaning.

; How to build it?
; avra program.asm

; Registers and it's purposes:
; r16 - (reserved) 0x00 for screen cleaning
; r17 - (reserved) argument, one number or one digit of the number
; r18 - (reserved) always stores 10 for comparasions (eg. >=, <)
; r19 - (reserved) first   (left)  digit of the number
; r20 - (reserved) second  (right) digit of the number
; r21 - (reserved) always stores 100 for comparasions (eg. >=, <)
; r22 - loops
; r23 - loops
; r24 - loops

; For improvements:
; If the register is reserved it's value cannot be changed in "random" place. Use stack to ensure that value won't change.
; If the register is not reserved it's value can be changed in "random" place. Also be careful about that.
; If you want to use loop register remember to don't modify them inside the loop!
; I didn't used registers that I don't mention.

.include "m32U4def.inc"
.cseg


; stack init
ldi r16, HIGH(RAMEND)
out SPH, r16
ldi r16, LOW(RAMEND)
out SPL, r16

; DDRD init
ldi r16, 223    ; not 255 because I don't want to use build-in TX LED (PD5)
out DDRD, r16
ldi r16, 0      ; for the clear function

; setup cathodes
sbi DDRF, 0
sbi DDRF, 1

; "turn off" cathodes
sbi PORTF, 0
sbi PORTF, 1

; init constants
ldi r18, 10
ldi r21, 100


start:
    ldi r17, 0

    counting:               ; do {
        call display_number
        inc r17             ; r17++
        cp r17, r21         ; r21 always stores 100
        breq start          ; if r17 == 100 goto start
        rjmp counting       ; } while(true);


; clears 7-segment screen (by setting anodes to 0V)
clear:
    out PORTD, r16          ; because r16 is zero
    ret

; turns on left and turns off right
left:
    cbi PORTF, 0
    sbi PORTF, 1
    ret

; turns on right and turns off left
right:
    cbi PORTF, 1
    sbi PORTF, 0
    ret


; r17 - number [0, 99]
display_number:
    call spilt_number
    ldi r22, 100
        d_n_inner:
            call display_digts
            dec r22
            brne d_n_inner
    ret

; r19 - number [0, 9] - left digit
; r20 - number [0, 9] - right digit
display_digts:
    push r17

    ; display left digit
    call left
    mov r17, r19
    call display_single_digit
    call wait_2_ms
    call clear

    ; display right digit
    call right
    mov r17, r20
    call display_single_digit
    call wait_2_ms
    call clear

    pop r17
    ret

; r17 - digit [0, 99], spilts into two digits
; returns:
;   r19 - first (left) digit    [0, 9]
;   r20 - second (right) digit  [0, 9]
spilt_number:
    ldi r19, 0

    cp r17, r21                 ; r21 always stores 100
    brsh display_overflow_case  ; r17 >= 100

    cp r17, r18                 ; r18 always stores 10
    brlo single_number_case     ; r17 < 10

    mov r20, r17
    division_loop:              ; do {
        inc r19                 ; r19++
        sub r20, r18            ; r20 -= 10
        cp r20, r18
        brlo end_of_division    ; break if r20 < 10
        rjmp division_loop      ; } while(true);

    end_of_division:
        ret

    single_number_case:
        ; r19 is already 0
        mov r20, r17
        ret

    display_overflow_case:      ; it shouldn't happen
        ; r19 is already 0
        ldi r20, 0
        ret


; r17 - digit [0, 9], displays a digit on every display by default
display_single_digit:
    cpi r17, 0
    breq case0

    cpi r17, 1
    breq case1

    cpi r17, 2
    breq case2

    cpi r17, 3
    breq case3

    cpi r17, 4
    breq case4

    cpi r17, 5
    breq case5

    cpi r17, 6
    breq case6

    cpi r17, 7
    breq case7

    cpi r17, 8
    breq case8

    cpi r17, 9
    breq case9
    ret

    case0:
        call zero
        ret
    case1:
        call one
        ret
    case2:
        call two
        ret
    case3:
        call three
        ret
    case4:
        call four
        ret
    case5:
        call five
        ret
    case6:
        call six
        ret
    case7:
        call seven
        ret
    case8:
        call eight
        ret
    case9:
        call nine
        ret



; numbers - turns on specific number:
zero:
    call antione
    call one
    call A
    call D
    ret

one:
    call B
    call C
    ret

; of course not a number - just a "line in front of the one" - used to print other existing numbers
antione:
    call F
    call E
    ret

two:
    call A
    call B
    call G
    call E
    call D
    ret

three:
    call one
    call A
    call G
    call D
    ret

four:
    call one
    call F
    call G
    ret

five:
    call A
    call F
    call G
    call C
    call D
    ret

six:
    call antione
    call G
    call C
    call D
    ret

seven:
    call one
    call A
    ret

eight:
    call zero
    call G
    ret

nine:
    call one
    call A
    call F
    call G
    call D
    ret


; segments - turns on specific segment:
A:
    sbi PORTD, 2
    ret

B:
    sbi PORTD, 3
    ret

C:
    sbi PORTD, 1
    ret

D:
    sbi PORTD, 0
    ret

E:
    sbi PORTD, 4
    ret

F:
    sbi PORTD, 7
    ret

G:
    sbi PORTD, 6
    ret



; waits 1 second
wait_1_s:
    push r16
    push r17
    push r18
    ldi r16, 42
    loop1:
        push r17
        ldi r17, 251
    loop2:
        ldi r18, 250
    loop3:
        dec r18
        brne loop3
        dec r17
        brne loop2
        pop r17
        dec r16
        brne loop1
        pop r18
        pop r17
        pop r16
        ret

; waits 2 ms
wait_2_ms:
    ldi r23, 32
    outer_loop:
        ldi r24, 250
        inner_loop:
            dec r24
            nop
            brne inner_loop
            dec r23
            brne outer_loop
            ret
