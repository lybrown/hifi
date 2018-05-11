    icl 'hardware.asm'
    org $2000
code
    org r:$2000
lo
    ert <*!=0
    :256 dta $A0|[#&$F]
hi
    ert <*!=0
    :256 dta $10|[#>>4]
banks
    :256 dta [[#&3]<<2]|[[[~#]&4]>>1]|[[[#^$18]&$38]<<2]|1
bankindex
    dta 0
main
    ; disable interrupts, ANTIC, POKEY
    sei
    mva #0 NMIEN
    sta DMACTL
    sta AUDCTL

    ; disable OS
    mva #$FE PORTB

    ; graphics
    mva #$F COLPM0
    mva #$FF GRAFP0

    ; init POKEY
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
    lda #0
    ldx #7
    sta:rpl AUDF1,x-

    ; init bank
    mwa #0 bankindex

dummyz equ 0
    mwa #0 dummyz

laststart equ $82
    sta laststart

    jsr setpulse

    ldy #0
play
    ; pages 0-61
>>> for $page (0 .. 61) {
    ldx $4000+<<<$page>>>*$100,y ; 4 cycles
    mva hi,x AUDC3 ; 8 cycles
    mva lo,x AUDC1 ; 8 cycles
    ;mva lo,x $F000 ; 8 cycles
    ; 20 cycles
    ; Pad to 37 cycles by adding 17 cycles of nop:
    stx HPOSP0 ; 4 cycles
    and (dummyz,x) ; 6 cycles NOP
    and (dummyz),y ; 5 cycles NOP
    nop ; 2 cycles NOP
>>> }
    ; page 62
    ldx $4000+62*$100,y ; 4 cycles
    mva hi,x AUDC3 ; 8 cycles
    mva lo,x AUDC1 ; 8 cycles
    ;mva lo,x $F000 ; 8 cycles
    ; 20 cycles
    ; Pad to 37 cycles by adding 17 cycles of nop:
    lda CONSOL ; 4 cycles
    and #1 ; 2 cycles
    cmp:sta laststart ; 5 cycles
    bcc toggle ; 2 cycles
    lda $FF00,x ; 4 cycles NOP
    ; page 63
page63
    ldx $4000+63*$100,y ; 4 cycles
    mva hi,x AUDC3 ; 8 cycles
    mva lo,x AUDC1 ; 8 cycles
    ;mva lo,x $F000 ; 8 cycles
    :2 and (dummyz),y ; 5+5 cycles NOP
    iny ; 2 cycles
branch
    beq next ; 2 cycles +1 if taken same page
    jmp play ; 3 cycles
next
    ; ert [>next]!=[>branch]

    ; Go to next RAM bank
setbank
    mva banks PORTB ; 8 cycles
    inc setbank+1 ; 6 cycles
    jmp play ; 3 cycles
codeend

toggle
    jsr setpulse
    jmp page63

setpulse
    ; Set up 1/16 dutycycle HiPass on 1+3
    ldx pindex
    mva paudf3,x AUDF3
    mva paudf1,x AUDF1
    sta STIMER
    sta AUDF3
    lda #1
    eor:sta pindex
    beq altirra
    mva #$0 COLBK
    mva #$F COLPM0
    rts
altirra
    mva #$F COLBK
    mva #$0 COLPM0
    rts
pindex
    dta 0
paudf1
    dta 12,3
paudf3
    dta 13,5


start
    ; disable interrupts, ANTIC, POKEY
    sei
    mva #0 NMIEN
    sta DMACTL
    sta AUDCTL
    mwa #dlist DLISTL
    mva #0 COLPF2
    mva #15 COLPF1
    lda:rne VCOUNT
    mva #$22 DMACTL

wait
    lda SKSTAT
    and #4
    beq continue
    lda TRIG0
    beq continue
    lda CONSOL
    and #7
    cmp #7
    bne continue
    jmp wait

continue

    jmp main
null
    rts

dlist
    :4 dta $70
    dta $42,a(scr)
    :6 dta $2
    dta $70
    :4 dta $2
    dta $70
    :4 dta $2
    dta $70
    :1 dta $2
    dta $41,a(dlist)
scr
    ;     0123456789012345678901234567890123456789
    dta d'  This is a demo of playing samples at  '
    dta d'    44270Hz with 8-bits of precision.   '
    dta d' Channel 3 plays the top 4-bits as PCM. '
    dta d'   Channel 1+3 are running at 1.78Mhz   '
    dta d' and use HiPass to produce a 1/16 pulse '
    dta d'   at 111Khz. The bottom 4-bits are     '
    dta d'       applied to this signal.          '

    dta d'         Idea: kool kitty89             '
    dta d'             Code: Xuel                 '
    dta d'    Music: elektric_funk.mod - Moby     '
    dta d'                                        '

    dta d'          AtariAge Thread:              '
    dta d'   http://atariage.com/forums/topic/    '
    dta d'      244946-using-pulse-density-       '
    dta d'       modulation-for-8-bit-pcm/        '

    dta d'           Press any key                '

    org $3000
nextbank
    ldx bankindex
    mva banks,x PORTB
    inx
    stx bankindex
    rts

    run start
