
        ;; F(ILL) MEMORY
        ;;
        ;; FORMAT:  F STARTADDR ENDADDR VALUE
        ;;
        ;;   THE FILL MEMORY COMMAND REPLACES THE CONTENTS OF MEMORY BETWEEN THE STARTING
        ;;   ADDRESS AND ENDING ADDRESS, INCLUSIVE, WITH THE SPECIFIED VALUE.
        ;;
        ;; --------------------------------------------------------------------------------
SMCMDF: .EQU    $

        ;; VALIDATE CALLED CONDITIONS
        ;;
        ;; --------------------------------------------------------------------------------
        ; VERIFY SMPB1 NOT BLANK AND VALID INT
        LD      HL,SMPB1    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      Z,_SMFV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK = A SPECIFIED STARTING ADDRESS. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO - SYNTAX ERROR
        LD      (_SMFSAD),DE; YES - SAVE PARAMETER STARTADDR

        ; VERIFY SMPB2 NOT BLANK AND VALID INT
        LD      HL,SMPB2    ; PARAM BUFFER 2
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMFV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO - SYNTAX ERROR
        LD      (_SMFEAD),DE; YES - SAVE PARAMETER ENDADDR

        ; VERIFY SMPB3 NOT BLANK AND VALID INT
        LD      HL,SMPB3    ; PARAM BUFFER 3
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMFV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO - SYNTAX ERROR
        LD      A,D         ; VERIFY VALUE ENTERED FITS IN SINGLE REGISTER E -- D MUST BE ZERO
        CP      0           ; IS IT?
        JP      NZ,_SMFV3   ; NO - SIZE ERROR
        LD      A,E         ; YES - SAVE IT INTO REG A

        ; VERIFY END ADDRESS IS GREATER THAN START ADDRESS
        AND     A           ; CLEAR CARRY
        LD      HL,(_SMFEAD); GET END ADDRESS INTO HL -- ASSUME IS THE LARGER
        LD      DE,(_SMFSAD); GET START ADDRESS INTO DE -- ASSUME IS THE SMALLER
        SBC     HL,DE       ; SUBTRACT START FROM END
        JP      C,_SMEV2    ; ERROR IF CARRY SHOWS WE HAD TO BORROW (START WAS LARGER THAN END)

        ; VERIFY WE HAVE A NON-ZERO RANGE
        JP      Z,_SMFV2    ; ERROR IF BOTH ARE THE SAME (NO RANGE)

        ;; PERFORM FILL OPERATION
        PUSH    HL          ; HL IS HOLDING RANGE SIZE
        POP     BC          ; GET INTO REG PAIR BC
        LD      HL,(_SMFSAD); START ADDRESS INTO HL
        LD      DE,(_SMFSAD); DESTINATION ADDRESS INTO DE
        LD      (HL),A      ; MANUALLY SET FIRST FILL BYTE
        INC     DE          ; START FILLING 1 BYTE AFTER SOURCE
        LDIR                ; EXECUTE COPY

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"  FILL OPERATION COMPLETED",CR,LF,CR,LF,NULL

        RET


        ; SYSMON COMMAND 'C' VALIDATION ERRORS
_SMFV1: LD      HL,SMERR00  ; LOAD 'SYNTAX ERROR' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMFV2: LD      HL,SMERR04  ; LOAD 'MALFORMED RANGE' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMFV3: LD      HL,SMERR05  ; LOAD 'RANGE OR SIZE' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMFSAD:.DW     1           ; START ADDRESS
_SMFEAD:.DW     1           ; END ADDRESS

        ;------ END SMCMD_F --------------------------------