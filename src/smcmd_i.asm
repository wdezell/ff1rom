
        ;; I(NPUT) FROM PORT
        ;;
        ;; FORMAT:  PORT COUNT SAVEADDR
        ;;
        ;;   INPUT SPECIFIED COUNT OF VALUES FROM SPECIFIED PORT AND STORE SEQUENTIALLY IN
        ;;   MEMORY BEGINNING AT THE ADDRESS SPECIFIED. COUNT MUST BE IN THE RANGE 0-255.
        ;;
        ;;   THE I/O PORT IS SPECIFIED BY THE PORT PARAMETER. PORT MUST BE IN THE RANGE 0-255.
        ;;
        ;; --------------------------------------------------------------------------------
SMCMDI: .EQU    $

        ;; VALIDATE CALLED CONDITIONS
        ;;
        ;; --------------------------------------------------------------------------------
        ; VERIFY SMPB1 NOT BLANK AND VALID INT
        LD      HL,SMPB1    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      Z,_SMIV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        LD      A,D         ; VERIFY VALUE ENTERED FITS IN SINGLE REGISTER E -- D MUST BE ZERO
        CP      0           ; IS IT?
        JP      NZ,_SMIV2   ; NO - SIZE ERROR
        LD      A,E         ; MOVE INTO ACCUMULATOR FOR MEMORY SAVE
        LD      (_SMIPRT),A ; YES - SAVE PARAMETER PORT

        ; VERIFY SMPB2 NOT BLANK AND VALID INT
        LD      HL,SMPB2    ; PARAM BUFFER 2
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMIV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMIV1   ; NO - SYNTAX ERROR
        LD      A,D         ; VERIFY VALUE ENTERED FITS IN SINGLE REGISTER E -- D MUST BE ZERO
        CP      0           ; IS IT?
        JP      NZ,_SMIV2   ; NO - SIZE ERROR
        LD      A,E         ; MOVE INTO ACCUMULATOR FOR MEMORY SAVE
        LD      (_SMICNT),A ; YES - SAVE PARAMETER COUNT

        ; VERIFY SMPB3 NOT BLANK AND VALID INT
        LD      HL,SMPB3    ; PARAM BUFFER 3
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMIV1    ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMIV1   ; NO - SYNTAX ERROR
        LD      (_SMISAD),DE; YES - SAVE PARAMETER COUNT

        ;; SETUP TRANSFER DESTINATION AND COUNT
        LD      HL,(_SMISAD); STORE BEGINNING AT ADDRESS SPECIFIED
        LD      A,(_SMICNT) ; READ THIS MANY BYTES
        LD      B,A
        LD      A,(_SMIPRT) ; FROM THIS PORT
        LD      C,A

        ;; TRANSFER
        INIR

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"  TRANSFER OPERATION COMPLETED",CR,LF,CR,LF,NULL

        RET


        ; SYSMON COMMAND 'I' VALIDATION ERRORS
_SMIV1: LD      HL,SMERR00  ; LOAD 'SYNTAX ERROR' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET

_SMIV2: LD      HL,SMERR05  ; LOAD 'RANGE OR SIZE' MESSAGE
        CALL    SMPRSE      ; DISPLAY AND EXIT
        RET


_SMIPRT:.DB     1           ; INPUT PORT WORD
_SMICNT:.DB     1           ; COUNT OF BYTES TO READ
_SMISAD:.DW     1           ; STARTING ADDRESS AT WHICH TO SAVE INPUT DATA
