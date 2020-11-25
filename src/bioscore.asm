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
        ;;  SIO CHANNEL A WILL BE CONFIGURED TO 9600-E-7-1 FOR TX &
        ;;  SIMPLEPOLLED-MODE RX.  MODE-SPECIFIC BOOT INITIALIZERS CAN
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
        ;; NOTE : FOR 4 MHZ INTERNAL SYSTEM CLOCK AN EXTERNAL AUX CLOCK *MUST* BE USED (SW 3 = 0)
        ;;        BECAUSE A 4 MHZ COUNT DOESN'T DIVIDE CLEANLY ENOUGH TO HIT MOST BAUDRATES
        ;;        WITHOUT A HIGH MARGIN OF ERROR.
        ;;
        PUSH    AF          ; SAVE REGISTERS & FLAGS
        PUSH    BC
        PUSH    HL

        IN      A,(SYSCFG)  ; READ CONFIG SWITCH
        BIT     3,A         ; IS BIT 3 SET?
        JR      NZ,_INCLK   ; YES - SETUP FOR INTERNAL SYSTEM CLOCK TIMING SOURCE
        LD      A,12        ; NO -- SET TC FOR EXTERNAL CLOCK
        JR      _CALSB
_INCLK: LD      A,20        ; SET TC FOR INTERNAL CLOCK
_CALSB: CALL    SETBDA      ; CALL SET BAUDRATE SUBROUTINE FOR SIO CHANNEL A

        ;; SET PROTOCOL PARAMS FROM TABLE
        LD	    C,SIOAC		    ; C = SIO CHANNEL "A" CONTROL PORT
        LD	    HL,_SPTAS	    ; HL = START OF PARAMETERS TABLE
        LD	    B,_SPTAE-_SPTAS	; B = LENGTH IN BYTES OF PARAMETER TABLE
        OTIR			        ; WRITE TABLE TO SIO CHANNEL CONTROL PORT

        POP     HL              ; RESTORE REGISTERS & FLAGS
        POP     BC
        POP     AF

        RET

        ;; SIO SERIAL CHANNEL A INITIALIZATION PARAMETERS TABLE
_SPTAS:
        .DB	    10H		    ; RESET HANDSHAKE COMMAND
        .DB	    30H		    ; RESET ERROR FLAGS COMMAND
        .DB	    18H		    ; RESET CHANNEL COMMAND
        .DB	    04H		    ; SELECT REGISTER 4
        .DB	    47H		    ; EVEN PARITY, 1 STOP BIT, 16X CLOCK
        .DB	    05H		    ; SELECT REGISTER 5
        .DB	    0AAH		; DTR & RTS ON, XMIT 7 DATA BITS, ON
        .DB	    03H		    ; SELECT REGISTER 3
        .DB	    41H		    ; RCV 7 DATA BITS, ON
        .DB	    01H		    ; SELECT REGISTER 1
        .DB	    00H		    ; NO INTERRUPTS
_SPTAE:	.EQU	$

	    ;; CONSOLE CHARACTER INPUT
	    ;;  WAITS FOR DATA AND RETURNS CHARACTER IN A
        ;; -------------------------------------------------------------
CONIN:  IN	    A,(SIOAC)	; READ STATUS
	    BIT	    0,A		    ; DATA AVAILABLE
        JR	    Z,CONIN	    ; NO DATA, WAIT
        IN	    A,(SIOAD)	; READ DATA
        AND	    7FH		    ; MASK BIT 7 (JUNK)
        RET

        ;; CONSOLE CHARACTER OUTUT
        ;; CHECKS CTS LINE AND XMITS CHARACTER IN C WHEN CTS IS ACTIVE
        ;; -------------------------------------------------------------
CONOUT: PUSH	AF
        LD	    A,10H		; SIO HANDSHAKE RESET DATA
        OUT	    (SIOAC),A	; UPDATE HANDSHAKE REGISTER
        IN	    A,(SIOAC)	; READ STATUS
        BIT	    5,A		    ; CHECK CTS BIT
        JR	    Z,CONOUT	; WAIT UNTIL CTS IS ACTIVE
_COUT1:	IN	    A,(SIOAC)	; READ STATUS
        BIT	    2,A		    ; XMIT BUFFER EMPTY?
        JR	    Z,_COUT1	; NO, WAIT UNTIL EMPTY
        LD	    A,C		    ; CHARACTER TO A
        OUT	    (SIOAD),A	; OUTPUT DATA
        POP	    AF
        RET

        ;; CONSOLE RECEIVE STATUS (POLLED)
        ;;  CHECKS SIO/DART TO SEE IF A CHARACTER IS AVAILABLE
        ;;
        ;; RETURNS: A = FFH (Z = 0)  CHAR AVAILABLE
        ;;          A = 00H (Z = 1)  NO CHAR AVAILABLE
        ;; -------------------------------------------------------------
CONRXS: IN	    A,(SIOAC)   ; READ STATUS
	    BIT	    0,A		    ; BIT 0 = DATA AVAILABLE
	    JR	    Z,_NOCHR	; NO DATA AVAILABLE
	    LD	    A,0FFH		; DATA AVAILABLE, SET A = FFH
	    AND	    A		    ; Z = 0
	    RET
_NOCHR:	XOR	    A		    ; A = 0, Z = 1
	    RET

        ;; IN-LINE PRINT ROUTINE
        ;;  PRINT NULL-TERMINATED STRING IMMEDIATELY FOLLOWING SUBROUTINE CALL.
        ;;  STACK RETURN ADDRESS IS ADJUSTED TO BYTE FOLLOWING TERMINATING NULL.
        ;;
        ;; REGISTERS AFFECTED:  NONE
        ;; -------------------------------------------------------------
INLPRT: EX	    (SP),HL		; NEXT BYTE AFTER CALL NOT RETURN ADDR BUT STRING
        CALL	WRSTRZ		; HL NOW POINTS TO STRING; PRINT AS USUAL
        INC	    HL		    ; ADJUST HL ONE BYTE BEYOND NULL TERMINATOR
        EX	    (SP),HL		; PUT HL BACK ON STACK AS ADJUSTED RETURN ADDRESS
        RET

        ;; PRINT NULL-TERMINATED STRING POINTED TO BY HL REGISTER PAIR
        ;;  HL = START  ADDRESS OF STRING
        ;;
        ;;  REGISTERS AFFECTED:  HL IS LEFT POINTING TO NULL TERMINATOR CHARACTER
        ;;                        AS REQUIRED BY INLPRT
        ;; -------------------------------------------------------------
WRSTRZ: PUSH	AF		    ; SAVE AFFECTED REGS
	    PUSH	BC
_WRGTC:	LD	    A,(HL)		; GET CHAR
        CP	    0		    ; IS CHAR NULL END-OF-STRING DELIM ?
        JP	    Z,_WRDON	; YES, DONE
        LD	    C,A		    ; NO, SEND TO CHAROUT ROUTINE
        CALL	CONOUT
        INC	    HL		    ; GET NEXT CHARACTER
        JP	    _WRGTC
_WRDON:	POP	    BC		    ; RESTORE AFFECTED REGS
	    POP	    AF
	    RET

;; -------------------------------------------------------------
;; GENERAL SERIAL UTILITY ROUTINES
;; -------------------------------------------------------------

SETBDA: .EQU    $
        ;; SET SIO A BAUD RATE
        ;;  REGISTERS AFFECTED:  NONE
        ;;
        ;;  FIREFLY USES CTC CHANNEL 0 TO SCALE A USER-SELECTABLE TIMING SOURCE
        ;;  TO DRIVE SIO CH A RX/TX CLOCKS.  TIMING SOURCE IS JUMPER SELECTABLE
        ;;  OPTION OF SYSTEM CLOCK OR INDEPENDENT AUXILLARY OSCILLATOR.
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
        ;;    MHZ    19200     9600     4800     2400     1800     1200      600
        ;;  ------  ------     ----     ----     ----     ----     ----     ----
        ;;  3.6864      *6      *12      *24      *48      *64      *96     *192
        ;;  4.0000     n/a       13       26       52       69      104      208
        ;;  6.1440     *10      *20      *40      *80      107     *160      n/a

        ;; INIT CTC CHANNEL 0 OUTPUT - SERIAL CHANNEL "A" BAUD RATE CLOCK
        PUSH    AF          ; SAVE ACCUMULATOR & FLAGS
        LD	    A,CTCCTR+CTCTC+CTCCTL   ; CTR MODE, TC FOLLOWS, IS CONTROL WORD
        OUT	    (CTCCH0),A
        LD	    A,20		; TC OF 20 = 9600 BAUD W/ 6.144 MHZ SYSTEM CLOCK
        OUT	    (CTCCH0),A
        POP     AF
        RET

;; -------------------------------------------------------------
;; BASIC MATH ROUTINES
;; -------------------------------------------------------------


;; -------------------------------------------------------------
;; MISCELLANEOUS UTILITY
;; -------------------------------------------------------------

        ;; "MATHEWS SAVE REGISTER ROUTINE" -- A DAMNED FINE BIT OF CLEVER CODING
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
CR:	    .EQU	0DH		    ; ASCII CARRIAGE RETURN
LF:	    .EQU	0AH		    ; ASCII LINE FEED
ESC:	.EQU	1BH		    ; ASCII ESCAPE CHARACTER
CRLFZ:	.TEXT	"\n\r\000"
VT52CL: .DB	    ESC, 'H', ESC, 'J', 00H

        ;; -------------------------------------------------------------
#ENDIF
