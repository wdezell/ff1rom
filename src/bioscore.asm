#IFNDEF bioscore_asm        ; TASM-specific guard
#DEFINE bioscore_asm  1

.NOLIST
;;  USAGE:  INLINE INCLUSION
;;  DEPS:   HWDEFS.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BIOS_CORE
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
        ;;          0 - EXTERNAL AUXILLIARY CLOCK, 3.6864 MHZ  (SHORT JP7 PINS 1 & 2)
        ;;          1 - INTERNAL SYSTEM CLOCK, 6.144 MHZ       (SHORT JP7 PINS 2 & 3)
        ;;
        ;; NOTE : FOR 4 MHZ INTERNAL SYSTEM CLOCK AN EXTERNAL AUX CLOCK *SHOULD* BE USED (SW 3 = 0)
        ;;        BECAUSE A 4 MHZ COUNT DOESN'T DIVIDE CLEANLY ENOUGH TO HIT MOST BAUDRATES
        ;;        WITHOUT A SIGNIFICANT MARGIN OF ERROR.
        ;;
        IN      A,(SYSCFG)  ; READ CONFIG SWITCH
        BIT     3,A         ; IS BIT 3 SET?
        JR      NZ,_INCLK   ; YES - SETUP FOR INTERNAL SYSTEM CLOCK TIMING SOURCE
        LD      L,12        ; NO -- SET TC FOR EXTERNAL CLOCK
        JR      _CALSB
_INCLK: LD      L,20        ; SET TC FOR INTERNAL CLOCK
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

        ;; CONSOLE CHARACTER INPUT
        ;;  WAITS FOR DATA AND RETURNS CHARACTER IN A
        ;; -------------------------------------------------------------
CONIN:  IN      A,(SIOAC)   ; READ STATUS
        BIT     0,A         ; DATA AVAILABLE
        JR      Z,CONIN     ; NO DATA, WAIT
        IN      A,(SIOAD)   ; READ DATA
        AND     7FH         ; MASK BIT 7 (JUNK)                                 <-- TBD
        RET

        ;; CONSOLE CHARACTER OUTUT
        ;;  CONOTW - CHECKS CTS LINE AND XMITS CHARACTER IN C
        ;;            WHEN CTS IS ACTIVE
        ;;  CONOUT - NON-BLOCKING XMIT OF CHARACTER IN C
        ;;            (IGNORES CTS)
        ;; -------------------------------------------------------------
CONOTW: LD      A,10H       ; SIO HANDSHAKE RESET DATA
        OUT     (SIOAC),A   ; UPDATE HANDSHAKE REGISTER
        IN      A,(SIOAC)   ; READ STATUS
        BIT     5,A         ; CHECK CTS BIT
        RST     08H         ;                                                         <-- DEBUG REMOVE
        JR      Z,CONOTW    ; WAIT UNTIL CTS IS ACTIVE
        RST     08H         ;                                                         <-- DEBUG REMOVE
CONOUT: IN      A,(SIOAC)   ; READ STATUS
        BIT     2,A         ; XMIT BUFFER EMPTY?
        JR      Z,CONOUT    ; NO, WAIT UNTIL EMPTY
        LD      A,C         ; CHARACTER TO A
        OUT     (SIOAD),A   ; OUTPUT DATA
        RST     08H         ;                                                         <-- DEBUG REMOVE
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

        ;; IN-LINE PRINT ROUTINE
        ;;  PRINT NULL-TERMINATED STRING IMMEDIATELY FOLLOWING SUBROUTINE CALL.
        ;;  STACK RETURN ADDRESS IS ADJUSTED TO BYTE FOLLOWING TERMINATING NULL.
        ;;
        ;; REGISTERS AFFECTED:  NONE
        ;; -------------------------------------------------------------
INLPRT: EX      (SP),HL     ; NEXT BYTE AFTER CALL NOT RETURN ADDR BUT STRING
        CALL    WRSTRZ      ; HL NOW POINTS TO STRING; PRINT AS USUAL
        INC     HL          ; ADJUST HL ONE BYTE BEYOND NULL TERMINATOR
        EX      (SP),HL     ; PUT HL BACK ON STACK AS ADJUSTED RETURN ADDRESS
        RET

        ;; PRINT NULL-TERMINATED STRING POINTED TO BY HL REGISTER PAIR
        ;;  HL = START  ADDRESS OF STRING
        ;;
        ;;  REGISTERS AFFECTED:  HL IS LEFT POINTING TO NULL TERMINATOR CHARACTER
        ;;                        AS REQUIRED BY INLPRT
        ;; -------------------------------------------------------------
WRSTRZ: PUSH    AF          ; SAVE AFFECTED REGS
        PUSH    BC
_WRGTC: LD      A,(HL)      ; GET CHAR
        CP      0           ; IS CHAR NULL END-OF-STRING DELIM ?
        JP      Z,_WRDON    ; YES, DONE
        LD      C,A         ; NO, SEND TO CHAROUT ROUTINE
        CALL    CONOUT
        INC     HL          ; GET NEXT CHARACTER
        JP      _WRGTC
_WRDON: POP     BC          ; RESTORE AFFECTED REGS
        POP     AF
        RET

        ;; SEND VT-52 SCREEN CLEAR COMMAND SEQUENCE
        ;;  REGISTERS AFFECTED:  HL
        ;; -------------------------------------------------------------
VTCLS:  .EQU    $
        LD      HL,(_VTCL)
        CALL    WRSTRZ
        RET
_VTCL:  .DB 1BH, 'H', 1BH, 'J', 00H

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
        ;;    MHZ   38400     19200     9600     4800     2400     1800     1200      600
        ;;  ------  ------   ------     ----     ----     ----     ----     ----     ----
        ;;  3.6864      *3       *6      *12      *24      *48      *64      *96     *192
        ;;  4.0000     n/a      n/a       13       26       52       69      104      208
        ;;  6.1440      *5      *10      *20      *40      *80      107     *160      n/a

        ;; INIT CTC CHANNEL 0 OUTPUT - SERIAL CHANNEL "A" BAUD RATE CLOCK
        LD      A,H                     ; GET PORT FROM PARAMETER H INTO C
        LD      C,A
        LD      A,CTCRST+CTCCTL+CTCCTR+CTCTC ; RESET, IS CONTROL WORD, COUNTER MODE, TC FOLLOWS
        OUT     (C),A
        OUT     (C),L                   ; TC VIA PARAMETER
        RST     08H         ;                                                         <-- DEBUG REMOVE
        RET

;; -------------------------------------------------------------
;; BASIC MATH ROUTINES
;; -------------------------------------------------------------

        ;; TO-DO:  8-BIT MULTIPLY

        ;; TO-DO:  16-BIT DIVIDE

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

;; -------------------------------------------------------------
;; USEFUL CONSTANTS
;; -------------------------------------------------------------
        ;; STATIC DATA DEFINITIONS
CR:     .EQU    0DH             ; ASCII CARRIAGE RETURN
LF:     .EQU    0AH             ; ASCII LINE FEED
ESC:    .EQU    1BH             ; ASCII ESCAPE CHARACTER
CRLFZ:  .TEXT   "\n\r\000"

        ;; -------------------------------------------------------------
#ENDIF
