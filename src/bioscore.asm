;; -------------------------------------------------------------
;; CONSOLE UTILITY ROUTINES
;; -------------------------------------------------------------

        ;; BASIC CONSOLE INITIALIZATION
        ;;  SIO CHANNEL A WILL BE CONFIGURED TO 9600-N-8-1 FOR TX &
        ;;  SIMPLE POLLED-MODE RX.  MODE-SPECIFIC BOOT INITIALIZERS CAN
        ;;  RECONFIGURE IF NEEDED.
        ;; -------------------------------------------------------------
CONINIT:    .EQU    $

        ;; SET BAUD RATE FOR SIO CHANNEL A
        ;; READ SYSCONFIG SWITCH 3 FOR BAUDRATE TIMING SOURCE
        ;;  7 6 5 4 3 2 1 0
        ;;  X X X X | X X X
        ;;          1 - EXTERNAL AUXILLIARY CLOCK @ 3.6864 MHZ  (SHORT JP7 PINS 1 & 2)
        ;;          0 - INTERNAL SYSTEM CLOCK @ 6.144 MHZ       (SHORT JP7 PINS 2 & 3)
        ;;
        ;; NOTE : FOR 4 MHZ INTERNAL SYSTEM CLOCK AN EXTERNAL AUX CLOCK *SHOULD* BE USED (SW 3 = 1)
        ;;        BECAUSE A 4 MHZ COUNT DOESN'T DIVIDE CLEANLY ENOUGH TO HIT MOST BAUDRATES
        ;;        WITHOUT A SIGNIFICANT MARGIN OF ERROR.
        ;;
        IN      A,(SYSCFG)  ; READ CONFIG SWITCH
        BIT     3,A         ; IS BIT 3 SET?
        JR      NZ,_EXCLK   ; YES - SETUP FOR EXTERNAL CLOCK TIMING SOURCE
        LD      L,20        ; NO -- SET TC FOR INTERNAL SYSTEM CLOCK
        JR      _CALSB
_EXCLK: LD      L,12        ; SET TC FOR EXTERNAL CLOCK
_CALSB: LD      H,CTCCH0    ; SIO CHANNEL A DRIVEN THROUGH CTC CH0
        CALL    SETBDR      ; CALL SET BAUDRATE SUBROUTINE

        ;; SET PROTOCOL PARAMS FROM TABLE
        LD      C,SIOAC     ; C = SIO CHANNEL "A" CONTROL PORT
        LD      HL,_SPTAS   ; HL = START OF PARAMETERS TABLE
        LD      B,_SPTAE-_SPTAS ; B = LENGTH IN BYTES OF PARAMETER TABLE
        OTIR                ; WRITE TABLE TO SIO CHANNEL CONTROL PORT
        RET

        ;; SIO SERIAL CHANNEL A INITIALIZATION PARAMETERS TABLE
_SPTAS:
        .DB     10H         ; RESET HANDSHAKE COMMAND
        .DB     30H         ; RESET ERROR FLAGS COMMAND
        .DB     18H         ; RESET CHANNEL COMMAND
        .DB     04H         ; SELECT REGISTER 4
        .DB     46H         ; NO PARITY, 1 STOP BIT, 16X CLOCK
        .DB     05H         ; SELECT REGISTER 5
        .DB     0EAH        ; DTR & RTS ON, XMIT 8 DATA BITS, XMIT ENABLE
        .DB     03H         ; SELECT REGISTER 3
        .DB     0C1H        ; RCV 8 DATA BITS, ON
        .DB     01H         ; SELECT REGISTER 1
        .DB     00H         ; NO INTERRUPTS
_SPTAE: .EQU    $

CONRLS: .EQU    $           ; START OF RELOCATABLE CONSOLE I/O ROUTINES
                            ;  NB - ONCE RELOCATED ACCESS WILL HAVE TO BE VIA BASE+OFFSET INDEX
                            ;       OR SOME OTHER MEANS OF INDIRECTION AS THESE ABSOLUTE LABELS
                            ;       WILL STILL REFER TO ORIGINAL ADDRESSES

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

CONRLE: .EQU    $           ; END OF RELOCATABLE CONSOLE I/O ROUTINES

        ;; IN-LINE PRINT ROUTINE
        ;;  PRINT NULL-TERMINATED STRING IMMEDIATELY FOLLOWING SUBROUTINE CALL.
        ;;  STACK RETURN ADDRESS IS ADJUSTED TO BYTE FOLLOWING TERMINATING NULL.
        ;;
        ;; REGISTERS AFFECTED:  NONE
        ;; -------------------------------------------------------------
PRINL:  EX      (SP),HL     ; NEXT BYTE AFTER CALL NOT RETURN ADDR BUT STRING
        CALL    PRSTRZ      ; HL NOW POINTS TO STRING; PRINT AS USUAL
        INC     HL          ; ADJUST HL ONE BYTE BEYOND NULL TERMINATOR
        EX      (SP),HL     ; PUT HL BACK ON STACK AS ADJUSTED RETURN ADDRESS
        RET

        ;; PRINT NULL-TERMINATED STRING POINTED TO BY HL REGISTER PAIR
        ;;  HL = START  ADDRESS OF STRING
        ;;
        ;;  REGISTERS AFFECTED:  HL IS LEFT POINTING TO NULL TERMINATOR CHARACTER
        ;;                        AS REQUIRED BY INLPRT
        ;; -------------------------------------------------------------
PRSTRZ: PUSH    AF          ; SAVE AFFECTED REGS
        PUSH    BC
_PRGTC: LD      A,(HL)      ; GET CHAR
        CP      0           ; IS CHAR NULL END-OF-STRING DELIM ?
        JP      Z,_PRDON    ; YES, DONE
        LD      C,A         ; NO, SEND TO CHAROUT ROUTINE
        CALL    CONOUT
        INC     HL          ; GET NEXT CHARACTER
        JP      _PRGTC
_PRDON: POP     BC          ; RESTORE AFFECTED REGS
        POP     AF
        RET

        ;; SEND VT-COMPATIBLE SCREEN CLEAR COMMAND SEQUENCE
        ;;  REGISTERS AFFECTED:  HL
        ;; -------------------------------------------------------------
VTCLS:  .EQU    $
        LD      HL,_VTCL
        CALL    PRSTRZ
        RET
_VTCL:  .DB 1BH, '[', '2', 'J', 00H

;; -------------------------------------------------------------
;; REAL-TIME CLOCK, CALENDAR, AND TIME-OF-DAY UTILITY ROUTINES
;; -------------------------------------------------------------

        ;; TO-DO ONCE WE HAVE IMPLEMENTED OUR HARDWARE


;; -------------------------------------------------------------
;; MASS STORAGE UTILITY ROUTINES (DISK)
;; -------------------------------------------------------------

        ;; TO-DO ONCE WE HAVE IMPLEMENTED OUR HARDWARE


;; -------------------------------------------------------------
;; SERIAL UTILITY ROUTINES
;; -------------------------------------------------------------

SETBDR: .EQU    $
        ;; SET SIO CHANNEL A OR B BAUD RATE CLOCK
        ;;  PARAMETERS: H   = CTC CHANNEL CONTROL REGISTER
        ;;              L   = TIMING CONSTANT AS PER TABLE BELOW
        ;;
        ;;  AFFECTED:   NONE
        ;;
        ;;  FIREFLY USES CTC CHANNEL 0 TO SCALE A USER-SELECTABLE TIMING SOURCE
        ;;  TO DRIVE SIO CH A RX/TX CLOCKS.  CTC CHANNEL 1 IS USED FOR SIO CHANNEL B.
        ;;  TIMING SOURCE IS JUMPER SELECTABLE OPTION OF SYSTEM CLOCK OR AUXILLIARY
        ;;  OSCILLATOR. THE TABLE BELOW IS BASED ON A 3.6864 MHZ AUXILLARY OSC.
        ;;
        ;;  USEFUL FORMULAE FOR 16X CLOCK RATES USING CTC IN COUNTER MODE:
        ;;    BAUD = CLK / 2 / 16 / TC
        ;;    TC =  CLK / ( 32 X BAUD )
        ;;
        ;;  TC VALUES FOR COMMON BAUD RATES AT COMMON CLOCK RATES FOLLOW.  VALUES
        ;;  MARKED BY ASTERISK ARE DESIRABLE AS THEY EXACTLY YIELD DESIRED BAUD
        ;;  RATES WITH 0% ERROR.
        ;;
        ;;  CLOCK   BAUD RATES
        ;;    MHZ   57600   38400   19200   9600   4800   2400   1800   1200    600
        ;;  ------  -----  ------   -----   ----   ----   ----   ----   ----   ----
        ;;  3.6864     *2      *3      *6    *12    *24    *48    *64    *96   *192
        ;;  4.0000    n/a     n/a     n/a     13     26     52     69    104    208
        ;;  6.1440    n/a      *5     *10    *20    *40    *80    107   *160    n/a

        ;; INIT CTC CHANNEL 0 OUTPUT - SERIAL CHANNEL "A" BAUD RATE CLOCK
        LD      A,H                     ; GET PORT FROM PARAMETER H INTO C
        LD      C,A
        LD      A,CTCRST+CTCCTL+CTCCTR+CTCTC ; RESET, IS CONTROL WORD, COUNTER MODE, TC FOLLOWS
        OUT     (C),A
        OUT     (C),L                   ; TC VIA PARAMETER
        RET

;; -------------------------------------------------------------
;; BASIC MATH ROUTINES
;; -------------------------------------------------------------

        ;; TODO:  8-BIT MULTIPLY

        ;; TODO:  16-BIT DIVIDE

;; -------------------------------------------------------------
;; MISCELLANEOUS UTILITY
;; -------------------------------------------------------------
        ;; -------------------------------------------------------------
        ;; TABLE DISPATCH -- ROUTE EXECUTION TO TABLE SUBROUTINE AT INDEX
        ;;
        ;;   USAGE: A       TABLE INDEX, 0-BASED
        ;;          B       NUMBER OF TABLE ENTRIES
        ;;          HL      ADDRESS OF JUMPT TABLE
        ;;
        ;;   ALTERS: AF
        ;;
        ;; ADAPTED FROM LANCE LEVANTHAL '9H JUMP TABLE (JTAB)'
        ;; -------------------------------------------------------------
        ;;
TABDSP: ;; EXIT WITH CARRY SET IF ROUTINE NUMBER IS INVALID,
        ;; THAT IS, IF IT IS TOO LARGE FOR TABLE (> _NMSUB-1)
        CP      B           ; COMPARE INDEX, TABLE SIZE
        CCF                 ; COMPLIMENT CARRY FOR ERROR INDICATOR
        RET     C           ; RETURN IF ROUTINE NUMBER TOO LARGE
                            ;  WITH CARRY SET

        ;; INDEX INTO TABLE OF WORD-LENGTH ADDRESSES
        ;; LEAVE REGISTER PAIRS UNCHANGED SO THEY CAN BE USED FOR PASSING PARAMS
        PUSH    HL          ; SAVE HL
        ADD     A,A         ; DOUBLE INDEX FOR WORD-LENGTH ENTRIES
        ADD     A,L         ; TO AVOID DISTURBING ANOTHER REGISTER PAIR
        LD      L,A
        LD      A,0
        ADC     A,H
        LD      H,A         ; ACCESS ROUTINE ADDRESS

        ;; OBTAIN ROUTINE ADDRESS FROM TABLE AND TRANSFER CONTROL TO IT,
        ;;  LEAVING ALL REGISTER PAIRS UNCHANGED
        LD      A,(HL)      ; MOVE ROUTINE ADDRESS TO HL
        INC     HL
        LD      H,(HL)
        LD      L,A
        EX      (SP),HL     ;RESTORE OLD HL, PUSH ROUTINE ADDRESS

        RET                 ; JUMP TO ROUTINE

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

;; -------------------------------------------------------------
;; USEFUL CONSTANTS
;; -------------------------------------------------------------
        ;; STATIC DATA DEFINITIONS
CR:     .EQU    0DH             ; ASCII CARRIAGE RETURN
LF:     .EQU    0AH             ; ASCII LINE FEED
ESC:    .EQU    1BH             ; ASCII ESCAPE CHARACTER
CRLFZ:  .TEXT   "\n\r\000"

        ;; -------------------------------------------------------------
