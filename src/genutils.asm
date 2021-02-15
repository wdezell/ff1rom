GUTLSS: .EQU    $               ; GENERAL UTILITIES START. TAG FOR RELOC & SIZE CALCS
        .PHASE GUTLS            ; ASSEMBLE RELATIVE TO EXECUTION LOCATION

;; CENTRALIZED IMPLEMENTATION OF USEFUL ROUTINES FOR SOFTWARE WHICH WINDS UP
;; CO-RESIDENT ON THE FIREFLY ROM.

;; -------------------------------------------------------------
;; CHARACTER AND STRING HANDLING
;; -------------------------------------------------------------

        ;; BYTE-TO-ASCII CONVERSION
        ;;  GIVEN A LOCATION IN MEMORY ADDRESSED BY REGISTER PAIR HL,
        ;;  RETURN 2-DIGIT HEXADECIMAL ASCII CHARACTER REPRESENTATIONS OF
        ;;  NIBBLE VALUES IN REGISTERS D AND E
        ;;
        ;;  HL = ADDRESS OF MEMORY LOCATION TO BE CONVERTED
        ;;  D = RETURNED ASCII CHARACTER REPRESENTATION OF HIGH NIBBLE
        ;;  E = RETURNED ASCII CHARACTER REPRESENTATION OF LOW NIBBLE
        ;;
        ;; ALTERS: DE
        ;; -------------------------------------------------------------
BY2HXA: PUSH    AF          ; SAVE REGS

        ;; CONVERT HIGH NIBBLE
        LD      A,(HL)      ; GET MEMORY CONTENTS INTO A
        AND     11110000B   ; CLEAR  LOW NIBBLE
        RRA                 ; RIGHT-JUSTIFY HIGH NIBBLE
        RRA
        RRA
        RRA
        CP      10          ; IS DATA 10 OR MORE?
        JR      C,_BY2H1
        ADD     A,'A'-'9'-1 ; YES - ADD OFFSET FOR LETTERS
_BY2H1: ADD     A,'0'       ; ADD OFFSET FOR ASCII
        LD      D,A

        ;; CONVERT LOW NIBBLE
        LD      A,(HL)      ; GET MEMORY CONTENTS INTO A
        AND     00001111B   ; CLEAR HIGH NIBBLE
        CP      10          ; IS DATA 10 OR MORE?
        JR      C,_BY2H2
        ADD     A,'A'-'9'-1 ; YES - ADD OFFSET FOR LETTERS
_BY2H2: ADD     A,'0'       ; ADD OFFSET FOR ASCII
        LD      E,A

        POP     AF          ; RESTORE REGS
        RET


        ;; IS ASCII CHAR IN A AN ALPHA CHARACTER (UPPERCASE OR LOWERCASE)
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISALPHA:AND     A           ; CLEAR CARRY
        CALL    ISUPPER     ; DOES REG A CONTAIN AN UPPERCASER ASCII CHAR?
        RET     C           ; YES
        CALL    ISLOWER     ; NOT UPPERCASE - IS IT LOWERCASE?
        RET                 ; CARRY WILL INFORM CALLER Y/N


        ;; IS ASCII CHAR IN A BINARY DIGIT (30H-31H)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISBDIGT:AND     A           ; CLEAR CARRY
        PUSH    HL          ; PRESERVE
        LD      H,'1'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'0'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS ASCII CHAR IN A CONTROL CHAR (00H-1AH)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF IS CONTROL CHAR, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISCTRL: AND    A           ; CLEAR CARRY
        PUSH    HL          ; PRESERVE
        LD      H,1AH       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,00H       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS ASCII CHAR IN A DECIMAL DIGIT (30H-39H)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISDDIGT:AND     A           ; CLEAR CARRY
        PUSH    HL          ; PRESERVE
        LD      H,'9'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'0'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS ASCII CHAR IN A HEXADECIMAL DIGIT (30H-39H OR 41H-46H)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISHDIGT:AND     A           ; CLEAR CARRY
        CALL    ISDDIGT     ; IS IT ONE OF THE ALSO-DECIMAL DIGITS 0-9?
        RET     C           ; YES
        PUSH    HL          ; NO - PRESERVE HL
        LD      H,'F'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'A'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; IS 'A'-'F'?
        JR      C,_ISHAF    ; YES - CARRY RESULT PROPAGATES UP
        LD      H,'f'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'a'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; IS 'a'-'f'?  CARRY RESULT PROPAGATES UP
_ISHAF: POP     HL
        RET


        ;; IS ASCII CHAR IN AN OCTAL DIGIT (30H-37H)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISODIGT:AND     A           ; CLEAR CARRY
        PUSH    HL          ; PRESERVE
        LD      H,'7'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'0'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS VALUE IN REG A IN THE RANGE (INCLUSIVE) BOUNDED BY H AND L (HIGH & LOW, RESPECTIVELY)
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
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


        ;; IS ASCII CHAR IN A LOWER-CASE ALPHA CHAR (61H-7AH)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISLOWER:AND     A           ; CLEAR CARRY
        PUSH    HL          ; PRESERVE
        LD      H,'z'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'a'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET


        ;; IS ASCII CHAR IN AN UPPER-CASE ALPHA CHAR (41H-5AH)?
        ;;
        ;;  RETURNS:
        ;;   A = UNCHANGED
        ;;   CARRY = 1 IF TRUE, ELSE CARRY = 0
        ;;
        ;; -------------------------------------------------------------
ISUPPER:AND     A           ; CLEAR CARRY
        PUSH    HL          ; PRESERVE
        LD      H,'Z'       ; SET HIGH RANGE INCLUSIVE BOUNDARY
        LD      L,'A'       ; SET LOW RANGE INCLUSIVE BOUNDARY
        CALL    ISINRHL     ; CALL EVAL ROUTINE, CARRY RESULT PROPAGATES UP
        POP     HL
        RET



        ;; DISPLAY VALUE OF REGISTER PAIR HL AS
        ;;   4-DIGIT HEXADECIMAL NUMBER
        ;;
        ;;  REGISTERS AFFECTED: NONE
        ;; -------------------------------------------------------------
PRTHLR: .EQU    $

        CALL    SAVE        ; SAVE ALL REGISTERS AND FLAGS
        EX      DE,HL       ; SWAP - WE NEED HL FOR INDIRECTION

        LD      HL,_PHTMP   ; POINT TO WORKING STORAGE BYTE
        LD      A,D         ; SAVE WHAT WAS 'H' AND PRINT IT
        LD      (HL),A
        CALL    PRTMEM

        LD      A,E         ; SAVE WHAT WAS 'L' AND PRINT IT
        LD      (HL),A
        CALL    PRTMEM

        RET

_PHTMP: .DB     1           ; SCRATCH STORAGE


        ;; DISPLAY VALUE OF MEMORY LOCATION ADDRESSED BY HL
        ;;  AS 2-DIGIT HEXADECIMAL NUMBER
        ;;
        ;;  REGISTERS AFFECTED: NONE
        ;; -------------------------------------------------------------
PRTMEM: PUSH    BC
        PUSH    AF

        CALL    BY2HXA
        LD      C,D         ; GET HIGH NIBBLE INTO C FOR OUTPUT
        CALL    CONOUT      ;
        LD      C,E         ; GET LOW NIBBLE INTO C FOR OUTPUT
        CALL    CONOUT      ;

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


        ;; DETERMINE LENGTH OF NULL-TERMINATED STRING
        ;;
        ;; INPUT:
        ;;   HL = ADDRESS OF STRING START
        ;;
        ;; OUTPUT:
        ;;   BC = LENGTH OF STRING *NOT COUNTING* NULL TERMINATOR

        ;; OTHER REGISTERS AFFECTED:
        ;;   NONE
        ;;
        ;; -------------------------------------------------------------
STRLEN: PUSH    AF      ; PRESERVE ORIGINAL CONTENTS FOR A, FLAGS, & HL
        PUSH    HL
        XOR     A		; LOAD A WITH NULL
        LD      C,A		; ZERO B & C COUNT AS WELL
        LD      B,A		;
        CPIR		    ; SEARCH
        LD      HL,-1	; CALC LENGTH
        SBC     HL,BC	; RESULT IS IN HL BUT WE WANT IN BC FOR CONVENTION
        LD      B,H
        LD      C,L
        POP     HL      ; RESTORE ORIG A, FLAGS, & HL
        POP     AF

        RET


        ;; CONVERT ASCII CHAR IN A IN RANGE 30-39H TO DIGIT
        ;;
        ;;  RETURNS:
        ;;   A = NUMERICAL VALUE OF CHAR IF VALID, ELSE UNCHANGED
        ;;   CARRY SET FOR VALID CONVERSION
        ;;
        ;; -------------------------------------------------------------
TODIGIT:AND     A           ; CLEAR CARRY
        CALL    ISHDIGT     ; IS VALUE IN A DIGIT 30H-39H OR 41H-46H? INCLUDES B, O, D, & H
        RET     NC          ; NO - ERROR RETURN W/ CARRY CLEAR

        CALL    ISDDIGT     ; IS IT PLAIN OLD 0-9?
        JR      C,_TDID     ; YES

        CALL    ISUPPER     ; IS IT UPPERCASE A-F?
        JR      C,_TDIU     ; YES

        SUB     20H         ; SO MUST BE LOWERCASE A-F, ADJUST FOR UPPER/LOWER OFFSET
_TDIU:  SUB     'A'-'9'-1   ; ADJUST FOR ALPHA/DIGIT OFFSET
_TDID:  SUB     30H         ; YES - CONVERT ASCII DIGIT TO NUMERICAL VALUE
        SCF                 ; ENSURE CARRY IS SET TO INDICATE SUCCESS
        RET


        ;; TOINT - CONVERT CHARACTER STRING TO 16-BIT UNSIGNED BINARY VALUE
        ;;
        ;;   HL = BUFFER CONTAINING NULL-TERMINATED STRING OF NUMERIC CHARACTERS
        ;;   DE = CONVERTED RESULT
        ;;
        ;; RETURNS:
        ;;   VALID CONVERSION: 16-BIT UNSIGNED VALUE, CARRY = 1
        ;;   ERROR:  0, CARRY = 0
        ;;
        ;; ONLY THE FOLLOWING CHARACTERS MAY APPEAR IN THE STRING:
        ;;   - ALPHA NUMERIC DIGITS AS LEGAL FOR THE RADIX
        ;;   - RADIX IDENTIFIER (SUFFIX), ONE OF
        ;;     'D' (OPTIONAL) = DECIMAL      DIGITS 0-9
        ;;     'H'            = HEXADECIMAL  DIGITS 0-9,A-F
        ;;     'B'            = BINARY       DIGITS 0,1
        ;;     'Q'            = OCTAL        DIGITS 0-7
        ;;
        ;; TODO - OPTIMIZE THIS UGLY BEAST
        ;;
        ;; FIXME - CARRY NOT BEING CLEARED BY 16-BIT PRODUCT OVERFLOW ERROR EXIT (E.G. 65536)
        ;; -------------------------------------------------------------
TOINT:  .EQU    $

        LD      (_TIBSV),HL ; SAVE BUFFER START ADDRESS

        ;; EXAMINE SOURCE STRING AND IDENTIFY RADIX MODE, SET POSITION MULTIPLER
        CALL    STRLEN      ; GET LENGTH OF STRING INTO BC
        DEC     BC          ; ADJUST FOR 0-BASED COUNT
        ADD     HL,BC       ; EXAMINE LAST POSITION FOR OPTIONAL RADIX SUFFIX
        LD      A,(HL)      ;
        CP      'H'         ; IS IT HEX?
        JR      Z,_TIH      ; YES
        CP      'Q'         ; OCTAL?
        JR      Z,_TIQ      ; YES
        CP      'B'         ; BINARY?
        JR      Z,_TIB      ; YES
        CP      'D'         ; EXPLICITLY DECIMAL?
        JR      Z,_TIDE     ; YES
        JR      _TID

_TIDE:  LD      (HL),0      ; REMOVE RADIX SUFFIX
_TID:   LD      A,10        ; NONE OF THE ABOVE. ASSUME DECIMAL, SET BASE-10
        JR      _TIBSTO
_TIB:   LD      (HL),0      ; REMOVE RADIX SUFFIX
        LD      A,2         ; SET BASE-2
        JR      _TIBSTO
_TIH:   LD      (HL),0      ; REMOVE RADIX SUFFIX
        LD      A,16        ; SET BASE-16
        JR      _TIBSTO
_TIQ:   LD      (HL),0      ; REMOVE RADIX SUFFIX
        LD      A,8         ; SET BASE-8

_TIBSTO:LD      (_TIRDX),A  ; STORE BASE MULTIPLIER
        LD      HL,(_TIBSV) ; RESTORE START ADDRESS OF STRING


        ;; SCAN L-R AND SUM ACCORDING TO THE FORMULA 'VALUE = VALUE * BASE + DIGIT'
        ;; WE WILL ACCUMULATE VALUE IN REG PAIR DE AS IT IS CONVENIENTLY ALSO OUR MULTIPLICAND
        LD      D,0         ; INIT 'VALUE' TO ZERO
        LD      E,0
_TIINSP:LD      A,(HL)      ; GET CHARACTER INTO A
        CP      0           ; ARE WE AT END OF STRING?
        JP      Z,_TIDON    ; YES
        CALL    _TIVLD      ; NO - IS CHARACTER A VALID DIGIT FOR BASE?
        JR      NC,_TIERR   ; NO

        ; MULTIPLY CURRENT VALUE ACCUMULATION BY BASE
        LD      (_TIBSV),HL ; SAVE POSITION IN CHARACTER STRING BECAUSE HL NEEDED FOR PRODUCT RETURN
        LD      A,(_TIRDX)  ; BASE MULTIPLIER INTO REG A, DE ALREADY HOLDS MULTIPLICAND (VALUE)
        CALL    M168U       ; PERFORM MULTIPLY OF 16-BIT * 8-BIT UNSIGNED


        ; CHECK OVERFLOW (PRODUCT IS IN A:HL)
        CP      0           ; A MUST EQUAL 0 OR WE HAVE EXCEEDED DESIRED 16-BIT PRODUCT RANGE
        JR      NZ,_TIERR   ; A IS NONZERO SO WE WILL CALL THIS AN ERROR

        ; MOVE PRODUCT BACK TO REG PAIR DE AND ADD CURRENT DIGIT
        EX      DE,HL
        LD      HL,(_TIBSV) ; RESTORE BUFFER POINTER
        LD      A,(HL)      ; FETCH CHARACTER THAT'S THERE
        CALL    TODIGIT     ; CONVERT FROM ASCII TO NUMERICAL VALUE
        PUSH    BC          ; SAVE BC SO CAN USE FOR 8-BIT TO 16-BIT ADD
        LD      B,0
        LD      C,A         ; NUMERICAL VALUE OF CURRENT DIGIT
        EX      DE,HL       ; GET DE INTO HL (PSEUDO 16-BIT ADD ACCUMULATOR)
        ADD     HL,BC
        EX      DE,HL       ; DE=DE+A, HL=BUFFER POINTER
        POP     BC          ; BC=ORIG CONTENTS
        INC     HL          ; ADVANCE TO NEXT CHARACTER

        JR      _TIINSP

_TIDON: SCF     ; SET CARRY FOR SUCCESS
        RET

_TIERR: LD      D,0         ; ERROR RETURN - DE = 0, CARRY = 0
        LD      E,0
        AND     A           ; CLEAR CARRY FLAG
        RET

        ; IS CHARACTER A VALID DIGIT FOR BASE?
_TIVLD: PUSH    AF          ; SAVE CHAR, FLAGS TOO
        LD      A,(_TIRDX)  ; GET STORED BASE MULTIPLIER
        CP      2           ; JUMP TO APPROPRIATE VALIDATOR
        JR      Z,_TIIBD    ; BINARY
        CP      8
        JR      Z,_TIIOD    ; OCTAL
        CP      10
        JR      Z,_TIIDD    ; DECIMAL
        CP      16
        JR      Z,_TIIHD    ; HEXADECIMAL

        JP      ABEND       ; THIS SHOULDN'T HAPPEN.

_TIIBD: POP     AF          ; CHAR TO INSPECT BACK IN A
        CALL    ISBDIGT     ; IS IT A VALID BINARY DIGIT?
        RET                 ; CARRY = 1 YES, CARRY = 0 NO

_TIIOD: POP     AF          ;
        CALL    ISODIGT     ; OCTAL DIGIT?
        RET                 ;

_TIIDD: POP     AF          ;
        CALL    ISDDIGT     ; DECIMAL DIGIT?
        RET                 ;

_TIIHD: POP     AF          ;
        CALL    ISHDIGT     ; HEXADECIMAL DIGIT?
        RET                 ;

_TIBSV: .DW     1           ; STRING BUFFER ADDRESS SAVE
_TIRDX: .DS     1           ; DETERMINED RADIX


        ;; CONVERT UPPERCASE ASCII CHAR IN REG A TO LOWERCASE
        ;;
        ;;  RETURNS:
        ;;   A = LOWERCASE CHAR IF VALID, ELSE UNCHANGED
        ;;   CARRY SET FOR VALID CONVERSION
        ;;
        ;; -------------------------------------------------------------
TOLOWER:CALL    ISUPPER     ; IS CHARACTER IN REG A AN UPPERCASE CHARACTER?
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
;; MATH ROUTINES
;; -------------------------------------------------------------

        ;; 16-BIT * 8-BIT UNSIGNED
        ;;
        ;; INPUT:               OUTPUT:
        ;;  A = MULTIPLIER       A:HL = PRODUCT
        ;;  DE = MULTIPLICAND
        ;;
        ;; DESTROYS:
        ;;  BC
        ;;
        ;; CREDIT: Z80 BITS, MILOS "BAZE" BAZELIDES, BAZE_AT_BAZE_AU_COM
        ;; -------------------------------------------------------------
M168U:  LD      HL,0
        LD      C,0
        ADD     A,A         ; OPTIMIZED 1ST ITERATION
        JR      NC,$+4
        LD      H,D
        LD      L,E

        LD      B,7
_168U:  ADD     HL,HL       ; UNROLL 7 TIMES
        RLA                 ; ...
        JR      NC,$+4      ; ...
        ADD     HL,DE       ; ...
        ADC     A,C         ; ...
        DJNZ    _168U

        RET


        ;; 16-BIT * 16-BIT UNSIGNED MULTIPLICATION
        ;;
        ;; INPUT:                OUTPUT:
        ;;  DE = MULTIPLIER       DE:HL = PRODUCT
        ;;  BC = MULTIPLICAND
        ;;
        ;; CREDIT: Z80 BITS, MILOS "BAZE" BAZELIDES, BAZE_AT_BAZE_AU_COM
        ;; -------------------------------------------------------------
M1616U: LD      HL,0
        SLA     E           ; OPTIMISED 1ST ITERATION
        RL      D
        JR      NC,$+4
        LD      H,B
        LD      L,C

        LD      A,15
_1616U: ADD     HL,HL       ; UNROLL 15 TIMES
        RL      E           ; ...
        RL      D           ; ...
        JR      NC,$+6      ; ...
        ADD     HL,BC       ; ...
        JR      NC,$+3      ; ...
        INC     DE          ; ...
        SUB     1
        JR      NZ,_1616U

        RET


;; -------------------------------------------------------------
;; MISCELLANEOUS UTILITY
;; -------------------------------------------------------------

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


        ;; DELAY .25 SEC TIMES B
        ;;  PROVIVIDES A DELAY OF APPROXIMATELY 250,000 US
        ;;  FOR EVERY COUNT SPECIFIED BY B
        ;;
        ;;  TIMING IS BASED ON EXECUTION TIMES ON A 6.144 MHZ SYSTEM
        ;;  CLOCK.  OVERALL TIMING IS EXPRESSED APPROXIMATELY BY THE
        ;;  FOLLOWING FORMULA (INCLUDING CALL AND RET TIMES):
        ;;
        ;;  DELAY IN MICROSECONDS = 14.160US + (B * 250,000US)
        ;;
        ;;
        ;; REGISTERS AFFECTED:
        ;;  B   PARAMETER - COUNT OF .25-SEC DELAYS TO PAUSE
        ;;
        ;; -------------------------------------------------------------
        ;;
        ;CALL   DLY25B      ; 17T
DLY25B: PUSH    DE          ; 11T   ; SAVE REG PAIR DE
        PUSH    AF          ; 11T   ; AND A, FLAGS

_DL25O:	LD	    DE,54858D   ; 10T  1.627US          (250000US - 87T)/28T
_DL25I:	DEC	    DE          ; 6T   28T 4.557US
	    LD	    A,D         ; 4T   |
	    OR	    E           ; 4T   |
	    NOP                 ; 4T   |
	    JP	    NZ,_DL25I   ; 10T  -
	    DJNZ	_DL25O      ; 8T  1.302US B!=0, 5T .814US B=0

        POP     AF          ; 10T
	    POP     DE          ; 10T
	    RET                 ; 10T


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


;; -------------------------------------------------------------
;; SERIAL UTILITY ROUTINES
;; -------------------------------------------------------------
        ;; TODO -- DECOUPLE AND "PARAMETERIZE" THIS A BIT BETTER
        ;;         THIS  SHOULD BE STRUCTURED FOR EASIER POST-BOOT
        ;;         CALLS SO RECONFIGURE CONSOLE AT WILL OR SETUP
        ;;         CHANNEL B WITHOUT RE-INVENTING THE WHEEL IN
        ;;         DUPLICATE CODE.  GOAL = A "SERIAL CONTROL BLOCK"

        ;; BASIC CONSOLE INITIALIZATION
        ;;  SIO CHANNEL A WILL BE CONFIGURED TO 19200-N-8-1 FOR TX &
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
        LD      L,10        ; NO -- SET TC FOR INTERNAL SYSTEM CLOCK
        JR      _CALSB
_EXCLK: LD      L,6         ; SET TC FOR EXTERNAL CLOCK
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

WDEMSG: CALL    PRINL
        INCBIN  "wdemsg"
        .DB     CR,LF,NULL
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
