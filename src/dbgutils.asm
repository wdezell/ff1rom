DBGUTS: .EQU    $               ; GENERAL UTILITIES END. TAG FOR RELOC & SIZE CALCS
        .PHASE DBGUTL           ; ASSEMBLE RELATIVE TO EXECUTION LOCATION

;; -------------------------------------------------------------
;; MISC DEBUG TOOLS
;; -------------------------------------------------------------

        ;; OUTPUT ACCUMULATOR AND ADDRESS *FOLLOWING* CALLING RST 08H
        ;;  DS4L/R HEX DISPLAYS = ADDRESS
        ;;  DS2                 = ACCUMULATOR
        ;;
        ;; USAGE:   RST 08H
        ;; AFFECTS: NONE
        ;; ---------------------------------------------------------
DEBG08: .EQU    $

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


        ;; OUTPUT REGISTERS AND FLAGS TO TO CONSOLE AND WAIT FOR A KEYPRESS
        ;;
        ;; USAGE:   RST 10H
        ;; AFFECTS: USES SCRATCH LOCATIONS RESERV1-RESERV4
        ;;          REGISTERS AND FLAGS ARE PRESERVED
        ;; ---------------------------------------------------------
DEBG10: .EQU    $

        EX      (SP),HL     ; SAVE RETURN ADDRESS FOR DISPLAY
        LD      (RESRV3),HL
        EX      (SP),HL

        ; PUSH COPIES OF EVERYTHING TO STACK FOR INSPECTION
        PUSH    AF          ; ORDER HERE MUST CORRESPOND TO DISPLAY POPS
        PUSH    IY
        PUSH    IX
        PUSH    HL
        PUSH    DE
        PUSH    BC

        ; SWITCH TO ALTERNATE REGISTERS AND FLAGS SO DON'T DISTURB CALLER
        EXX
        EX      AF,AF'

        CALL    PRINL
        .TEXT   CR,LF,NULL

        ;; LINE 1
        ; BC
        CALL    PRINL
        .TEXT   "BC [",NULL
        POP     HL          ; COPY OF ORIGINAL REG PAIR BC
        LD      (RESRV1),HL
        LD      HL,RESRV2   ; 1ST REG OF PAIR IN LOC+1
        CALL    PRTMEM
        LD      HL,RESRV1   ; 2ND REG OF PAIR IN LOC+0
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; DE
        CALL    PRINL
        .TEXT   "DE [",NULL
        POP     HL
        LD      (RESRV1),HL
        LD      HL,RESRV2
        CALL    PRTMEM
        LD      HL,RESRV1
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; HL
        CALL    PRINL
        .TEXT   "HL [",NULL
        POP     HL
        LD      (RESRV1),HL
        LD      HL,RESRV2
        CALL    PRTMEM
        LD      HL,RESRV1
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; IX
        CALL    PRINL
        .TEXT   "IX [",NULL
        POP     HL
        LD      (RESRV1),HL
        LD      HL,RESRV2
        CALL    PRTMEM
        LD      HL,RESRV1
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; IY
        CALL    PRINL
        .TEXT   "IY [",NULL
        POP     HL
        LD      (RESRV1),HL
        LD      HL,RESRV2
        CALL    PRTMEM
        LD      HL,RESRV1
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]",CR,LF,NULL

        ;; LINE 2
        ; PROGRAM COUNTER (RETURN ADDRESS)
        CALL    PRINL
        .TEXT   "PC [",NULL
        LD      HL,RESRV4
        CALL    PRTMEM
        LD      HL,RESRV3
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; AF - A
        CALL    PRINL
        .TEXT   " A [",NULL
        POP     HL          ; COPY OF ORIGINAL ACCUMULATOR AND FLAGS
        LD      (RESRV2),HL
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; AF - FLAGS
        CALL    PRINL
        .TEXT   "  S-",NULL
        LD      HL,RESRV1
        BIT     7,(HL)
        CALL    NZ,_D10P0
        CALL    Z,_D10P1
        CALL    PRINL
        .TEXT   "  Z-",NULL
        BIT     6,(HL)
        CALL    NZ,_D10P0
        CALL    Z,_D10P1
        CALL    PRINL
        .TEXT   "  H-",NULL
        BIT     4,(HL)
        CALL    NZ,_D10P0
        CALL    Z,_D10P1
        CALL    PRINL
        .TEXT   "  P/V-",NULL
        BIT     2,(HL)
        CALL    NZ,_D10P0
        CALL    Z,_D10P1
        CALL    PRINL
        .TEXT   "  N-",NULL
        BIT     1,(HL)
        CALL    NZ,_D10P0
        CALL    Z,_D10P1
        CALL    PRINL
        .TEXT   "  C-",NULL
        BIT     0,(HL)
        CALL    NZ,_D10P0
        CALL    Z,_D10P1
        CALL    PRINL
        .TEXT   CR,LF,NULL

        ; WAIT FOR A KEYPRESS
        CALL    PRINL
        .TEXT   "DEBUG: PRESS ANY KEY...",NULL
        CALL    CONCIN

        ; RESTORE NORMAL REGISTERS AND FLAGS
        EX      AF,AF'
        EXX
        RET

        ;DEBG10 BIT HELPER
_D10P0:.EQU     $
        LD      C,"0"
        CALL    CONOUT
        RET

        ;DEBG10 BIT HELPER
_D10P1:.EQU $
        LD  C,"1"
        CALL CONOUT
        RET

;; -------------------------------------------------------------
        .DEPHASE
DBGUTE: .EQU    $               ; GENERAL UTILITIES END. TAG FOR RELOC & SIZE CALCS
DBSIZ:  .EQU    DBGUTE-DBGUTS   ; SIZE OF UTILITIES CODE
