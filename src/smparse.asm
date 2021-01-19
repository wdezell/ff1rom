
        ;; -------------------------------------------------------------
        ;; USER PROMPT AND INPUT-PARSING LOGIC
        ;;
        ;; PARSING DECOMPOSES THE SPACE-SEPARATED USER INPUT IN CONBUF
        ;; INTO FIELD COMPONENTS AND STORES INTO BUFFERS SMP0-SMP6.
        ;;
        ;; PARSING CONCLUDES WHEN AT LEAST ONE NON-BLANK CHARACTER HAS
        ;; BEEN STORED INTO SMP0.
        ;;
        ;; UNUSED COMPONENT BUFFER SPACE IS ZERO-FILLED.
        ;;
        ;; -------------------------------------------------------------

        ;; PROMPT AND PARSE INPUT
SMPRAP: .EQU    $

        ;; DISPLAY PROMPT
        CALL    PRINL
        .TEXT   CR,LF,"MON>",NULL

        ; CLEAR BUFFERS
        CALL    SMCLRB

        ;; GET USER INPUT
        LD      HL,CONBUF   ; RETURN BUFFER
        LD      B,CNBSIZ    ; BUFFER SIZE
        CALL    CONLIN      ; COUNT OF CHARS READ RETURNED IN A
        CP      0           ; NO CHARS READ (USER JUST PRESSED ENTER)
        JP      Z,SMPRAP    ; NO ENTRY - READ AGAIN
        LD      B,A         ; ELSE SAVE NUMBER OF CHARS IN BUFFER TO B

        ;; PARSE MAIN INPUT BUFFER
        ;;
        ;;  THERE ARE POTENTIALLY 7 FIELDS SEPARATED BY ONE OR MORE SPACES.
        ;;  WE ONLY KNOW FOR SURE THAT THERE IS AT LEAST ONE INPUT CHARACTER AS B > 0 GOT US HERE.
        ;;
        ;;  COPY BYTES L-TO-R INTO DESTINATION BUFFERS FOR FURTHER VALIDATIONS, SWITCHING TO NEW DESTINATION
        ;;  BUFFER AS WE HIT SPACE DELIMITERS.  INITIAL. TRAILING, AND CONSECQUTIVE SPACES ARE IGNORED.
        ;;
        ;; -------------------------------------------------------------
        CALL    SMRSTB      ; RESET TO FIRST TOKEN DESTINATION BUFFER
        LD      HL,CONBUF   ; POINT HL TO START OF USER INPUT BUFFER
        LD      C,' '       ; INIT FLAG TO DISALLOW DESTINATION BUFFER INCREMENT ON INITIAL SPACE(S)
_SMINBP:LD      A,(HL)      ; INSPECT CHARACTER
        CP      ' '         ; IS IT A SPACE?
        JR      NZ,_SMNAS   ; NO - NOT A SPACE
        CALL    SMNXTB      ; YES - SWITCH TO NEXT DESTINATION BUFFER
        INC     HL          ; POINT TO NEXT SOURCE BYTE
        DJNZ    _SMINBP
        RET

_SMNAS: LD      C,A         ; CLEAR CONSECUTIVE-SPACE REF FLAG
        CALL    SMCKBS      ; CHECK THAT INPUT NOT EXCEEDING BUFFER SIZE
        JP      C,SMPFSE    ; FIELD WIDTH EXCEEDS DESTINATION BUFFER -- ERROR BAIL
        LD      (DE),A      ; WRITE DATA TO LOCATION ADDRESSED BY DE
        INC     HL          ; POINT TO NEXT SOURCE BYTE
        INC     DE          ; POINT TO NEXT DESTINATION BYTE
        DJNZ    _SMINBP
        RET


        ;; CHECK THAT INPUT IS NOT EXCEEDING DESTINATION BUFFER SIZE
        ;;  CARRY SET ON EXIT TO INDICATE BOUNDS EXCEEDED
        ;; -------------------------------------------------------------
SMCKBS:.EQU     $
        PUSH    AF
        PUSH    HL
        LD      HL,SMCBCC   ; GET CURRENT BUFFER CHARACTER COUNTER
        INC     (HL)        ; INCREMENT COUNT
        LD      A,SMPMSZ    ; LOAD SIZE LIMIT INTO A
        CP      (HL)        ; IF COUNT > A THEN CARRY = SET
        POP     HL
        POP     AF
        RET


        ;;CLEAR BUFFERS AND WORK VARS (THAT CAN RESET TO ZERO)
        ;; -------------------------------------------------------------
SMCLRB: .EQU    $

        LD      B,SMCLRE-SMCLRS
        LD      HL,SMCLRS   ; START OF CONTIGUOUS GROUP
_SMCB:  LD      (HL),0      ; WRITE A ZERO TO BYTE
        INC     HL          ; POINT TO NEXT
        DJNZ    _SMCB       ; REPEAT UNTIL ALL BYTES ZEROED

        ;; CLEAR CONBUF
        LD      HL,CONBUF
        LD      (HL),0
        LD      DE,CONBUF+1
        LD      BC,CNBSIZ-1
        LDIR

        RET


        ;; NEXT TOKEN DESTINATION BUFFER
        ;;  GET POINTER TO NEXT BUFFER START INTO REG PAIR DE FROM
        ;;  PERSISTENT REFERENCE SMTKSL
        ;; -------------------------------------------------------------
SMNXTB: .EQU    $

        CP      C           ; A CONTAINS ' ' BUT DOES REF REGISTER C? (E.G., BACK-TO-BACK SPACES)
        RET     Z           ; YES - DON'T SWITCH TO NEXT BUFFER, WE'VE ALREADY DONE IT. IGNORE & RETURN.

        PUSH    HL
        LD      HL,SMTKSL   ; POINT HL TO BUFFER SELECTOR
        INC     (HL)        ; INCREMENT SELECTOR TO POINT TO ADDRESS OF NEXT BUFFER IN TABLE
        INC     (HL)        ;  (EACH TABLE ENTRY IS 2 BYTES SO INCREMENT TWICE)
        LD      HL,(SMTKSL) ; HL NOW POINTING TO TABLE ENTRY ROW ADDRESS
        LD      E,(HL)      ; FETCH LOW BYTE OF ADDRESS ENTRY INTO E
        INC     HL          ;
        LD      D,(HL)      ; FETCH HIGH BYTE OF ADDRESS ENTRY INTO D

        LD      HL,SMCBCC   ; RESET CURRENT BUFFER CHARACTER COUNT TO ZERO
        LD      (HL),0
        POP     HL

        LD      C,A         ; RECORD THE SPACE THAT GOT US HERE INTO CONSEQUTIVE-SPACE REF FLAG REGISTER C
        RET


        ;; PARSE ERROR -- FIELD SIZE
        ;; -------------------------------------------------------------
SMPFSE: LD      HL,SMERR02  ; 'PARAM WIDTH' ERROR
        CALL    SMPRSE      ;


        ;; VALIDATION ERROR HANDLER
        ;;  RETURNS WITH CARRY SET SO UPSTREAM CAN ADAPT FLOW AS REQD
        ;; -------------------------------------------------------------
SMPRSE: .EQU    $

        PUSH    HL          ; PRESERVE ERROR MESSAGE PASSED IN HL
        CALL    PRINL       ; DISPLAY ERROR MESSAGE PREAMBLE
        .TEXT   "**ERROR**: ",0

        POP     HL          ; RETRIEVE MESSAGE BODY AND PRINT IT
        CALL    PRSTRZ

        CALL    PRINL       ; WAIT FOR ACKKNOWLEDGEMENT
        .TEXT   HT,"PRESS ANY KEY...",0

        CALL    CONCIN      ; READ A KEY

        SCF                 ; SET CARRY FLAG TO INDICATE ERROR
        RET

        ;; RESET DESTINATION BUFFER AND REG PAIR DE
        ;; -------------------------------------------------------------
SMRSTB: PUSH    HL
        LD      HL,SMP0ADR      ; POINT HL TO *POINTER* TO FIRST BUFFER
        LD      (SMTKSL),HL     ; STORE POINTER INTO SELECTOR
        LD      E,(HL)          ; FETCH LOW BYTE OF ADDRESS ENTRY INTO E
        INC     HL              ;
        LD      D,(HL)          ; FETCH HIGH BYTE OF ADDRESS ENTRY INTO D
        LD      HL, SMCBCC      ; RESET CURRENT BUFFER CHARACTER COUNT TO ZERO
        LD      (HL),0
        POP     HL
        RET


        ;; -- PARSE DESTINATION BUFFER LOOKUP TABLE --
SMTKSL: .DW     0           ; BUFFER SELECTOR (ADDRESS OF DESTINATION BUFFER WE'RE PARSING INTO)
SMP0ADR:.DW     SMP0        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 0
SMP1ADR:.DW     SMP1        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 1
SMP2ADR:.DW     SMP2        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 2
SMP3ADR:.DW     SMP3        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 3
SMP4ADR:.DW     SMP4        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 4
SMP5ADR:.DW     SMP5        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 5
SMP6ADR:.DW     SMP6        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 6
        ;; -- TABLE END --
