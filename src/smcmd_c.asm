
        ;; C(OPY) MEMORY
        ;;
        ;; FORMAT:  C STARTADDR ENDADDR DESTADDR
        ;;
        ;;   THE COPY MEMORY COMMAND COPIES THE CONTENTS OF MEMORY BETWEEN THE STARTING
        ;;   ADDRESS AND ENDING ADDRESS, INCLUSIVE, TO A RANGE OF EQUAL LENGTH BEGINNING
        ;;   AT THE SPECIFIED DISTINAGION ADDRESS.
        ;;
        ;;   IF THE DESTINATION RANGE WILL EXTEND BEYOND THE END OF MEMORY AN ERROR WILL
        ;;   BE REPORTED AND THE COPY WILL NOT BE PERFORMED.
        ;;
        ;; --------------------------------------------------------------------------------

SMCMDC: .EQU    $

        ;; VALIDATE CALLED CONDITIONS
        ;;
        ;; --------------------------------------------------------------------------------
        ; VERIFY SMPB1 NOT BLANK AND VALID INT
        LD      HL,SMPB1    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMCV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK = A SPECIFIED STARTING ADDRESS. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO - SYNTAX ERROR
        LD      (_SMCSAD),DE; YES - SAVE PARAMETER STARTADDR

        ; VERIFY SMPB2 NOT BLANK AND VALID INT
        LD      HL,SMPB2    ; PARAM BUFFER 2
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMCV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO - SYNTAX ERROR
        LD      (_SMCEAD),DE; YES - SAVE PARAMETER ENDADDR

        ; VERIFY SMPB3 NOT BLANK AND VALID INT
        LD      HL,SMPB3    ; PARAM BUFFER 3
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMCV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO - SYNTAX ERROR
        LD      (_SMCDAD),DE; YES - SAVE PARAMETER DESTADDR

        ; VERIFY END ADDRESS IS GREATER THAN START ADDRESS
        AND     A           ; CLEAR CARRY
        LD      HL,(_SMCEAD); GET END ADDRESS INTO HL -- ASSUME IS THE LARGER
        LD      DE,(_SMCSAD); GET START ADDRESS INTO DE -- ASSUME IS THE SMALLER
        SBC     HL,DE       ; SUBTRACT START FROM END
        JP      C,_SMEV2    ; ERROR IF CARRY SHOWS WE HAD TO BORROW (START WAS LARGER THAN END)

        ; VERIFY WE HAVE A NON-ZERO RANGE
        JP      Z,_SMCV2    ; ERROR IF BOTH ARE THE SAME (NO RANGE)

        ; VERIFY THAT COPY DESTINATION RANGE DOES NOT EXTEND BEYOND END OF MEMORY
        EX      DE,HL       ; GET RANGE SIZE INTO REG PAIR DE
        LD      HL,(_SMCDAD); GET DESTINATIN ADDRESS INTO HL
        ADD     HL,DE       ; ADD
        JR      C,_SMCV3    ; CARRY SET IF SUM EXCEEDS HL MAX VALUE OF FFFFH

        ;; PERFORM COPY OPERATION
        PUSH    DE          ; DE IS HOLDING RANGE SIZE
        POP     BC          ; GET INTO REG PAIR BE
        INC     BC          ; ADD ONE FOR INCLUSIVITY OF BOTH RANGE ENDPOINTS
        LD      HL,(_SMCSAD); START ADDRESS INTO HL
        LD      DE,(_SMCDAD); DESTINATION ADDRESS INTO DE
        LDIR                ; EXECUTE COPY

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"  COPY OPERATION COMPLETED",CR,LF,CR,LF,NULL

        RET


        ; SYSMON COMMAND 'C' VALIDATION ERRORS
_SMCV1: LD      HL,SMERR00  ; LOAD 'SYNTAX ERROR' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMCV2: LD      HL,SMERR04  ; LOAD 'MALFORMED RANGE' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMCV3: LD      HL,SMERR05  ; LOAD 'RANGE OR SIZE' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMCSAD:.DW     1           ; START ADDRESS
_SMCEAD:.DW     1           ; END ADDRESS
_SMCDAD:.DW     1           ; DESTINATION ADDRESS

        ;------ END SMCMD_C --------------------------------