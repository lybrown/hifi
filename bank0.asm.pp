    icl 'hardware.asm'
    opt f+h-
    ;========================================================
    org $A000
code
    org r:$2000
lo
    ert <*!=0
    :256 dta $A0|[#&$F]
hi
    ert <*!=0
    :256 dta $10|[#>>4]
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

    ; Set up 1/16 dutycycle HiPass on 1+3
    mvx #12 AUDF1
    mva #13 AUDF3
    sta STIMER
    stx AUDF3

    ; init bank
    mwa #1 $D5A0
    ldy #0

dummyz equ 0
    mwa #0 dummyz

play
    ; pages 0-30
>>> for $page (0 .. 30) {
    ldx $A000+<<<$page>>>*$100,y ; 4 cycles
    mva hi,x AUDC3 ; 8 cycles
    mva lo,x AUDC1 ; 8 cycles
    ;mva lo,x $F000 ; 8 cycles
    ; 20 cycles
    ; Pad to 37 cycles by adding 17 cycles of nop:
    stx HPOSP0 ; 4 cycles
    and (dummyz,x) ; 6 cycles NOP
    and (dummyz),y ; 5 cycles NOP
    nop
>>> }
    ; page 31
    ldx $A000+31*$100,y ; 4 cycles
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

    ; Go to next cart bank
    inc $D5A0 ; 6 cycles
    sne:inc $D5A1 ; 3-8 cycles
    jmp play ; 3 cycles
codeend

    ;========================================================
    org $B000
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

    ; copy code
    mwa #code $80
    mwa #$2000 $82
    ldx #[[codeend-code]>>8]+1
    ldy #0
copy
    mva:rne ($80),y ($82),y+
    inc $81
    inc $83
    dex
    bne copy

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
    dta d' Channel 2 plays the top 4-bits as PCM. '
    dta d'   Channel 1+3 are running at 1.78Mhz   '
    dta d' and use HiPass to produce a 1/16 pulse '
    dta d'   at 111Khz. The bottom 4-bits are     '
    dta d'       applied to this signal.          '

    dta d'         Idea: kool kitty89             '
    dta d'             Code: Xuel                 '
    dta d'         Music: DemoVibes 11            '
    dta d'   http://demovibes.org/demovibes-11/   '

    dta d'          AtariAge Thread:              '
    dta d'   http://atariage.com/forums/topic/    '
    dta d'      244946-using-pulse-density-       '
    dta d'       modulation-for-8-bit-pcm/        '

    dta d'           Press any key                '

    ;========================================================
    org $BFFA
    dta a(start) ; start
    dta 0 ; no left cart
    dta 4 ; no DOS
    dta a(null) ; init
