        .PHASE BBIOS        ; ASSEMBLE RELATIVE TO EXECUTION LOCATION
BBIOSS: .EQU    $           ; BOARD BIOS START. TAG FOR RELOC & SIZE CALCS

;; -------------------------------------------------------------
;; CONSOLE UTILITY ROUTINES
;; -------------------------------------------------------------

        ;; CONSOLE CHARACTER INPUT
        ;;  WAITS FOR DATA AND RETURNS CHARACTER IN A
        ;; -------------------------------------------------------------
CONCHR: IN      A,(SIOAC)   ; READ STATUS
        BIT     0,A         ; DATA AVAILABLE?
        JR      Z,CONCHR    ; NO DATA, WAIT
        IN      A,(SIOAD)   ; READ DATA
        AND     7FH         ; MASK BIT 7    TODO:  EVAL IMPLICATIONS FOR X-MODEM, ETC..
        RET

        ;; CONSOLE LINE INPUT
        ;;  RECEIVES TTY INPUT INTO A USER-PROVIDED LINE BUFFER UP TO N CHARS OR CARRIAGE RETURN
        ;;
        ;; PARAMS
        ;;  HL = ADDRESS OF LINE BUFFER START
        ;;  B  = MAX CHARS <= LINE BUFFER SIZE
        ;;
        ;; RETURNS
        ;;  A = NUMBER OF CHARS READ
CONLIN: .EQU    $           ;; TODO: TEST CONLIN

        ;; VERIFY NON-ZERO BUFFER SIZE
        LD      A,B
        CP      0
        RET     Z           ; B WAS 0 SO RETURN 0 CHARACTERS READ

        ;; PRESERVE ORIGINAL REQUESTED READ COUNT
        PUSH    BC          ; TO PRESERVE ORIGINAL C
        LD      C,B

        ;; READ 'B' COUNT OF CHARACTERS
_CLGTC: IN      A,(SIOAC)   ; READ STATUS
        BIT     0,A         ; DATA AVAILABLE?
        JR      Z,_CLGTC    ; NO DATA, WAIT
        IN      A,(SIOAD)   ; READ DATA
        AND     7FH         ; MASK BIT 7
        LD      (HL),A      ; SAVE CHARACTER TO BUFFER              TODO: DECIDE IF WE SHOULD DISCARD CR OR KEEP
        CP      CR          ; IS CHARACTER A CARRIAGE RETURN?
        JR      Z,_CLCR     ; YES
        INC     HL          ; NO - POINT HL TO NEXT BUFFER BYTE
        DJNZ    _CLGTC      ; DECREMENT COUNT REMAINING AND READ AGAIN

        ;; READ FULL BUFFER
        LD      A,B         ; REPORT THAT WE READ FULL BUFFER
        POP     BC          ; RESTORE ORIGINAL BC (FOR C)
        RST     08H         ;                                           <-- DEBUG / REMOVE
        RET

        ;; DETECTED CARRIAGE RETURN PRESS
_CLCR:  DEC     B           ; FINAL DECREMENT TO B TO REFLECT CHAR READ
        LD      A,C         ; GET ORIGINAL READ COUNT
        SUB     B           ; SUBTRACT DOWNCOUNT TO REPORT HOW MANY CHARS WE ACTUALLY READ
        POP     BC          ; RESTORE ORIGINAL BC (FOR C)
        RST     08H         ;                                           <-- DEBUG / REMOVE
        RET

        ;; CONSOLE CHARACTER OUTUT BLOCKING
        ;;  CONOTW - CHECKS CTS LINE AND XMITS CHARACTER IN C
        ;;            WHEN CTS IS ACTIVE
        ;; -------------------------------------------------------------
CONOTW: PUSH    AF          ; SAVE ACCUMULATOR AND FLAGS
        LD      A,10H       ; SIO HANDSHAKE RESET DATA
        OUT     (SIOAC),A   ; UPDATE HANDSHAKE REGISTER
        IN      A,(SIOAC)   ; READ STATUS
        BIT     5,A         ; CHECK CTS BIT
        JR      Z,CONOTW    ; WAIT UNTIL CTS IS ACTIVE
        JR      _CNOT1      ; FALL-THRU TO CONOUT BUT DON'T PUSH AF AGAIN

        ;; CONSOLE CHARACTER OUTUT NON-BLOCKING
        ;;  CONOUT - NON-BLOCKING XMIT OF CHARACTER IN C
        ;;            (IGNORES CTS)
        ;; -------------------------------------------------------------
CONOUT: PUSH    AF          ; SAVE ACCUMULATOR AND FLAGS
_CNOT1: IN      A,(SIOAC)   ; READ STATUS
        BIT     2,A         ; XMIT BUFFER EMPTY?
        JR      Z,CONOUT    ; NO, WAIT UNTIL EMPTY
        LD      A,C         ; CHARACTER TO A
        OUT     (SIOAD),A   ; OUTPUT DATAL
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
BBIOSE: .EQU    $               ; BOARD BIOS END. TAG FOR RELOC & SIZE CALCS
BBSIZ:  .EQU    BBIOSE-BBIOSS   ; SIZE OF BOARD BIOS CODE
        .DEPHASE
