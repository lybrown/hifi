    icl 'hardware.asm'
    ;========================================================
    org $2000
sine
    dta sin(127,127,256,0,255)
sinelo
    dta sin(135,7,64,0,255)
triangle
    :256 dta #
trianglelo
    :256 dta 128+#&$F
lo
    ert <*!=0
    :256 dta $A0|[#&$F]
hi
    ert <*!=0
    :256 dta $10|[#>>4]

player
    ; disable interrupts, ANTIC, POKEY
    sei
    mva #0 NMIEN
    sta DMACTL
    sta AUDCTL

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
    mva #$AF AUDC1
    mva #$10 AUDC2
    mva #$A0 AUDC3
    mva #$10 AUDC4
    mva #0 AUDF2
    mva #0 AUDF4

    ; Set up 1/16 dutycycle HiPass on 1+3
    mvx optpulsex AUDF1
    mva optpulsey AUDF3
    sta STIMER
    stx AUDF3

    lda optenablelo
    ldx #{sta a:}
    and #1
    sne:ldx #{bit a:}
    stx stlo44
    stx stlo15

    lda optenablehi
    ldx #{sta a:}
    and #1
    sne:ldx #{bit a:}
    stx sthi44
    stx sthi15

    lda optwaveform
    add #$20
    sta play44+2
    sta play15+2

    lda optfreq
    and #1
    bne play44
    jmp play15

play44
    ldx sine,y ; 4 cycles
    lda hi,x ; 4 cycles
sthi44
    sta AUDC4 ; 4 cycles
    lda lo,x ; 4 cycles
stlo44
    sta AUDC1 ; 4 cycles
    ; 20 cycles
    ; Pad to 37 cycles
    nop ; 2 cycles
    stx HPOSP0 ; 4 cycles
    iny ; 2 cycles
    lda SKSTAT ; 4 cycles
    and #4 ; 2 cycles
branch44
    bne play44
    ; 2 cycles + 1 if taken same page
    ;ert [>branch44]!=[>play44]
    jmp menu

play15
    ldx sine,y ; 4 cycles
    lda hi,x
    sta WSYNC
sthi15
    sta AUDC4 ; 8 cycles
    lda lo,x
stlo15
    sta AUDC1 ; 8 cycles
    ; 20 cycles
    stx HPOSP0 ; 4 cycles
    iny ; 2 cycles
    lda SKSTAT ; 4 cycles
    and #4 ; 2 cycles
branch15
    bne play15 ; 2 cycles + 1 if taken same page
    jmp menu

menu
    ; disable interrupts, ANTIC, POKEY
    sei
    mva #0 NMIEN
    sta DMACTL
    sta AUDCTL
    sta HPOSP0
    :8 sta AUDC1
    mwa #dlist DLISTL
    mva #0 COLPF2
    mva #15 COLPF1
    lda:rne VCOUNT
    mva #$22 DMACTL

domenu
    ldx optwaveform
    mva wavetick+3,x scr+1
    mva wavetick+2,x scr+1+40
    mva wavetick+1,x scr+1+80
    mva wavetick+0,x scr+1+120
    lda optenablelo
    ldx #' '-32
    and #1
    seq:ldx #'*'-32
    stx scrlsb+1
    lda optenablehi
    ldx #' '-32
    and #1
    seq:ldx #'*'-32
    stx scrmsb+1
    lda optfreq
    ldx #'H'-32
    and #1
    sne:ldx #'L'-32
    stx scrfreq+1
    lda optpulsex
    and #$1F
    sta optpulsex
    lda optpulsey
    and #$1F
    sta optpulsey
    ldx optpulsex
    mva dig10,x scrpulsex+15
    mva dig0,x scrpulsex+16
    ldx optpulsey
    mva dig10,x scrpulsey+15
    mva dig0,x scrpulsey+16

readkeys
    lda SKSTAT
    and #4
    cmp:sta lastkeydown
    bcs nohit
    lda KBCODE
    cmp #31 ; '1'
    sne:mvx #0 optwaveform
    cmp #30 ; '2'
    sne:mvx #1 optwaveform
    cmp #26 ; '3'
    sne:mvx #2 optwaveform
    cmp #24 ; '4'
    sne:mvx #3 optwaveform
    cmp #29 ; '5'
    sne:inc optenablelo
    cmp #27 ; '6'
    sne:inc optenablehi
    cmp #51 ; '7'
    sne:inc optfreq
    cmp #53 ; '8'
    sne:inc optpulsex
    cmp #48 ; '9'
    sne:inc optpulsey

nohit

    lda CONSOL
    and #1
    bne nostart
    jmp player

nostart

    jmp domenu

    jsr player
null
    rts

lastkeydown
    dta 0
optfreq
    dta 1
optwaveform
    dta 0
optenablelo
    dta 1
optenablehi
    dta 1
optpulsex
    dta 12
optpulsey
    dta 13

dig10
    :32 dta 16+[#/10]
dig0
    :32 dta 16+[#%10]
wavetick
    dta d'   *   '

dlist
    :8 dta $70
    dta $42,a(scr)
    :9 dta $2
    dta $70
    :2 dta $2
    dta $41,a(dlist)
scr
    ;     0123456789012345678901234567890123456789
    dta d'   1. Sine Wave                         '
    dta d'   2. Sine Wave at 1/16 volume          '
    dta d'   3. Triangle Wave                     '
    dta d'   4. Triangle Wave at 1/16 volume      '
scrlsb
    dta d'   5. Toggle LSB                        '
scrmsb
    dta d'   6. Toggle MSB                        '
scrfreq
    dta d'   7. Toggle 44KHz/15KHz                '
scrpulsex
    dta d'   8. Pulse X:                          '
scrpulsey
    dta d'   9. Pulse Y:                          '
    dta d'   START. Play tone                     '

    dta d'   Press any key while tone is playing  '
    dta d'   to return to this menu               '

    run menu
