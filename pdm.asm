    icl 'hardware.asm'

    org $600
lo
    ert <*!=0
    :256 dta $A0|[#&$F]
hi
    ert <*!=0
    :256 dta $10|[#>>4]

main
    sei
    mva #0 NMIEN
    sta DMACTL
    mva #$FE PORTB
    sta AUDCTL
    mva #3 SKCTL
    ; 1.79Mhz for channel 1
FAST1 equ 1<<6
    ; 1.79Mhz for channel 3
FAST3 equ 1<<5
    ; HiPass 1+3
HI13 equ 1<<2
    ; 15Khz
KHZ15 equ 1<<0
    mva #[FAST1|FAST3|HI13] AUDCTL
    ;mva #[HI13|KHZ15] AUDCTL
    mva #$AF AUDC1
    mva #$10 AUDC2
    mva #$A0 AUDC3
    mva #$10 AUDC4
    mva #$F COLPM0
    mva #$1 GRAFP0
    mvx #12 AUDF1
    mva #13 AUDF3
    sta STIMER
    stx AUDF3

play
    ldx waveform ; 4 cycles
    lda hi,x ; 4 cycles
    ldy lo,x ; 4 cycles
    sta AUDC2 ; 4 cycles
    sty AUDC1 ; 4 cycles
    ;sty $FF00 ; 4 cycles
    inc play+1 ; 6 cycles
branch
    bne nohi ; 2 cycles +1 if taken to same page
    inc play+2 ; 6 cycles
    jmp play ; 3 cycles
    ; total = 37 cycles
    ; 105 available per scanline
nohi
    ert [>branch]!=[>*]
    bit 0 ; 3 cycles
    nop ; 2 cycles
    jmp play ; 3 cycles
dummy
    dta 0

waveform
    ins 'waveform.bin'

    run main
