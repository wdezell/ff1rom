;; -------------------------------------------------------------
;; MISC DEBUG TOOLS
;; -------------------------------------------------------------

        ;; OUTPUT ACCUMULATOR AND ADDRESS *FOLLOWING* CALLING RST 08H
        ;;  DS4L/R HEX DISPLAYS = ADDRESS
        ;;  DS2                 = ACCUMULATOR
        ;;
        ;; USAGE:   RST 08H
        ;; AFFECTS: NONE
        ;;
DRST08: .EQU    $

        EX      (SP),HL     ; GET CALLER RETURN ADDRESS INTO HL
        PUSH    AF          ; PRESERVE A & FLAGS
        LD      A,H         ; DISPLAY HIGH BYTE OF CALLER'S ADDRESS
        OUT     (DS4L),A
        LD      A,L         ; DISPLAY LOW BYTE OF CALLER'S ADDRESS
        OUT     (DS4R),A
        POP     AF          ; RESTORE A & FLAGS
        OUT     (DS2),A     ; DISPLAY CALLER'S A
        EX      (SP),HL     ; PUT CALLER RETURN ADDRESS & HL BACK
        RET

        ;; PRINT HEX-ASCII REPRESENTATION OF REGISTER PAIR HL BY STORING H & L SEPERATELY
        ;; TO SCRATCH RAM LOCATIONS THEN DOING NORMAL H2ASC CONVERSION/PRINT OF CONTENTS
        ;; HL = ADDRESS VALUE THAT IS TO BE PRINTED IN FORM FFFF
        ;;
PRTADR: PUSH    HL          ; SAVE REGS WHILE WE DO ASCII CONVERSION OF ADDRESS
        PUSH    DE
        PUSH    BC
        LD      D,H         ; SAVE ADDRESS IN REG PAIR DE
        LD      E,L
        LD      HL,SCRAT1   ; POINT HL TO HIGH-BYTE STORAGE LOCATION
        LD      A,D         ; GET HIGH BYTE OF WORKING ADDRESS
        LD      (HL),A      ; SAVE TO WORK VAR
        CALL    HX2ASC      ; GET ASCII REPRESENTATION OF HIGH-BYTE INTO BC REG PAIR
        CALL    CONOUT      ; PRINT HIGH NIBBLE ASII REPRESENTATION (ALREADY IN REG C)
        LD      C,B         ; MOVE LOW-NIBBLE ASCII REPRESENTATION INTO REG C
        CALL    CONOUT      ; PRINT LOW-NIBBLE
        LD      HL,SCRAT2   ; POINT HL TO LOW-BYTE STORAGE LOCATION
        LD      A,E         ; GET LOW BYTE OF WORKING ADDRESS
        LD      (HL),A      ; SAVE TO WORK VAR
        CALL    HX2ASC      ; GET ASCII REPRESENTATION OF HIGH-BYTE INTO BC REG PAIR
        CALL    CONOUT      ; PRINT HIGH NIBBLE ASII REPRESENTATION (ALREADY IN REG C)
        LD      C,B         ; MOVE LOW-NIBBLE ASCII REPRESENTATION INTO REG C
        CALL    CONOUT      ; PRINT LOW-NIBBLE
        POP     BC
        POP     DE
        POP     HL
        RET

        ;; BYTE-TO-ASCII CONVERSION
        ;;  HL = ADDRESS OF MEMORY LOCATION TO BE CONVERTED
        ;;  B = RETURNED ASCII REPRESENTATION OF LOW NIBBLE
        ;;  C = RETURNED ASCII REPRESENTATION OF HIGH NIBBLE
        ;;
HX2ASC: PUSH    AF          ; SAVE REGS

        ;; CONVERT HIGH NIBBLE
        LD      A,(HL)      ; GET MEMORY CONTENTS INTO A
        AND     11110000B   ; CLEAR  LOW NIBBLE
        RRA                 ; RIGHT-JUSTIFY HIGH NIBBLE
        RRA
        RRA
        RRA
        CP      10          ; IS DATA 10 OR MORE?
        JR      C,_ASCZ1
        ADD     A,'A'-'9'-1 ; YES - ADD OFFSET FOR LETTERS
_ASCZ1: ADD     A,'0'       ; ADD OFFSET FOR ASCII
        LD      C,A

        ;; CONVERT LOW NIBBLE
        LD      A,(HL)      ; GET MEMORY CONTENTS INTO A
        AND     00001111B   ; CLEAR HIGH NIBBLE
        CP      10          ; IS DATA 10 OR MORE?
        JR      C,_ASCZ2
        ADD     A,'A'-'9'-1 ; YES - ADD OFFSET FOR LETTERS
_ASCZ2: ADD     A,'0'       ; ADD OFFSET FOR ASCII
        LD      B,A

        POP     AF          ; RESTORE REGS
        RET

        ;; -------------------------------------------------------------
        
