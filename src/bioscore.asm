#IFNDEF bioscore_asm        ; TASM-specific guard
#DEFINE bioscore_asm  1

.NOLIST
;;  USAGE:  INLINE INCLUSION
;;  DEPS:   HWDEFS.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BIOS_CORE

;; -------------------------------------------------------------


;; -- WIP REFACTORING & ADAPTATION FOLLOW ---

        ;;   FIREFLY USES CTC CHANNEL 0 TO SCALE A USER-SELECTABLE TIMING SOURCE
        ;;   TO DRIVE SIO CH A RX/TX CLOCKS.  TIMING SOURCE IS JUMPER SELECTABLE
        ;;   OPTION OF SYSTEM CLOCK OR INDEPENDENT AUXILLARY OSCILLATOR.
        ;;
        ;;   USEFUL FORMULAE FOR 16X CLOCK RATES USING CTC IN COUNTER MODE:
        ;;     BAUD = CLK / 2 / 16 / TC
        ;;     TC =  CLK / ( 32 X BAUD )
        ;;
        ;;   TC VALUES FOR COMMON BAUD RATES AT COMMON CLOCK RATES FOLLOW.  VALUES
        ;;   MARKED BY ASTERISK ARE DESIRABLE AS THEY EXACTLY YIELD DESIRED BAUD
        ;;   RATES WITH 0% ERROR.
        ;;
        ;;   CLOCK   BAUD RATES
        ;;     MHZ    19200     9600     4800     2400     1800     1200      600
        ;;   ------  ------     ----     ----     ----     ----     ----     ----
        ;;   3.6864      *6      *12      *24      *48      *64      *96     *192
        ;;   4.0000     n/a       13       26       52       69      104      208
        ;;   6.1440     *10      *20      *40      *80      107     *160      n/a

        ;; INIT CTC CHANNEL 0 OUTPUT - SERIAL CHANNEL "A" BAUD RATE CLOCK

        ;; SIMPLE SERIAL CONSOLE OUTPUT (NON-INTERRUPT) SO WE CAN DISPLAY MESSAGES
        ;;   DEFAULT CONSOLE IS 9600 BAUD, NO PARITY, 8-BIT WORDS, 1 STOP BIT (9600-N-8-1)
INICTC: LD	    A,CTCCTR+CTCTC+CTCCTL   ; CTR MODE, TC FOLLOWS, IS CONTROL WORD
        OUT	    (CTCCH0),A
        LD	    A,20		; TC OF 20 = 9600 BAUD W/ 6.144 MHZ SYSTEM CLOCK
        OUT	    (CTCCH0),A

	    ;; INIT SIO SERIAL CHANNEL A
INISIO: LD	    C,SIOAC		; C = SIO CHAN. "A" CONTROL PORT
        LD	    HL,SATBLS	; HL = START OF CHAN. A INIT PARAMETERS TABLE
        LD	    B,SATBLE-SATBLS	; B = LENGTH IN BYTES OF PARAMETER TABLE
        OTIR			    ; WRITE TABLE TO SIO CHIP

	    ;; INIT DEC VT320 TERMINAL TO VT52 MODE, CLEAR SCREEN
INITRM: LD	    HL,VT52CL
	    CALL	WRSTRZ

	    RET

	    ;; SIO SERIAL CHANNEL A INITIALIZATION PARAMETERS TABLE
SATBLS:
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
SATBLE:	.EQU	$


        ;; POLLED-MODE SERIAL I/O ROUTINES
        ;; ( FROM VERSALOGIC/PROLOG VL-7806 REFERENCE MANUAL PG 3-21 )

        ;; Input status routine, checks SIO/DART to see if a character is
        ;; available.  If available, returns A = FFH (Z = 0).  If not
        ;; available, returns A = 00H (Z = 1).

INSTAT: IN	    A,(SIOAC)	; READ STATUS
	    BIT	    0,A		    ; BIT 0 = DATA AVAILABLE
	    JR	    Z,INSTT1	; NO DATA AVAILABLE
	    LD	    A,0FFH		; DATA AVAILABLE, SET A = FFH
	    AND	    A		    ; Z = 0
	    RET
INSTT1:	XOR	    A		    ; A = 0, Z = 1
	    RET

	    ;; Character input routine
	    ;; Waits for data and returns character in A
CHRIN:  IN	    A,(SIOAC)	; READ STATUS
	    BIT	    0,A		    ; DATA AVAILABLE
        JR	    Z,CHRIN	    ; NO DATA, WAIT
        IN	    A,(SIOAD)	; READ DATA
        AND	    7FH		    ; MASK BIT 7 (JUNK)
        RET

        ;; Character output routine
        ;; Checks CTS line and xmits character in C when CTS is active
CHROUT: PUSH	AF
        LD	    A,10H		; SIO HANDSHAKE RESET DATA
        OUT	    (SIOAC),A	; UPDATE HANDSHAKE REGISTER
        IN	    A,(SIOAC)	; READ STATUS
        BIT	    5,A		    ; CHECK CTS BIT
        JR	    Z,CHROUT	; WAIT UNTIL CTS IS ACTIVE
COUT1:	IN	    A,(SIOAC)	; READ STATUS
        BIT	    2,A		    ; XMIT BUFFER EMPTY?
        JR	    Z,COUT1		; NO, WAIT UNTIL EMPTY
        LD	    A,C		    ; CHARACTER TO A
        OUT	    (SIOAD),A	; OUTPUT DATA
        POP	    AF
        RET

        ;; Print Hex-ASCII representation of Register Pair HL by storing H & L seperately
        ;; to scratch RAM locations then doing normal H2ASC conversion/print of contents
        ;; HL = address value that is to be printed in form FFFF

PRTADR:	PUSH	HL		    ; SAVE REGS WHILE WE DO ASCII CONVERSION OF ADDRESS
        PUSH	DE
        PUSH	BC
        LD	    D,H		    ; SAVE ADDRESS IN REG PAIR DE
        LD	    E,L
        LD	    HL,ADDRHI	; POINT HL TO HIGH-BYTE STORAGE LOCATION
        LD	    A,D		    ; GET HIGH BYTE OF WORKING ADDRESS
        LD	    (HL),A		; SAVE TO WORK VAR
        CALL	H2ASC		; GET ASCII REPRESENTATION OF HIGH-BYTE INTO BC REG PAIR
        CALL	CHAROUT		; PRINT HIGH NIBBLE ASII REPRESENTATION (ALREADY IN REG C)
        LD	    C,B		    ; MOVE LOW-NIBBLE ASCII REPRESENTATION INTO REG C
        CALL	CHAROUT		; PRINT LOW-NIBBLE
        LD	    HL,ADDRLO	; POINT HL TO LOW-BYTE STORAGE LOCATION
        LD	    A,E		    ; GET LOW BYTE OF WORKING ADDRESS
        LD	    (HL),A		; SAVE TO WORK VAR
        CALL	H2ASC		; GET ASCII REPRESENTATION OF HIGH-BYTE INTO BC REG PAIR
        CALL	CHAROUT		; PRINT HIGH NIBBLE ASII REPRESENTATION (ALREADY IN REG C)
        LD	    C,B		    ; MOVE LOW-NIBBLE ASCII REPRESENTATION INTO REG C
        CALL	CHAROUT		; PRINT LOW-NIBBLE
        POP	    BC
        POP	    DE
        POP	    HL
        RET


        ;; In-line print routine
        ;; Print null-terminated string immediately following subroutine CALL
        ;; instruction.
        ;; Stack return address is adjusted to byte following terminating NULL.
INLPRT: EX	    (SP),HL		; NEXT BYTE AFTER CALL NOT RETURN ADDR BUT STRING
        CALL	WRSTRZ		; HL NOW POINTS TO STRING; PRINT AS USUAL
        INC	    HL		    ; ADJUST HL ONE BYTE BEYOND NULL TERMINATOR
        EX	    (SP),HL		; PUT HL BACK ON STACK AS ADJUSTED RETURN ADDRESS
        RET

        ;; Print null-terminated string pointed to by HL register pair
        ;; HL = start  address of string
        ;; Exit - HL is left pointing to NULL terminator character
WRSTRZ: PUSH	AF		    ; SAVE AFFECTED REGS
	    PUSH	BC
WRGETC:	LD	    A,(HL)		; GET CHAR
        CP	    0		    ; IS CHAR NULL END-OF-STRING DELIM ?
        JP	    Z,WRDONE	; YES, DONE
        LD	    C,A		    ; NO, SEND TO CHAROUT ROUTINE
        CALL	CHAROUT
        INC	    HL		    ; GET NEXT CHARACTER
        JP	    WRGETC
WRDONE:	POP	    BC		    ; RESTORE AFFECTED REGS
	    POP	    AF
	    RET


        ;; Byte-to-ASCII conversion
        ;; HL = address of memory location to be converted
        ;; B = returned ASCII representation of LOW nibble
        ;; C = returned ASCII representation of HIGH nibble

H2ASC:  PUSH	AF		    ; SAVE REGS

        ;; CONVERT HIGH NIBBLE
        LD	    A,(HL)		; GET MEMORY CONTENTS INTO A
        AND	    11110000B	; CLEAR  LOW NIBBLE
        RRA			        ; RIGHT-JUSTIFY HIGH NIBBLE
        RRA
        RRA
        RRA
        CP	    10		    ; IS DATA 10 OR MORE?
        JR	    C,ASCZ1
        ADD	    A,'A'-'9'-1	; YES - ADD OFFSET FOR LETTERS
ASCZ1:	ADD	    A,'0'		; ADD OFFSET FOR ASCII
	    LD	    C,A

        ;; CONVERT LOW NIBBLE
        LD	    A,(HL)		; GET MEMORY CONTENTS INTO A
        AND	    00001111B	; CLEAR HIGH NIBBLE
        CP	    10		    ; IS DATA 10 OR MORE?
        JR	    C,ASCZ2
        ADD	    A,'A'-'9'-1	; YES - ADD OFFSET FOR LETTERS
ASCZ2:	ADD	    A,'0'		; ADD OFFSET FOR ASCII
	    LD	    B,A

        POP	    AF		    ; RESTORE REGS
        RET


	    ;; STATIC DATA DEFINITIONS
CRLFZ:	.TEXT	"\n\r\000"
VT52CL:	.DB	    ESC, 'H', ESC, 'J', 00H




        ;; -------------------------------------------------------------
#ENDIF
