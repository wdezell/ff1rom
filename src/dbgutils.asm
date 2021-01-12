DBGUTS: .EQU    $               ; DEBUG UTILITIES START. TAG FOR RELOC & SIZE CALCS
        .PHASE DBGUTL           ; ASSEMBLE RELATIVE TO EXECUTION LOCATION

;; -------------------------------------------------------------
;; MISC DEBUG TOOLS
;; -------------------------------------------------------------


        ;; GENERALIZED ADVISORY AND HALT FOR PLACES WE SHOULD
        ;;  NEVER REACH.  IF THIS DISPLAYS THE FAT LADY HAS SUNG.
        ;; ---------------------------------------------------------
ABEND:  .EQU    $

        ; IN CASE DEBUG LED DISPLAY ATTACHED DO RST 08H-EQUIV OUTPUT
        EX      (SP),HL         ; GET CALLER RETURN ADDRESS INTO HL
        PUSH    AF              ; PRESERVE A & FLAGS
        LD      A,H             ; DISPLAY HIGH BYTE OF CALLER'S ADDRESS
        OUT     (DS4L),A
        LD      A,L             ; DISPLAY LOW BYTE OF CALLER'S ADDRESS
        OUT     (DS4R),A
        POP     AF              ; RESTORE A & FLAGS
        OUT     (DS2),A         ; DISPLAY CALLER'S A
        EX      (SP),HL         ; PUT CALLER RETURN ADDRESS & HL BACK

        ; IN CASE WE'VE GOT CONSOLE
        RST     10H
        CALL    PRINL
        .TEXT   CR,LF,"ABEND",NULL

        HALT
        JR      $


        ;; CLEAR FLOATING GARBAGE ON DEBUG DISPLAYS IF THEY'RE ATTACHED
        ;; ---------------------------------------------------------
CLDBDS: XOR     A           ; ZERO INTO ACCUMULATOR
        OUT     (DS4L)      ; WRITE TO DEBUG DISPLAY PORTS
        OUT     (DS4R)
        OUT     (DS2)
        RET


        ;; OUTPUT ACCUMULATOR AND RETURN ADDRESS
         ;; ( ADDRESS *FOLLOWING* RST 08H CALL)
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


        ;; OUTPUTS CONTENTS OF PRIMARY PROCESSOR REGISTERS
        ;;  AND FLAGS TO CONSOLE. CURRENTLY I & R ARE OMITTED.
        ;;
        ;; NOTES:
        ;;   PC         WILL REFLECT ADDRESS OF INSTRUCTION IMMEDIATELY
        ;;              *FOLLOWING* RST 10H CALL - E.G., THE RETURN ADDRESS
        ;;
        ;;   SP         REFLECTS ADDRESS OF SP FOLLOWING LAST STATE-CAPTURE PUSH,
        ;;              MOST USEFUL AS AN INDICATOR OF STACK LOADING.
        ;;
        ;;   BC,DE,HL   REGISTER PAIRS ARE DISPLAYED WITH AN INTERNAL ':' SEPARATOR
        ;;              WHICH SHOULD BE IGNORED WHEN CONSIDERING AS A 16-BIT REGISTER.
        ;;              8-BIT COMPONENTS ARE DISPLAYED L-R AS THEY READ ('[BB:CC]'),
        ;;              NOT REVERSED AS APPEARING IN MEMORY OR OPCODES.
        ;;
        ;; USAGE:   RST 10H
        ;; AFFECTS: USES SCRATCH LOCATIONS RESERV1-RESERV4
        ;;          PRIMARY REGISTERS AND FLAGS ARE PRESERVED
        ;; ---------------------------------------------------------
DEBG10: .EQU    $

        ; SP VALUE
        LD	    (RESRV1),SP     ; SAVE SP VALUE TO SCRATCH LOCATION

        ; SP CONTENTS
        EX      (SP),HL         ; SAVE RETURN ADDRESS TO SCRATCH LOCATION
        LD      (RESRV3),HL
        EX      (SP),HL

        ; PUSH COPIES OF EVERYTHING TO STACK FOR INSPECTION
        PUSH    AF          ; ORDER HERE INVERSE OF DISPLAY POPS
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
        ; DISPLAY SP (STORED BY ABOVE INTO RESRV1 & RESRV2
        CALL    PRINL
        .TEXT   "SP [",NULL
        LD      HL,RESRV2   ; 1ST REG OF PAIR IN LOC+1
        CALL    PRTMEM
        LD      HL,RESRV1   ; 2ND REG OF PAIR IN LOC+0
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; DISPLAY BC
        CALL    PRINL
        .TEXT   "BC [",NULL
        POP     HL          ; COPY OF ORIGINAL REG PAIR BC
        LD      (RESRV1),HL
        LD      HL,RESRV2   ; 1ST REG OF PAIR IN LOC+1
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   ":",NULL
        LD      HL,RESRV1   ; 2ND REG OF PAIR IN LOC+0
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; DISPLAY DE
        CALL    PRINL
        .TEXT   "DE [",NULL
        POP     HL
        LD      (RESRV1),HL
        LD      HL,RESRV2
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   ":",NULL
        LD      HL,RESRV1
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; DISPLAY HL
        CALL    PRINL
        .TEXT   "HL [",NULL
        POP     HL
        LD      (RESRV1),HL
        LD      HL,RESRV2
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   ":",NULL
        LD      HL,RESRV1
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; DISPLAY IX
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

        ; DISPLAY IY
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
        ; DISPLAY PROGRAM COUNTER (RETURN ADDRESS)
        CALL    PRINL
        .TEXT   "PC [",NULL
        LD      HL,RESRV4
        CALL    PRTMEM
        LD      HL,RESRV3
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; DISPLAY AF - A
        CALL    PRINL
        .TEXT   " A [",NULL
        POP     HL          ; GET COPY OF ORIGINAL ACCUMULATOR AND FLAGS
        LD      (RESRV1),HL ; F INTO 1, A INTO 2
        LD      HL,RESRV2
        CALL    PRTMEM
        CALL    PRINL
        .TEXT   "]  ",NULL

        ; DISPLAY AF - FLAGS
        CALL    PRINL
        .TEXT   "   S-",NULL
        LD      HL,RESRV1
        BIT     7,(HL)
        CALL    Z,_D10P0
        CALL    NZ,_D10P1
        CALL    PRINL
        .TEXT   "  Z-",NULL
        BIT     6,(HL)
        CALL    Z,_D10P0
        CALL    NZ,_D10P1
        CALL    PRINL
        .TEXT   "    H-",NULL
        BIT     4,(HL)
        CALL    Z,_D10P0
        CALL    NZ,_D10P1
        CALL    PRINL
        .TEXT   "  P/V-",NULL
        BIT     2,(HL)
        CALL    Z,_D10P0
        CALL    NZ,_D10P1
        CALL    PRINL
        .TEXT   "  N-",NULL
        BIT     1,(HL)
        CALL    Z,_D10P0
        CALL    NZ,_D10P1
        CALL    PRINL
        .TEXT   "  C-",NULL
        BIT     0,(HL)
        CALL    Z,_D10P0
        CALL    NZ,_D10P1
        CALL    PRINL
        .TEXT   CR,LF,NULL

IF 0    ; SUPPRESSING FOR NOW AS INTRODUCES SIDE EFFECTS DEBUGGING CON-RELATED CODE
        ; WAIT FOR A KEYPRESS
        CALL    CONCIN
ENDIF
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
_D10P1:.EQU     $
        LD      C,"1"
        CALL    CONOUT
        RET


        ;; DEBUG CHECKPOINT HELPER MACRO
        ;;  SIMPLIFY DISPLAY OF NAMED CHECKPOINTS TO CONSOLE
        ;;
        ;; USAGE:   DBCK    ALPHA
        ;; ---------------------------------------------------------
DBCK    MACRO   NAMESTR

        ; ----BEGIN DEBUG / REMOVE ----
        CALL    PRINL
        .TEXT   "DEBUG: `NAMESTR`",CR,LF,NULL
        ; ----END DEBUG / REMOVE   ----

        ENDM


        ;; DEBUG CHECKPOINT HELPER MACRO
        ;;  SIMPLIFY DISPLAY OF NAMED CHECKPOINTS TO CONSOLE
        ;;
        ;; USAGE:   DBCKD    BRAVO
        ;; ---------------------------------------------------------
DBCKD    MACRO   NAMESTR

        ; ----BEGIN DEBUG / REMOVE ----
        CALL    PRINL
        .TEXT   "DEBUG: `NAMESTR`",CR,LF,NULL
        RST     10H
        ; ----END DEBUG / REMOVE   ----

        ENDM

;; -------------------------------------------------------------
        .DEPHASE
DBGUTE: .EQU    $               ; DEBUG UTILITIES END. TAG FOR RELOC & SIZE CALCS
DBSIZ:  .EQU    DBGUTE-DBGUTS   ; SIZE OF DEBUG UTILITIES CODE
