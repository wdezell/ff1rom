
        ;; M(ODIFY) MEMORY
        ;;
        ;; FORMAT:  M  ADDRESS
        ;;
        ;;   THE MODIFY MEMORY COMMAND ALLOWS INDIVIDUAL MEMORY LOCATIONS TO BE DISPLAYED
        ;;   AND/OR ALTERED USING THE MONITOR.  THIS COMMAND ACCEPTS ONE REQUIRED PARAMETER,
        ;;   WHICH IS THE MEMORY ADDRESS AT WHICH TO BEGIN EXAMINING OR ALTERING DATA.
        ;;   EACH LINE HAS THE FOLLOWING FORMAT:
        ;;
        ;;   AAAA  DD >
        ;;
        ;;   WHERE AAAA IS THE CURRENT MEMORY ADDRESS AND DD IS THE HEXADECIMAL VALUE OF
        ;;   THE DATA IN THAT LOCATION.  AFTER DISPLAYING THE CONTENTS OF A MEMORY LOCATION
        ;;   THE ROUTINE WAITS FOR ONE OF THE FOLLOWING ITEMS TO BE INPUT FROM THE CONSOLE:
        ;;
        ;;   * TYPING A CARRIAGE RETURN ALONE WILL CAUSE THE ROUTINE TO DISPLAY THE DATA AT
        ;;     THE NEXT LOCATION
        ;;
        ;;   * ENTERING A MINUS SIGN WILL HAVE SIMILAR EFFECT, EXCEPT THE ADDRESS IS
        ;;     DECREMENTED RATHER THAN INCREMENTED
        ;;
        ;;   * ENTERING A 2-DIGIT HEXADECIMAL NUMBER (NO 'H' SUFFIX) WILL CAUSE THAT VALUE
        ;;     TO BE STORED AT THE CURRENT LOCATION AND ADVANCE TO THE NEXT LOCATION.
        ;;
        ;;   * ENTERING ANY OTHER CHARACTER EXITS TO THE MAIN PROMPT
        ;;
        ;; --------------------------------------------------------------------------------

SMCMDM: .EQU    $

        ;; VALIDATE CALLED CONDITIONS
        ;;
        ;; --------------------------------------------------------------------------------
        ; VERIFY SMPB1 CONTAINS A VALID INT ADDRESS
        LD      HL,SMPB1    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      Z,_SMMV1    ; BLANK, DISPLAY ERROR AND EXIT
        CALL    TOINT       ; NOT BLANK = SPECIFIED ADDRESS. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMMV1   ; NO
        EX      DE,HL       ; YES - MOVE ADDRESS INTO HL FOR LOOP


        ;; MEM MODIFY DISPLAY AND INPUT LOOP
        ;;
        ;; --------------------------------------------------------------------------------
        ; DISPLAY ADDRESS
        CALL    PRINL
        .TEXT   CR,LF,CR,LF
        .TEXT  "  ENTER = ADVANCE, '-' = DECREMENT, HEX DIGIT PAIR ENTERS AUTOMATICALLY",CR,LF
        .TEXT  "  ANY OTHER KEY EXITS",CR,LF,CR,LF,NULL

_SMMDI: CALL    PRINL
        .TEXT   CR,LF,"  ",NULL

        PUSH    HL          ; SAVE LOOP INDEX, NEED HL FOR VARIOUS TASKS
        LD      (SMCURA),HL

        LD      HL,SMCURA+1 ; POINT HL AT ADDRESS WORD HIGH BYTE
        CALL    BY2HXA      ; CONVERT BYTE TO 2 PRINTABLE ASCII CHARS IN REG PAIR DE
        LD      C,D         ; PRINT
        CALL    CONOUT
        LD      C,E
        CALL    CONOUT

        LD      HL,SMCURA   ; POINT HL AT ADDRESS WORD LOW BYTE
        CALL    BY2HXA      ; CONVERT BYTE TO 2 PRINTABLE ASCII CHARS IN REG PAIR DE
        LD      C,D         ; PRINT
        CALL    CONOUT
        LD      C,E
        CALL    CONOUT

        CALL    PRINL
        .TEXT   "H  ",NULL

        ; DISPLAY DATA CONTAINED AT ADDRESS
        LD      HL,(SMCURA)
        CALL    BY2HXA      ; CONVERT BYTE VALUE TO PRINTABLE 2-CHAR HEX VALUE IN REG PAIR DE
        LD      C,D         ; PRINT HEX DIGIT FOR HIGH NIBBLE
        CALL    CONOUT      ;
        LD      C,E         ; PRINT HEX DIGIT FOR LOW NIBBLE
        CALL    CONOUT

        CALL    PRINL
        .TEXT   "  >",NULL

        ;; A LOCAL PARSE LOOP AS DESCRIBED BY THE USER GUIDE FOR THE FERGUSON BIG BOARD
        ;; (AFTER WRITING MY OWN ALTERNATIVE THE EASE OF USE FOR THIS UI BECAME APPARENT)
        ;;
        ;; ------------------------------------------------------------------------------

        ; READ A SINGLE CHARACTER
        CALL    CONCIN      ; READ A CHARACTER INTO A
        LD      C,A         ;
        CALL    CONOUT      ; ECHO

        CP      CR          ; DID THE OPERATOR PRESS 'ENTER'?
        JP      Z,_SMMAV    ; YES - ADVANCE TO NEXT LOCATION
        CP      '-'         ; DID THE OPERATOR PRESS THE MINUS SUGN?
        JP      Z,_SMMDC    ; YES - DECREMENT
        CALL    ISHDIGT     ; IS IT A VALID HEX DIGIT?
        CALL    NC,_SMMEX   ; NO - EXIT
        LD      (CONBUF),A  ; YES - SAVE IT TO THE FIRST LOCATION OF CONBUF

        ; READ ANOTHER CHARACTER TO SEE IF WE'VE GOT TWO HEX DIGITS
        CALL    CONCIN      ; READ A CHARACTER INTO A
        LD      C,A         ;
        CALL    CONOUT      ; ECHO

        CALL    ISHDIGT     ; IS IT A VALID HEX DIGIT ALSO?
        CALL    NC,_SMMEX   ; NO - EXIT
        LD      (CONBUF+1),A; YES - SAVE IT TO THE SECOND LOCATION OF CONBUF

        ; CONVERT ASCII CHAR STRING TO NUMERICAL VALUE
        LD      A,'H'       ; OUR CONVERION ROUTINE EXPECTS A SUFFIX TO DESIGNATE RADIX - H FOR HEXADECIMAL
        LD      (CONBUF+2),A;
        LD      HL,CONBUF+3 ; AND A NULL TERMINATOR FOR THE STRING TO BE CONVERTED
        LD      (HL),0      ;

        LD      HL,CONBUF   ; SPECIFY BUFFER LOCATION
        CALL    TOINT       ; AND CONVERT (RESULT IS IN DE)
        ;JR      NC,_SMMV1   ; ERROR BAIL IF CONVERSION PROBLEM

        ; ELSE STORE TO MEMORY, ADVANCE, DISPLAY
        POP     HL          ; RESTORE LOOP INDEX
        LD      (HL),E      ; WRITE MEMORY (IGNORE HIGH BYTE IN REG D SINCE INPUT LIMIT IS 2 HEX DIGITS)
        INC     HL          ; ADVANCE TO NEXT ADDRESS AND DISPLAY
        LD      (SMCURA),HL ; STORE FOR DISPLAY CONVERION
        JP      _SMMDI


_SMMEX: CALL    PRINL
        .TEXT   CR,LF,NULL

        POP     HL          ; EXIT
        POP     HL          ;
        RET


_SMMAV: POP     HL          ; RESTORE LOOP INDEX
        INC     HL          ; ADVANCE TO NEXT ADDRESS AND DISPLAY
        LD      (SMCURA),HL ; STORE FOR DISPLAY CONVERION
        JP      _SMMDI


_SMMDC: POP     HL          ; RESTORE LOOP INDEX
        DEC     HL          ; DECREMENT ADDRESS AND DISPLAY
        LD      (SMCURA),HL ; STORE FOR DISPLAY CONVERION
        JP      _SMMDI


        ; SYSMON COMMAND 'M' VALIDATION ERRORS
_SMMV1: LD      HL,SMERR00  ; LOAD 'SYNTAX ERROR' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

        ;------ END SMCMD_M --------------------------------