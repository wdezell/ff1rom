
        ;; O(UTPUT) TO PORT
        ;;
        ;; FORMAT:  PORT VALUE
        ;;          PORT COUNT SRCADDR DELAY
        ;;
        ;;   OUTPUT SPECIFIED VALUE TO SPECIFIED PORT ONCE WHEN USING THE PORT/VALUE SYNTAX.
        ;;
        ;;   WHEN USING THE PORT/COUNT/ADDRESS/DELAY SYNTAX, THE VALUE(S) TO BE OUTPUT ARE
        ;;   READ FROM MEMORY AND OUTPUT TO THE SPECIFIED PORT AT A RATE DETERMINED BY THE
        ;;   'DELAY' PARAMETER.  DELAY IS SPECIFIED IN UNITS OF 0.25 SECONDS PER INCREMENT
        ;;   (E.G., A DELAY VALUE OF '4' WOULD RESULT IN A 1-SECOND DELAY).
        ;;
        ;;   THE I/O PORT IS SPECIFIED BY THE PORT PARAMETER. PORT MUST BE IN THE RANGE 0-255.
        ;;
        ;; --------------------------------------------------------------------------------

        ;; TODO -- PORT BELOW TO 'OUTPUT' IMPLEMENTATION

SMCMDO: .EQU    $

        ;; VALIDATE CALLED CONDITIONS
        ;;
        ;; --------------------------------------------------------------------------------
        ; VERIFY SMPB1 NOT BLANK AND VALID INT
        LD      HL,SMPB1    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      Z,_SMESYN   ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        LD      A,D         ; VERIFY VALUE ENTERED FITS IN SINGLE REGISTER E -- D MUST BE ZERO
        CP      0           ; IS IT?
        JP      NZ,_SMEROS  ; NO - SIZE ERROR
        LD      A,E         ; MOVE INTO ACCUMULATOR FOR MEMORY SAVE
        LD      (_SMOPRT),A ; YES - SAVE PARAMETER PORT

        ; VERIFY SMPB2 NOT BLANK AND VALID INT
        LD      HL,SMPB2    ; PARAM BUFFER 2
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      Z,_SMESYN   ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMESYN  ; NO - SYNTAX ERROR
        LD      A,D         ; VERIFY VALUE ENTERED FITS IN SINGLE REGISTER E -- D MUST BE ZERO
        CP      0           ; IS IT?
        JP      NZ,_SMEROS  ; NO - SIZE ERROR
        LD      A,E         ; MOVE INTO ACCUMULATOR FOR MEMORY SAVE
        LD      (_SMOCV),A  ; YES - SAVE PARAMETER COUNT/VALUE (ROLE DEPENDS ON MODE)

        ; VERIFY SMPB3 NOT BLANK AND VALID INT
        LD      HL,SMPB3    ; PARAM BUFFER 3
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JR      Z,_SMOOSM   ; BLANK - NOT ERROR, MEANS SIMPLE ONE-SHOT MODE
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMESYN  ; NO - SYNTAX ERROR
        LD      (_SMOSAD),DE; YES - SAVE PARAMETER SOURCE ADDRESS

        ; VERIFY SMPB4 NOT BLANK AND VALID INT
        LD      HL,SMPB4    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      Z,_SMESYN   ; BLANK - SYNTAX ERROR
        CALL    TOINT       ; NOT BLANK. DOES IT CONVERT TO A NUMBER?
        LD      A,D         ; VERIFY VALUE ENTERED FITS IN SINGLE REGISTER E -- D MUST BE ZERO
        CP      0           ; IS IT?
        JP      NZ,_SMEROS  ; NO - SIZE ERROR
        LD      A,E         ; MOVE INTO ACCUMULATOR FOR MEMORY SAVE
        LD      (_SMODLY),A ; YES - SAVE PARAMETER DELAY


        ;MULTI-TRANSFER MODE
        LD      HL,(_SMOSAD); OUTPUT FROM MEMORY BEGINNING AT ADDRESS SPECIFIED
        LD      A,(_SMOCV)  ; THIS MANY BYTES
        LD      B,A         ; SAVE COUNT INTO REG B
        LD      A,(_SMODLY) ; LOAD DELAY VALUE FROM SAVED PARAM
        LD      D,A         ; STORE IN REG D
        LD      A,(_SMOPRT) ; GET PORT FROM SAVED PARAMETER
        LD      C,A         ; AND STORE IN REG C


_SMOMXL:LD      A,(HL)      ; LOAD
        OUT     (C),A       ; AND WRITE IT OUT TO SPECIFIED PORT
        PUSH    BC          ; SAVE REG B COUNT
        LD      B,D         ; COPY DELAY COUNT INTO REG B AS CALL PARAMETER
        CALL    DLY25B      ; AND DELAY
        POP     BC          ; RESTORE ONGOING COUNT INTO REG B
        INC     HL          ; POINT TO NEXT DATUM
        DJNZ    _SMOMXL     ; LOOP UNTIL WE'VE WRITTEN ALL

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"  MULTI-TRANSFER OPERATION COMPLETED",CR,LF,CR,LF,NULL

        RET

        ;; ONE-SHOT OUTPUT MODE
_SMOOSM:LD      A,(_SMOPRT) ; GET PORT FROM SAVED PARAMETER
        LD      C,A         ; AND STORE IN REG C
        LD      A,(_SMOCV)  ; LOAD VALUE TO OUTPUT INTO ACCUMULATOR
        OUT     (C),A       ; AND WRITE IT OUT TO SPECIFIED PORT

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"  SINGLE TRANSFER OPERATION COMPLETED",CR,LF,CR,LF,NULL

        RET


_SMOCV: .DB     1           ; COUNT OF BYTES TO WRITE OR VALUE TO OUTPUT ONE-SHOT
_SMODLY:.DB     1           ; DELAY BETWEEN WRITES
_SMOPRT:.DB     1           ; OUTPUT PORT
_SMOSAD:.DW     1           ; STARTING ADDRESS AT WHICH TO SAVE INPUT DATA

        ;------ END SMCMD_O --------------------------------
