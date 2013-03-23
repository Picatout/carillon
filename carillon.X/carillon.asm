;NOM: carillon
;DESCRIPTION: carillon électronique. 
;MCU: PIC10F202
;DATE: 2013-03-21
;AUTEUR: Jacques Deschênes


    include p10f202.inc
    include "c:\microchip\include\base-macro.inc"


    __config _WDTE_OFF & _MCLRE_OFF

;;;;;;;;;; constantes ;;;;;;;;;;;;;;;;;;
OPTION_CFG EQU B'10000010' ; prescale TIMER0=1/8
TRIS_CFG EQU B'1001'

ATTACK EQU D'50'*D'125'  ; durée phase croissante
WHOLE   EQU D'1500'*D'125' ; durée note ronde


AUDIO_P EQU GP1 ; sortie audio
ENV_P EQU GP2   ; contrôle enveloppe
BTN_P EQU GP3

F_DECAY  EQU 0

;;;;;;;;; macros ;;;;;;;;;;;;;;;;;;;;;;;
#define AUDIO  GPIO, AUDIO_P
#define ENV    GPIO, ENV_P
#define BTN    GPIO, BTN_P





;;;;;;;;; variables ;;;;;;;;;;;;;;;;;;;;
    udata
flags res 1  ; indicateurs booléen
timeout res 3  ; compteur délais durée phase enveloppe.
half_delay res 1 ; compteur délais demi-période
half_period res 1 ; durée demi-période
ring_idx res 1 ; indice accès ring_table
duration res 3 ;
temp res 1

;;;;;;;;; code ;;;;;;;;;;;;;;;;;;;;;;;;;
rst_vector org 0
    goto init

tone_table ; délais demi-cycle  mulitple de 8 micro-secondes complément de 2.
    addwf PCL, F
    dt .17  ;0 C3 (do) 261,6 Hz
    dt .31  ;1 C#
    dt .43  ;2 D (ré)
    dt .55  ;3 D#
    dt .66  ;4 E  (mi)
    dt .77  ;5 F  (fa)
    dt .87  ;6 F#
    dt .97  ;7 G  (sol)
    dt .106 ;8 G#
    dt .114 ;9 A  (la)
    dt .122 ;10 A#
    dt .129 ;11 B  (si)
    dt .137 ;12 C4 (do)
    dt .143 ;13 C#
    dt .150 ;14 D  (ré)
    dt .156 ;15 D#
    dt .161 ;16 E  (mi)
    dt .167 ;17 F  (fa)
    dt .172 ;18 F#
    dt .176 ;19 G  (sol)
    dt .181 ;20 G#
    dt .185 ;21 A  (la)
    dt .189 ;22 A#
    dt .193 ;23 B5 (si) 987,8Hz

ring_table ; durée, note....
    addwf PCL, F
    dt .1, .12
    dt .1,.16
    dt .2, .14
    dt .2, .11
    dt .2, .12
    dt .2, .7
    dt .0, .0


;;;;;;;;;;;;; tone  ;;;;;;;;;;;;;
; entrées:
;  w = note :
;  dly1 = durée phase croissante
;  dly2 = durée phase décroissante
tone
;phase croissante
    call tone_table
    movwf half_period
    bcf flags, F_DECAY
    movlw  ATTACK & H'FF'
    movwf timeout
    movlw  (ATTACK>>8) & H'FF'
    movwf timeout+1
    movlw (ATTACK>>16) & H'FF'
    movwf timeout+2
    bsf ENV
    clrf TMR0
tone01
    movfw TMR0
    skpz
    goto $-2
    movfw half_period
    movwf TMR0
    movlw 1<<AUDIO_P
    xorwf GPIO, F  ; commute la sortie son
    movfw half_period
    addwf timeout, F
    skpc
    goto tone01
    movlw 1
    subwf timeout+1, F
    skpnc
    goto tone01
    subwf timeout+2, F
    skpnc
    goto tone01
    btfsc flags, F_DECAY
    return
    movfw duration
    movwf  timeout
    movfw duration+1
    movwf timeout+1
    movfw duration+2
    movwf timeout+2
    bsf flags, F_DECAY
    bcf ENV
    goto tone01




;;;;;;;;; initialisation MCU ;;;;;;;;;;;
init
    movlw D'12'
    movwf OSCCAL
    bcf OSCCAL, 0
    movlw OPTION_CFG
    option
    movlw TRIS_CFG
    tris GPIO

;;;;;;;;; procédure principale ;;;;;;;;;
main
    btfsc BTN
    goto $-1
    clrf ring_idx
ring_loop
    movlw WHOLE & H'FF'
    movwf duration
    movlw (WHOLE>>8) & H'FF'
    movwf duration+1
    movlw (WHOLE>>D'16') & H'FF'
    movwf duration+2
    movfw ring_idx
    call ring_table ; durée
    movwf temp
    movf  temp, F
    skpnz
    goto get_note
divide_duration
    clrc
    rrf duration+2, F
    rrf duration+1,F
    rrf duration,F
    decfsz temp, F
    goto divide_duration
get_note
    incf ring_idx, F
    movfw ring_idx
    call ring_table
    xorlw 0
    skpnz
    goto ring_end
    call tone
    incf ring_idx, F
    goto ring_loop
ring_end
    btfss BTN
    goto ring_end
    goto main

    end




