BBIOSS: .EQU    $           ; BOARD BIOS START. TAG FOR RELOC & SIZE CALCS
        .PHASE BBIOS        ; ASSEMBLE RELATIVE TO EXECUTION LOCATION

;; -------------------------------------------------------------
;; CONSOLE UTILITY ROUTINES
;; -------------------------------------------------------------

        ;; CONSOLE CHARACTER INPUT
        ;;  WAITS FOR DATA AND RETURNS CHARACTER IN A
        ;; -------------------------------------------------------------
CONCIN: IN      A,(SIOAC)   ; READ STATUS
        BIT     0,A         ; DATA AVAILABLE?
        JR      Z,CONCIN    ; NO DATA, WAIT
        IN      A,(SIOAD)   ; READ DATA
        AND     7FH         ; MASK BIT 7    TODO:  EVAL IMPLICATIONS FOR X-MODEM, ETC..

IF 0    ; echo caharcter read (not sure this is right place to do this)
        PUSH    BC          ; PRESEVE C
        LD      C,A
        CALL    CONOUT
        POP     BC
ENDIF
        RET

        ;; CONSOLE LINE INPUT
        ;;  RETURNS TTY INPUT TO A USER-PROVED BUFFER AFTER N CHARS OR CARRIAGE RETURN
        ;;
        ;;  SUPPORTS ONLY BASIC CMD-LINE EDITING VIA BACKSPACE/CTRL-H
        ;;
        ;; PARAMS
        ;;  HL = ADDRESS OF USER RETURN BUFFER START
        ;;  B  = SIZE OF USER RETURN BUFFER OR MAX CHARS TO READ, MUST BE LESS THAN < 256
        ;;
        ;; RETURNS
        ;;  A = NUMBER OF CHARS PLACED INTO PROVIDED USER BUFFER
        ;;
        ;; NOTE: INPUT IS READ TO AN INTERMEDIATE BUFFER (CONBUF) AND THEN COPIED TO THE
        ;;       USER-PROVIDED BUFFER UPON INPUT COMPLETION.  THIS MINOR INEFFICIENCY IS TO
        ;;       SIMPLIFY LATER CONVERSION FROM POLLED TO INTERRUPT-DRIVEN (IM2) SERIAL I/O
        ;; ---------------------------------------------------------------------------------
CONLIN: .EQU    $

        ;; VERIFY NON-ZERO BUFFER SIZE
        LD      A,B
        CP      0
        RET     Z           ; B WAS 0 SO RETURN 0 CHARACTERS READ

        ;; SAVE REGS
        PUSH    BC          ; B IS A PARAM BUT PRESERVE C
        PUSH    DE          ; NEED TO USE AS RETURN COPY DEST ADDRESS

        ;; SETUP
        EX      DE,HL       ; STORE RETURN BUFFER ADDRESS IN DE
        LD      C,B         ; PRESERVE ORIGINAL READ COUNT
        LD      HL,CONBUF   ; POINT TO INTERMEDIATE SYSTEM BUFFER

_CLGTC: CALL    CONCIN      ; READ A CHARACTER INTO A
        LD      C,A         ; COPY TO C FOR ECHO
        CALL    CONOUT      ; ECHO              TODO - FIGURE OUTHOW TO GET DESTRUCTIVE RUB FOR BS/DEL

        CP      CR          ; IS CHARACTER A CARRIAGE RETURN?
        JR      Z,_CLCR     ; YES

        CP      BS          ; IS IT A BACKSPACE?
        JR      Z,_CLBS     ; YES

        LD      (HL),A      ; SAVE IT TO BUFFER
        INC     HL          ; POINT HL TO NEXT BUFFER BYTE
        DJNZ    _CLGTC      ; DECREMENT COUNT REMAINING AND READ AGAIN

        LD      A,C         ; REPORT THAT WE READ A FULL BUFFER
        JR      _CLCPY

        ;; BACKSPACE PRESSED - DISCARD BS AND REMOVE LAST BUFFER ENTRY
_CLBS:  LD      A,C         ; EDGE CASE - GET ORIG READ COUNT
        CP      B           ; IS THIS THE FIRST CHAR READ? E.G., NOTHING TO BACKSPACE OVER?
        JR      Z,_CLGTC    ; YES - GO BACK TO READ LOOP
        DEC     HL          ; NO - MOVE BUFFER POINTER BACK BY ONE (DISCARD LAST CHAR)
        INC     B           ; ADJUST READ COUNTDOWN TO COMPENSATE
        JR      _CLGTC      ; READ ANOTHER

        ;; CARRIAGE RETURN PRESSED
_CLCR:  LD      A,B         ; REPORT CHARS READ BEFORE CR PRESSED

        ;; COPY COLLECTED INPUT TO USER BUFFER
_CLCPY: LD      HL,CONBUF   ; SRC = INTERMEDIATE BUFFER, DEST = ADDR SAVED INTO DE ABOVE
        LD      C,0         ; NO HIGH BYTE SINCE < 256 MAX
        LD      B,A         ; COUNT OF BYTES READ
        LDIR                ; COPY IT

        ;; RESTORE WORK REGS AND RETURN
        POP     DE
        POP     BC
        RET

        ;; CONSOLE CHARACTER OUTUT BLOCKING
        ;;  CONOTW - CHECKS CTS LINE AND XMITS CHARACTER IN C
        ;;            WHEN CTS IS ACTIVE
        ;; -------------------------------------------------------------
CONOTW: PUSH    AF          ; SAVE ACCUMULATOR AND FLAGS
_CNOW1: LD      A,10H       ; SIO HANDSHAKE RESET DATA
        OUT     (SIOAC),A   ; UPDATE HANDSHAKE REGISTER
        IN      A,(SIOAC)   ; READ STATUS
        BIT     5,A         ; CHECK CTS BIT
        JR      Z,_CNOW1    ; WAIT UNTIL CTS IS ACTIVE
        JR      _CNOT1      ; FALL-THRU TO CONOUT BUT DON'T PUSH AF AGAIN

        ;; CONSOLE CHARACTER OUTUT NON-BLOCKING
        ;;  CONOUT - NON-BLOCKING XMIT OF CHARACTER IN C
        ;;            (IGNORES CTS)
        ;; -------------------------------------------------------------
CONOUT: PUSH    AF          ; SAVE ACCUMULATOR AND FLAGS
_CNOT1: IN      A,(SIOAC)   ; READ STATUS
        BIT     2,A         ; XMIT BUFFER EMPTY?
        JR      Z,_CNOT1    ; NO, WAIT UNTIL EMPTY
        LD      A,C         ; CHARACTER TO A
        OUT     (SIOAD),A   ; OUTPUT CHARACTER
        POP     AF          ; RESTORE ACCUMULATOR AND FLAGS
        RET

        ;; CONSOLE RECEIVE STATUS (POLLED)
        ;;  CHECKS SIO/DART TO SEE IF A CHARACTER IS AVAILABLE
        ;;
        ;; RETURNS: A = FFH (Z = 0)  CHAR AVAILABLE
        ;;          A = 00H (Z = 1)  NO CHAR AVAILABLE
        ;; -------------------------------------------------------------
CONRXS: IN      A,(SIOAC)   ; READ STATUS
        BIT     0,A         ; BIT 0 = DATA AVAILABLE
        JR      Z,_NOCHR    ; NO DATA AVAILABLE
        LD      A,0FFH      ; DATA AVAILABLE, SET A = FFH
        AND     A           ; Z = 0
        RET
_NOCHR: XOR     A           ; A = 0, Z = 1
        RET

;; -------------------------------------------------------------
;; REAL-TIME CLOCK, CALENDAR, AND TIME-OF-DAY UTILITY ROUTINES
;; -------------------------------------------------------------

        ;; TO-DO ONCE WE HAVE IMPLEMENTED OUR HARDWARE


;; -------------------------------------------------------------
;; MASS STORAGE UTILITY ROUTINES (DISK)
;; -------------------------------------------------------------

        ;; TO-DO ONCE WE HAVE IMPLEMENTED OUR HARDWARE


;; -------------------------------------------------------------
;; MISCELLANEOUS UTILITY
;; -------------------------------------------------------------

        ;; "MATHEWS SAVE REGISTER ROUTINE"
        ;;  FROM ZILOG MICROPROCESSOR APPLICATIONS REFERENCE BOOK VOLUME 1, 2-18-81
        ;;
        ;; SAVE AND AUTOMATICALLY RESTORE ALL REGISTERS AND FLAGS IN ANY SUBROUTINE
        ;;  WITH JUST A SINGLE 'CALL SAVE' AT ROUTINE START
SAVE:   EX      (SP),HL     ; SP = HL
        PUSH    DE          ;      DE
        PUSH    BC          ;      BC
        PUSH    AF          ;      AF
        PUSH    IX          ;      IX
        PUSH    IY          ;      IY
        CALL    _GO         ;      PC
        POP     IY
        POP     IX
        POP     AF
        POP     BC
        POP     DE
        POP     HL
        RET
_GO:    JP      (HL)

        ;; VARIATION FOR USE IN INTERRUPT SERVICE ROUTINES
SAVEI:  EX      (SP),HL     ; SP = HL
        PUSH    DE          ;      DE
        PUSH    BC          ;      BC
        PUSH    AF          ;      AF
        PUSH    IX          ;      IX
        PUSH    IY          ;      IY
        CALL    _GOI        ;      PC
        POP     IY
        POP     IX
        POP     AF
        POP     BC
        POP     DE
        POP     HL
        EI
        RETI
_GOI:   JP      (HL)

        .DEPHASE
BBIOSE: .EQU    $               ; BOARD BIOS END. TAG FOR RELOC & SIZE CALCS
BBSIZ:  .EQU    BBIOSE-BBIOSS   ; SIZE OF BOARD BIOS CODE

;; -------------------------------------------------------------
