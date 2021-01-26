GUTLSS: .EQU    $               ; GENERAL UTILITIES START. TAG FOR RELOC & SIZE CALCS
        .PHASE GUTLS            ; ASSEMBLE RELATIVE TO EXECUTION LOCATION

;; CENTRALIZED IMPLEMENTATION OF USEFUL ROUTINES FOR SOFTWARE WHICH WINDS UP
;; CO-RESIDENT ON THE FIREFLY ROM.

;; -------------------------------------------------------------
;; CHARACTER AND STRING HANDLING
;; -------------------------------------------------------------

        ;; BYTE-TO-ASCII CONVERSION
        ;;  HL = ADDRESS OF MEMORY LOCATION TO BE CONVERTED
        ;;  B = RETURNED ASCII REPRESENTATION OF LOW NIBBLE
        ;;  C = RETURNED ASCII REPRESENTATION OF HIGH NIBBLE
        ;;
        ;; -------------------------------------------------------------
HX2ASC: PUSH    AF          ; SAVE REGS

        ;; CONVERT HIGH NIBBLE
        LD      A,(HL)      ; GET MEMORY CONTENTS INTO A
        AND     11110000B   ; CLEAR  LOW NIBBLE
        RRA                 ; RIGHT-JUSTIFY HIGH NIBBLE
        RRA
        RRA
        RRA
        CP      10          ; IS DATA 10 OR MORE?
        JR      C,_ASCZ1
        ADD     A,'A'-'9'-1 ; YES - ADD OFFSET FOR LETTERS
_ASCZ1: ADD     A,'0'       ; ADD OFFSET FOR ASCII
        LD      C,A

        ;; CONVERT LOW NIBBLE
        LD      A,(HL)      ; GET MEMORY CONTENTS INTO A
        AND     00001111B   ; CLEAR HIGH NIBBLE
        CP      10          ; IS DATA 10 OR MORE?
        JR      C,_ASCZ2
        ADD     A,'A'-'9'-1 ; YES - ADD OFFSET FOR LETTERS
_ASCZ2: ADD     A,'0'       ; ADD OFFSET FOR ASCII
        LD      B,A

        POP     AF          ; RESTORE REGS
        RET

IF 0    ;; CLEANUP AND PORT TO FIREFLY

        ;; PRINT HEX-ASCII REPRESENTATION OF REGISTER PAIR HL BY STORING H & L SEPERATELY
        ;; TO SCRATCH RAM LOCATIONS THEN DOING NORMAL H2ASC CONVERSION/PRINT OF CONTENTS
        ;; HL = ADDRESS VALUE THAT IS TO BE PRINTED IN FORM FFFF
        ;;
        ;; -------------------------------------------------------------
PRTADR: PUSH    HL          ; SAVE REGS WHILE WE DO ASCII CONVERSION OF ADDRESS
        PUSH    DE
        PUSH    BC
        LD      D,H         ; SAVE ADDRESS IN REG PAIR DE
        LD      E,L
        LD      HL,RESRV3   ; POINT HL TO HIGH-BYTE STORAGE LOCATION
        LD      A,D         ; GET HIGH BYTE OF WORKING ADDRESS
        LD      (HL),A      ; SAVE TO WORK VAR
        CALL    HX2ASC      ; GET ASCII REPRESENTATION OF HIGH-BYTE INTO BC REG PAIR
        CALL    CONOUT      ; PRINT HIGH NIBBLE ASII REPRESENTATION (ALREADY IN REG C)
        LD      C,B         ; MOVE LOW-NIBBLE ASCII REPRESENTATION INTO REG C
        CALL    CONOUT      ; PRINT LOW-NIBBLE
        LD      HL,RESRV4   ; POINT HL TO LOW-BYTE STORAGE LOCATION
        LD      A,E         ; GET LOW BYTE OF WORKING ADDRESS
        LD      (HL),A      ; SAVE TO WORK VAR
        CALL    HX2ASC      ; GET ASCII REPRESENTATION OF HIGH-BYTE INTO BC REG PAIR
        CALL    CONOUT      ; PRINT HIGH NIBBLE ASII REPRESENTATION (ALREADY IN REG C)
        LD      C,B         ; MOVE LOW-NIBBLE ASCII REPRESENTATION INTO REG C
        CALL    CONOUT      ; PRINT LOW-NIBBLE
        POP     BC
        POP     DE
        POP     HL
        RET
ENDIF

        ;; DISPLAY VALUE OF MEMORY LOCATION POINTED TO BY HL IN FORM FF
        ;;  HL = ADDRESS
        ;;
        ;;  REGISTERS AFFECTED: NONE
        ;; -------------------------------------------------------------
PRTMEM: .EQU    $

        PUSH    BC
        PUSH    AF

        CALL    HX2ASC
        CALL    CONOUT      ; HIGH NIBBLE ALREADY IN C
        LD      C,B         ; GET LOW NIBBLE INTO C FOR OUTPUT
        CALL    CONOUT      ; AND PRINT

        POP     AF
        POP     BC
        RET

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

        ;; SEND ADM3A COMPATIBLE SCREEN CLEAR COMMAND
        ;;  REGISTERS AFFECTED:  NONE
        ;;
        ;; NOTE: LS ADM3A SCREEN CLEAR FUNCTION MAY BE DISABLED
        ;;       BY INTERNAL SWITCH #3 ON SWITCH BLOCK A6
        ;; -------------------------------------------------------------
CLSA3:  CALL    PRINL
        .DB     01AH, NULL  ; SINGLE CTRL-Z CHAR
        RET

        ;; SEND VT-100 COMPATIBLE SCREEN CLEAR COMMAND SEQUENCE
        ;;  REGISTERS AFFECTED:  NONE
        ;; -------------------------------------------------------------
CLSVT:  CALL    PRINL
        .DB     1BH, '[', '2', 'J', NULL
        RET

;; -------------------------------------------------------------
;; MATH ROUTINES
;; -------------------------------------------------------------

        ;; TODO:  8-BIT MULTIPLY

        ;; TODO:  16-BIT DIVIDE


;; -------------------------------------------------------------
;; MISCELLANEOUS UTILITY
;; -------------------------------------------------------------

        ;; DELAY .25 SEC TIMES B
        ;;  PROVIVIDES A DELAY OF APPROXIMATELY 250,000 US
        ;;  FOR EVERY COUNT SPECIFIED BY B
        ;;
        ;;  TIMING IS BASED ON EXECUTION TIMES ON A 6.144 MHZ SYSTEM
        ;;  CLOCK.  DOES NOT ACCOUNT FOR CALL & RETURN TIMES NOR
        ;;  ~4 USEC OVERALL SETUP AND TEARDOWN TIMES.
        ;;
        ;; REGISTERS AFFECTED:
        ;;  B
        ;;  AF'
        ;; -------------------------------------------------------------
        ;;
DLY25B:	EX	    AF,AF'          ; 0.65  US @ 6.144 MHZ
	    LD	    DE,34176D		; 1.63
_DLY25:	DEC	    DE			    ; 0.975  ---
	    LD	    A,D			    ; 0.65   ^
	    OR	    E 			    ; 0.65   5.205 US
	    JP	    NZ,_DLY25		; 1.63
	    NOP				        ; 0.65   v
	    NOP 				    ; 0.65   ---
	    DJNZ	DLY25B		    ; 2.11 B != 0, 1.3 US B = 0
	    EX	    AF,AF'          ; 0.65

	    RET


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
TABDSP: .EQU    $

        ;; EXIT WITH CARRY SET IF ROUTINE NUMBER IS INVALID,
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


        ;; IS ASCII CHAR IN A AN ASCII ALPHA CHARACTER (UPPERCASE OR LOWERCASE)
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF IS ALPHA CHAR, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISALPHA:AND     A           ; CLEAR CARRY
        CALL    ISUPPER     ; DOES REG A CONTAIN AN UPPERCASER ASCII CHAR?
        RET     C           ; YES
        CALL    ISLOWER     ; NOT UPPERCASE - IS IT LOWERCASE?
        RET                 ; CARRY WILL INFORM CALLER Y/N

        ;; IS ASCII CHAR IN A AN ASCII LOWER-CASE ALPHA CHAR (61H-7AH)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF IS LOWERCASE ALPHA CHAR, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISLOWER:PUSH    HL          ; PRESERVE
        LD      H,'z'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'a'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS ASCII CHAR IN A AN ASCII UPPER-CASE ALPHA CHAR (41H-5AH)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF IS UPPERCASE ALPHA CHAR, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISUPPER:PUSH    HL          ; PRESERVE
        LD      H,'Z'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'A'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS ASCII CHAR IN A AN ASCII DIGIT (30H-39H)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF IS NUMERIC CHAR, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISNUM:  PUSH    HL          ; PRESERVE
        LD      H,'9'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'0'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS VALUE IN REG A IN THE RANGE (INCLUSIVE) BOUNDED BY H AND L (HIGH & LOW, RESPECTIVELY)
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF IS NUMERIC CHAR, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISINRHL:AND     A           ; CLEAR CARRY
        CP      L           ; IS A >= LOW LIMIT?
        JR      NC,_IRGEL   ; YES - NOW CHECK RANGE TOP
        CCF                 ; RANGE FAIL, A < LOW LIMIT, CLEAR CARRY FOR ERR IND
        RET
_IRGEL: CP      H          ; IS A <= HIGH RANGE LIMIT
        JR      C,_IRLEH
        JR      Z,_IRLEH
        RET                 ; RANGE FAIL, A > HIGH LIMIT, LEAVE CARRY CLEAR FOR ERR IND
_IRLEH: SCF                 ; ENSURE CARRY IS SET TO INDICATE SUCCESS
        RET


        ;; CONVERT ASCII CHAR IN A IN RANGE 30-39H TO DIGIT
        ;;
        ;;  RETURNS:
        ;;   A = NUMERICAL VALUE OF CHAR IF VALID, ELSE UNCHANGED
        ;;   CARRY SET FOR VALID CONVERSION
        ;;
        ;; -------------------------------------------------------------
TODIGIT:CALL    ISNUM       ; IS VALUE IN A AN ASCII DIGIT 30H-39H?
        RET     NC          ; NO - ERROR RETURN W/ CARRY CLEAR
        SUB     30H         ; YES - CONVERT ASCII DIGIT TO NUMERICAL VALUE
        SCF                 ; ENSURE CARRY IS SET TO INDICATE SUCCESS
        RET


        ;; CONVERT UPPERCASE ASCII CHAR IN REG A TO LOWERCASE
        ;;
        ;;  RETURNS:
        ;;   A = LOWERCASE CHAR IF VALID, ELSE UNCHANGED
        ;;   CARRY SET FOR VALID CONVERSION
        ;;
        ;; -------------------------------------------------------------
TOLOWER:CALL    ISUPPER     ; IS CHARACTER IN REG A A UPPERCASE CHARACTER?
        RET     NC          ; NO -WON'T CONVERT
        ADD     20H         ; YES - CONVERT TO LOWERCASE EQUIVALENT
        RET


        ;; CONVERT LOWERCASE ASCII CHAR IN REG A TO UPPERCASE
        ;;
        ;;  RETURNS:
        ;;   A = UPPERCASE CHAR IF VALID, ELSE UNCHANGED
        ;;   CARRY SET FOR VALID CONVERSION
        ;;
        ;; -------------------------------------------------------------
TOUPPER:CALL    ISLOWER     ; IS CHARACTER IN REG A A LOWERCASE CHARACTER?
        RET     NC          ; NO -WON'T CONVERT
        SUB     20H         ; YES - CONVERT TO UPPERCASE EQUIVALENT
        RET

;; -------------------------------------------------------------
;; SERIAL UTILITY ROUTINES
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
        ;; -------------------------------------------------------------

SETBDR: .EQU    $
        ;; INIT CTC CHANNEL 0 OUTPUT - SERIAL CHANNEL "A" BAUD RATE CLOCK
        LD      A,H                     ; GET PORT FROM PARAMETER H INTO C
        LD      C,A
        LD      A,CTCRST+CTCCTL+CTCCTR+CTCTC ; RESET, IS CONTROL WORD, COUNTER MODE, TC FOLLOWS
        OUT     (C),A
        OUT     (C),L                   ; TC VIA PARAMETER
        RET

;; -------------------------------------------------------------
;; USEFUL CONSTANTS
;; -------------------------------------------------------------
        ;; STATIC DATA DEFINITIONS
NULL:   .EQU    00H             ; ASCII NULL
BS:     .EQU    08H             ; ASCII BACKSPACE
DEL:    .EQU    7FH             ; ASCII DELETE
HT:     .EQU    09H             ; ASCII HORIZONTAL TAB
CR:     .EQU    0DH             ; ASCII CARRIAGE RETURN
LF:     .EQU    0AH             ; ASCII LINE FEED
ESC:    .EQU    1BH             ; ASCII ESCAPE CHARACTER

        .DEPHASE
GUTLSE: .EQU    $               ; GENERAL UTILITIES END. TAG FOR RELOC & SIZE CALCS
GUSIZ:  .EQU    GUTLSE-GUTLSS   ; SIZE OF UTILITIES CODE
;; -------------------------------------------------------------
