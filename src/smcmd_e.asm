
        ;; E(XAMINE) MEMORY
        ;;
        ;; FORMAT:  E <START> <END>
        ;;
        ;;   THE EXAMINE MEMORY COMMAND OUTPUTS A TABULAR DISPLAY OF THE CONTENTS OF MEMORY
        ;;   IN HEXADECIMAL AND ASCII REPRESENTATION.  EACH LINE HAS THE FOLLOWING FORMAT:
        ;;
        ;;   AAAA  DD DD DD DD DD DD DD DD DD DD DD DD DD DD DD DD  CCCCCCCCCCCCCCCC
        ;;
        ;;   WHERE AAAA IS THE STARTING MEMORY ADDRESS OF THE LINE IN HEXADECIMAL, THE DD'S
        ;;   ARE THE HEX VALUES OF THE 16 BYTES OF DATA STARTING AT LOCATION AAAA, AND THE
        ;;   C'S ARE THE PRINTABLE ASCII CHARACTERS EQUIVALENT TO EACH DATA BYTE.  BYTES
        ;;   LESS THAN 20 HEX ARE REPLACED IN THE ASCII PORTION OF THE DISPLAY BY PERIODS.
        ;;
        ;;   THE EXAMINE MEMORY COMMAND ACCEPTS ZERO, ONE, OR TWO ADDRESS PARAMETERS.  IF
        ;;   TWO ADDRESSES ARE SPECIFIED, THE BLOCK OF MEMORY BETWEEN THOSE TWO LOCATIONS
        ;;   WILL BE DISPLAYED.  ENTERING ONLY ONE ADDRESS WILL DISPLAY 256 BYTES OF MEMORY
        ;;   STARTING AT THE SPECIFIED LOCATION. TYPING 'E' WITH NO PARAMETERS WILL DISPLAY
        ;;   THE NEXT 256-BYTE BLOCK OF MEMORY STARTING AT THE ADDRESS FOLLOWING THE LAST
        ;;   DISPLAYED BYTE. ONCE AN EXAMINE COMMAND HAS BEEN EXECUTED, PRESSING 'ENTER'
        ;;   BY ITSELF WILL BE INTERPRETED THE SAME AS 'E' WITH NO PARAMETERS.
        ;;
        ;; --------------------------------------------------------------------------------

SMCMDE: .EQU    $

        ;; VALIDATE CALLED CONDITIONS
        ;;
        ;;  DISPATCH ASSURES US THAT SMPB0 CONTAINS 'E' (EVEN FOR ENTER-ONLY) USER INPUT
        ;; --------------------------------------------------------------------------------
        ; VERIFY SMPB1 BLANK OR VALID INT
        LD      HL,SMPB1    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMDSA    ; BLANK, MODE = DISPLAY 256 BYTES BEGINNING AT NEXT START ADDRESS
        CALL    TOINT       ; NOT BLANK = A SPECIFIED STARTING ADDRESS. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO
        LD      (SMCURA),DE ; YES - SAVE PARAMETER 'SMCURA' (START/CURRENT ADDRESS)

        ; VERIFY SMPB2 BLANK OR VALID INT
        LD      HL,SMPB2    ; PARAM BUFFER 2
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMDSA    ; BLANK, MODE = DISPLAY 256 BYTES BEGINNING AT SPECIFIED START ADDRESS
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEV1   ; NO
        LD      (SMENDA),DE ; YES - SAVE PARAMETER 'SMENDA' (END ADDRESS)

        ; VERIFY OTHER PARAM PARSE BUFFERS ARE BLANK
        ;  BECAUSE OF THE WAY THE PARSER WORKS WE ONLY HAVE TO CHECK BUFFER 3.
        ;  BUFFERS 4 AND 5 CAN'T BE POPULATED IF BUFFER 3 IS BLANK
        LD      HL,SMPB3    ; PARAM BUFFER 3
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      NZ,_SMEV1   ; NON-BLANK - REPORT SYNTAX ERROR

        ; VERIFY END ADDRESS IS GREATER THAN START ADDRESS
        AND     A           ; CLEAR CARRY
        LD      HL,(SMENDA) ; GET END ADDRESS INTO HL -- ASSUME IS THE LARGER
        LD      DE,(SMCURA) ; GET START ADDRESS INTO DE -- ASSUME IS THE SMALLER
        SBC     HL,DE       ; SUBTRACT START FROM END
        JP      C,_SMEV2    ; ERROR IF CARRY SHOWS WE HAD TO BORROW (START WAS LARGER THAN END)

        ; VERIFY WE HAVE A NON-ZERO RANGE
        JP      Z,_SMEV2    ; ERROR IF BOTH ARE THE SAME (NO RANGE)
        JP      _SMDSE      ; ALL GOOD, MODE = DISPLAY NUMBER OF BYTES BETWEEN START ADDRESS AND END ADDRESS


    ;; DISPLAY 256 BYTES BEGINNING AT SPECIFIED ADDRESS
    ;;   HANDLES 'E' WITH ONE OR ZERO ADDRESS PARAMETERS
    ;;   1 PARAM = SPECIFIED STARTING ADDRESS
    ;;   0 PARAM = DEFAULT STARTING ADDRESS IS NEXT UNDISPLAYED ADDRESS OR 0000H IF FIRST INVOCATION
    ;;
    ;; ---------------------------------------------------------------------------------------------
_SMDSA: .EQU    $

        ; SET END ADDRESS AS CURRENT + 256
        LD      HL,(SMCURA) ; GET CURRENT ADDRESS FROM VARIABLE 'SMCURA'
        LD      DE,0100H    ;
        ADC     HL,DE
        JR      C,_SMENX    ; EXCEEDED LAST MEMORY LOCATION - CONSTRAIN
        LD      (SMENDA),HL ; VALID ENDING ADDRESS - SAVE TO WORK VAR
        JR      _SMDISP     ; DISPLAY

_SMENX: LD      HL,0FFFFH   ; LIMIT ENDING ADDRESS TO LAST BYTE OF MEMORY
        LD      (SMENDA),HL
        JR      _SMDISP     ; DISPLAY


        ;; DISPLAY BYTES BETWEEN START ADDRESS AND END ADDRESS
_SMDSE: .EQU    $

        CALL    _SMDISP     ; DISPLAY
        RET


        ;; DISPLAY WORKER ROUTINE
_SMDISP:CALL    PRINL
        .TEXT   CR,LF,NULL

        ; PRINT ADDRESS
_SMDSL: LD      HL,SMCURA+1         ; POINT HL AT ADDRESS WORD HIGH BYTE
        CALL    BY2HXA              ; CONVERT BYTE TO 2 PRINTABLE ASCII CHARS IN REG PAIR DE
        LD      C,D                 ; PRINT
        CALL    CONOUT
        LD      C,E
        CALL    CONOUT

        LD      HL,SMCURA           ; POINT HL AT ADDRESS WORD LOW BYTE
        CALL    BY2HXA              ; CONVERT BYTE TO 2 PRINTABLE ASCII CHARS IN REG PAIR DE
        LD      C,D                 ; PRINT
        CALL    CONOUT
        LD      C,E
        CALL    CONOUT

        CALL    PRINL
        .TEXT   "H  ",NULL

        ; PRINT HEX REPRESENTATION OF 16 DATA BYTES BEGINNING AT CURRENT ADDRESS
        LD      B,16
        LD      HL,(SMCURA)
_SMDSD: CALL    BY2HXA              ; CONVERT BYTE VALUE TO PRINTABLE 2-CHAR HEX VALUE IN REG PAIR DE
        LD      C,D                 ; PRINT HEX DIGIT FOR HIGH NIBBLE
        CALL    CONOUT              ;
        LD      C,E                 ; PRINT HEX DIGIT FOR LOW NIBBLE
        CALL    CONOUT              ;
        LD      A,(HL)              ; GET BYTE VALUE FOR DISPLAY AS ASCII REPRESENTATION
        CALL    _SMDAB              ; SAVE TO ASCII DISPLAY BUFFER

        CALL    PRINL               ; PRINT SEPARATOR BETWEEN BYTE HEX REPRESENTATION DIGIT PAIRS
        .TEXT   " ",NULL

        INC     HL                  ; NEXT BYTE
        DJNZ    _SMDSD              ;

        LD      (SMCURA),HL         ; UPDATE CURRENT ADDRESS

        CALL    PRINL               ; PRINT AN EXTRA SPACE SEPARATOR
        .TEXT   " ",NULL

        ; PRINT ACCUMULATED ASCII CHAR BUFFER AND CONCLUDE LINE
        PUSH    HL
        LD      HL,SMASCII+16       ; ENSURE BUFFER HAS TERMINATING NULL
        LD      (HL),0
        LD      HL,SMASCII
        CALL    PRSTRZ
        POP     HL

        CALL    PRINL
        .TEXT   CR,LF,NULL

        ; END LOOP WHEN CURRENT ADDRESS = END ADDRESS
        PUSH    HL
        AND     A                   ; CLEAR CARRY
        LD      HL,(SMENDA)
        LD      DE,(SMCURA)
        SBC     HL,DE
        POP     HL
        JR      NZ,_SMDSL

        ; UPDATE DEFAULT START ADDRESS FOR NEXT INVOCATION
        INC     HL
        LD      (SMCURA),HL         ; UPDATE CURRENT ADDRESS

        RET

        ;; ASCII-REPRESENTATION BUFFER BUILD
        ;;   FOR BYTE VALUES 20H-7EH, STORE FOR DISPLAY IN CORRESPONDING BUFFER LOCATION 1-16
        ;;   FOR NON-PRINTABLE BYTE VALUES LESS THAN 20H OR GREATER THAN 7EH, STORE A PERIOD.
        ;;
        ;; PARAMETERS:
        ;;   A = CHARACTER
        ;;
        ;;------------------------------------------------------------------------------------
_SMDAB: PUSH    AF          ; SAVE REGS WE'LL USE
        PUSH    HL
        PUSH    DE

        LD      D,0         ; B INTO DE FOR HL MATH
        LD      E,B
        LD      HL,SMASCII+16   ; POINT TO END OF BUFFER
        AND     A           ; CLEAR CARRY
        SBC     HL,DE       ; SUBTRACT REVERSE COUNT TO GET STORAGE LOC
        PUSH    HL          ; SAVE SO CAN USE AS PARAMS FOR RANGE CALL
        LD      H,7EH       ; SEE IF CHARACTER IS BETWEEN 20H AND 7EH INCLUSIVE
        LD      L,20H
        CALL    ISINRHL
        POP     HL
        JR      C,_SMDA1    ; YES - SAVE AS-IS
        LD      A,'.'       ; NO - REPLACE WITH A PERIOD
_SMDA1: LD      (HL),A

        POP     DE          ; RESTORE REGS
        POP     HL
        POP     AF
        RET

        ; SYSMON COMMAND 'E' VALIDATION ERRORS
_SMEV1: LD      HL,SMERR00  ; LOAD 'SYNTAX ERROR' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMEV2: LD      HL,SMERR04  ; LOAD 'MALFORMED RANGE' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

SMLCNT: .DS     1                       ; COUNT OF BYTES DISPLAYED ON LINE
SMCURA: .DW     1                       ; ADDRESS FOR NEXT MEMORY COMMAND
SMENDA: .DW     1                       ; ENDING ADDRESS FOR CURRENT OPERATION
SMASCII:.DS     17                      ; PRINTABLE ASCII BUILD BUFFER, 16 CHARS PLUS NULL