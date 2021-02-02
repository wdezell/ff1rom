SYSMNS: .EQU    $           ; SYSTEM MONITOR START. TAG FOR RELOC & SIZE CALCS
        .PHASE HISTOP-SMSIZ ; ASSEMBLE RELATIVE TO EXECUTION LOCATION

;; -------------------------------------------------------------
;; SYSTEM MONITOR
;;  MONITOR LOOSELY BASED ON BIG BOARD PFM-80 COMMAND SET
;;  WITH EXTENSIONS AS USEFUL/NEEDED
;;
;; MONITOR WILL RESIDE FOR EXECUTION JUST UNDER BIOS AND BUFFERS
;; MONITOR INIT WILL CLEAR MEMORY FROM 0100H UP TO MONITOR
;;  FOR USER WORK
;; -------------------------------------------------------------

SYSMON: .EQU    $

SMCOLD: .EQU    $           ; SYSMON COLD START
        CALL   SMINIT       ; INTIALIZE WORK BUFFERS, COUNTERS

SMWARM: .EQU    $           ; SYSMON WARM START

        ;; DISPLAY ONE-TIME HELP MESSAGE
        CALL    PRINL
        .TEXT   CR,LF,"('?' = HELP)",CR,LF,NULL

        ;; DISPLAY USER PROMPT AND PARSE INPUT
_SMPPL: CALL    SMPRAP

        ;; COMMAND VALIDATE AND DISPATCH IF NO PARSING ERROR
        CALL    NC,SMVAD

        JR      _SMPPL      ; PROMPT & PARSE LOOP


        ;; DISPLAY MAIN MENU
        ;; -------------------------------------------------------------
SMMENU: .EQU    $

        CALL    CLSVT       ; CLEAR SCREEN (SEE IF CAN DO BOTH VT-100 AND LEAR-SIEGLER ADM3A)
        CALL    CLSA3

        CALL    PRINL
        .TEXT   CR,LF, "SYSTEM MONITOR",CR,LF,CR,LF      ; FIXME - display address and size here
        .TEXT   " Command                  Format",CR,LF
        .TEXT   " --------------------     ----------------------------------------------",CR,LF
        ;; TODO       D(isassmble) memory      D   STARTADDR ENDADDR
        .TEXT   " E(xamine) memory         E   STARTADDR COUNT",CR,LF
        .TEXT   " M(odify) memory          M   ADDRESS VALUE",CR,LF
        .TEXT   " G(o) execute memory      G   ADDRESS",CR,LF
        .TEXT   " C(opy) memory            C   STARTADDR ENDADDR DESTADDR",CR,LF
        .TEXT   " F(ill) memory            F   STARTADDR ENDADDR CONST",CR,LF
        .TEXT   " T(est) memory            T   STARTADDR ENDADDR",CR,LF
        .TEXT   " H(ex Load) memory        H   SER_A/B BAUD PARITY WORD STOP AUTOEXECUTE",CR,LF
        .TEXT   CR,LF
        .TEXT   " R(ead) mass storage      R   UNIT TRACK SECTOR DESTADDR COUNT",CR,LF
        .TEXT   " W(rite) mass storage     W   UNIT TRACK SECTOR STARTADDR ENDADDR",CR,LF
        .TEXT   " B(oot)                   B   ?,M #, 1-7",CR,LF
        .TEXT   CR,LF
        .TEXT   " I(nput) port             I   PORTNUM COUNT",CR,LF
        .TEXT   " O(utput) port            O   PORTNUM CONST COUNT",CR,LF
        .TEXT   CR,LF
        .TEXT   " ? (Help)                 ?",CR,LF,CR,LF,NULL

        ; CLEAR ACTIVE COMMAND REFERENCE
        CALL    SMCCC
        RET


        ;; CLEAR ACTIVE COMMAND REFERENCE
        ;; -------------------------------------------------------------
SMCCC:  PUSH    AF
        LD      A,' '
        LD      (SMCURCM),a
        POP     AF
        RET

        ;; SYSMON INIT
        ;;  INITIALIZE WORK BUFFERS, COUNTERS
        ;; -------------------------------------------------------------
SMINIT: .EQU    $

        ;; CLEAR LOW MEMORY FROM PAGE 1 UP TO LAST BYTE BELOW MONITOR
        LD      A,0
        LD      (RESET),A
        LD      HL,RESET
        LD      DE,RESET+1
        LD      BC,SYSMON-RESET-2
        LDIR

        ;; CLEAR BUFFERS AND WORK VARS, INSTALL NEW BOOT HOOK
        CALL    SMCLRB
        CALL    SMBPAT

        RET

        ;; PATCH SO THAT WARM RESTARTS INVOKE SYSMON DIRECTLY
SMBPAT: .EQU    $
        LD      HL,_SMBPAT
        LD      DE,ROMBEG
        LD      BC,3
        LDIR
        RET

_SMBPAT:JP      SMWARM      ; REPLACES 'JP  RESET' @ LOCATION 0000H


        ;; -------------------------------------------------------------
        ;; BEGIN - USER PROMPT AND INPUT-PARSING SECTION
        ;;
        ;; PARSING DECOMPOSES THE SPACE-SEPARATED USER INPUT IN CONBUF
        ;; INTO FIELD COMPONENTS AND STORES INTO BUFFERS SMP0-SMP6.
        ;;
        ;; USER INPUT IS NORMALIZED INTO UPPERCASE CHARACTERS.
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

        ; CLEAR BUFFERS, RESET ERROR FLAG
        CALL    SMCLRB
        AND     A           ; CLEAR CARRY

        ;; GET USER INPUT
        LD      HL,CONBUF   ; RETURN BUFFER
        LD      B,CNBSIZ    ; BUFFER SIZE
        CALL    CONLIN      ; COUNT OF CHARS READ RETURNED IN A
        LD      B,A         ; COPY OF COUNT READ TO B
        CP      0           ; IS COUNT ZERO? (USER JUST PRESSED ENTER)
        JR      NZ,_SMNZCM  ; COUNT NOT ZERO, HAVE A LINE AND TO PARSE & VALIDATE
_SMHVCM:LD      A,' '       ; SEE IF WE ARE IN AN ACTIVE COMMAND MODE
        LD      HL,SMCURCM
        CP      (HL)
        JP      Z,SMPRAP    ; NO ENTRY, NO ACTIVE COMMAND MODE - READ AGAIN
        AND     A           ; ENSURE RETURN WITH CARRY = 0 TO SIGNAL NO ERROR
        RET                 ; NO ENTRY BUT HAVE ACTIVE COMMAND MODE

        ;; PARSE MAIN INPUT BUFFER
        ;;
        ;;  THERE ARE POTENTIALLY 7 FIELDS SEPARATED BY ONE OR MORE SPACES.
        ;;  WE ONLY KNOW FOR SURE THAT THERE IS AT LEAST ONE INPUT CHARACTER AS B > 0 GOT US HERE.
        ;;
        ;;  COPY BYTES L-TO-R INTO DESTINATION BUFFERS FOR FURTHER VALIDATIONS, SWITCHING TO NEW DESTINATION
        ;;  BUFFER AS WE HIT SPACE DELIMITERS.  INITIAL. TRAILING, AND CONSECQUTIVE SPACES ARE IGNORED.
        ;;
        ;; -------------------------------------------------------------
_SMNZCM:CALL    SMRSTB      ; RESET TO FIRST TOKEN DESTINATION BUFFER
        LD      HL,CONBUF   ; POINT HL TO START OF USER INPUT BUFFER
        LD      C,' '       ; INIT FLAG TO DISALLOW DESTINATION BUFFER INCREMENT ON INITIAL SPACE(S)
_SMINBP:LD      A,(HL)      ; GET CHARACTER
        CALL    TOUPPER     ; NORMALIZE ALPHA CHARS TO UPPERCASE        NB - CHANGE IF SOME PARAMS REQ LC
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
        LD      A,SMPBSZ    ; LOAD SIZE LIMIT INTO A
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
        ;;  PERSISTENT REFERENCE SMCBSL
        ;; -------------------------------------------------------------
SMNXTB: .EQU    $

        CP      C           ; A CONTAINS ' ' BUT DOES REF REGISTER C? (E.G., BACK-TO-BACK SPACES)
        RET     Z           ; YES - DON'T SWITCH TO NEXT BUFFER, WE'VE ALREADY DONE IT. IGNORE & RETURN.

        PUSH    HL
        LD      HL,SMCBSL   ; POINT HL TO BUFFER SELECTOR
        INC     (HL)        ; INCREMENT SELECTOR TO POINT TO ADDRESS OF NEXT BUFFER IN TABLE
        INC     (HL)        ;  (EACH TABLE ENTRY IS 2 BYTES SO INCREMENT TWICE)
        LD      HL,(SMCBSL) ; HL NOW POINTING TO TABLE ENTRY ROW ADDRESS
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
        ;;
        ;; USAGE:   SET HL = ADDRESS OF SPECIFIC ERROR TEXT
        ;;          CALL SMPRSE
        ;; -------------------------------------------------------------
SMPRSE: .EQU    $
        PUSH    AF          ; PRESERVE A, FLAGS
        PUSH    HL          ; PRESERVE ERROR MESSAGE PASSED IN HL
        CALL    PRINL       ; DISPLAY ERROR MESSAGE PREAMBLE
        .TEXT   CR,LF,"**ERROR**: ",NULL

        POP     HL          ; RETRIEVE MESSAGE BODY AND PRINT IT
        CALL    PRSTRZ

        CALL    PRINL       ; WAIT FOR ACKKNOWLEDGEMENT
        .TEXT   CR,LF,"PRESS ANY KEY...",NULL

        CALL    CONCIN      ; READ A KEY
        POP     AF
        SCF                 ; SET CARRY FLAG TO INDICATE ERROR
        RET

        ;; RESET DESTINATION BUFFER AND REG PAIR DE
        ;; -------------------------------------------------------------
SMRSTB: PUSH    HL
        LD      HL,SMPB0AD      ; POINT HL TO *POINTER* TO FIRST BUFFER
        LD      (SMCBSL),HL     ; STORE POINTER INTO SELECTOR
        LD      E,(HL)          ; FETCH LOW BYTE OF ADDRESS ENTRY INTO E
        INC     HL              ;
        LD      D,(HL)          ; FETCH HIGH BYTE OF ADDRESS ENTRY INTO D
        LD      HL, SMCBCC      ; RESET CURRENT BUFFER CHARACTER COUNT TO ZERO
        LD      (HL),0
        POP     HL
        RET


        ;; EQUATES, GENERAL WORK VARS
        ;; -------------------------------------------------------------
SMERR00:.TEXT   "SYNTAX ERROR",NULL  ; ERROR MESSAGES
SMERR01:.TEXT   "INVALID COMMAND",NULL;
SMERR02:.TEXT   "PARAM WIDTH",NULL   ;
SMERR03:.TEXT   "NOT IMPLEMENTED YET",NULL   ;

        ;; -- TABLE: PARSE DESTINATION BUFFER LOOKUP --
SMCBSL: .DW     0           ; BUFFER SELECTOR (ADDRESS OF DESTINATION BUFFER WE'RE PARSING INTO)
SMPB0AD:.DW     SMPB0       ; POINTER - ADDRESS OF COMPONENT PARSING BUFFER 0
        .DW     SMPB1       ; ... 1
        .DW     SMPB2       ; ... 2
        .DW     SMPB3       ; ... 3
        .DW     SMPB4       ; ... 4
        .DW     SMPB5       ; ... 5
        .DW     SMPB6       ; ... 6


        ;; INPUT COMPONENT BUFFERS AND RELATED
        ;; -------------------------------------------------------------
SMPBSZ: .EQU    10          ; COMPONENT BUFFER SIZE (SIZED TO FIT LARGEST FOR SIMPLICITY)

SMCLRS: .EQU    $           ; BUFFER/SCRATCH AREA START
SMCBCC: .DB     1           ; CURRENT BUFFER ACCUMULATED CHARACTER COUNT (NTE SMPBSZ)
SMPB0:  .DS     SMPBSZ      ; TOKEN 0 (COMMAND)
SMPB1:  .DS     SMPBSZ      ; TOKENS 1 - 6 (POSSIBLE PARAMETERS)
SMPB2:  .DS     SMPBSZ      ;
SMPB3:  .DS     SMPBSZ      ;
SMPB4:  .DS     SMPBSZ      ;
SMPB5:  .DS     SMPBSZ      ;
SMPB6:  .DS     SMPBSZ      ;
SMCLRE: .EQU    $           ; BUFFER/SCRATCH AREA END
        ASSERT  ((SMCLRE-SMCLRS) < 256 )    ; SMCLRB RANGE LIMIT

        ;; -------------------------------------------------------------
        ;; END - USER PROMPT AND INPUT-PARSING SECTION
        ;; -------------------------------------------------------------

        ;; -------------------------------------------------------------
        ;; BEGIN - COMMAND VALIDATION AND HANDLER DISPATCH
        ;;
        ;;  USER INPUT IS CHECKED AGAINST A LIST OF VALID COMMANDS.
        ;;  IF FOUND TO BE A LEGAL COMMAND, THE POSITION OF THE COMMAND
        ;;  IN THE VALIDATION REFERENCE STRING IS USED AS AN INDEX INTO
        ;;  THE COMMAND HANDLER DISPATCH TABLE.
        ;;
        ;;  FURTHER VALIDATION OF PARAMETERS (IF ANY) IS DEFERRED TO THE
        ;;  RESPECTIVE COMMAND HANDLER.
        ;;
        ;; -------------------------------------------------------------
SMVAD:  .EQU    $

        ;; VALIDATE COMMAND AND GET POSITION INDEX   (MAYBE MOVE TOUPPER HERE, YES? IS GOOD IDEA.)
        LD      HL,SMPB0    ; GET FIRST CHAR FROM COMMAND BUFFER INTO REG A
        LD      A,(HL)
        ;CALL    TOUPPER    ; NOTE - CALL HERE INSTEAD OF IN PARSE IF CMD-ONLY CASE CONVERSION
        LD      HL,SMVCMDS  ; POINT HL TO ORDERED LIST OF VALID COMMANDS
        LD      BC,SMVCMCT  ; SET SEARCH COUNTER TO NUMBER OF COMMANDS
        CPIR                ; SEARCH LIST FOR COMMAND MATCHING CHARACTER IN REG A
        JR      Z,_SMVM     ; WE MATCHED A VALID COMMAND
        LD      HL,SMERR01  ; NO MATCH - DISPLAY ERROR MESSAGE
        CALL    SMPRSE
        RET

        ;; COMMAND VALID - DERIVE DISPATCH INDEX FROM COMMAND POSITION IN REFERENCE LIST
_SMVM:  LD      HL,SMCURCM  ; UPDATE 'CURRENT COMMAND' REFERENCE BYTE
        LD      (HL),A
        LD      A,SMVCMCT-1 ; GET COUNT OF TOTAL COMMANDS IN A, ADJUST FOR ZERO-BASED TABLE INDEX
        SUB     C           ; SUBTRACT 'TRIES REMAINING' COUNT (B IS ZERO SO JUST LOOK AT C)

        ;; DISPATCH HANDLER FOR COMMAND
        LD      HL,SMCMTAB  ; POINT TO START OF DISPATCH TABLE
        LD      B,SMVCMCT   ; NUMBER OF ENTRIES IN TABLE
        CALL    TABDSP      ; INVOKE COMMAND HANDLER
        RET


        ;; VALIDATION AND DISPATCH WORKING STORAGE
SMCURCM:.DB     ' '                     ; CURRENT COMMAND MODE
SMVCMDS:.TEXT   ".?BCEFGHIMORTW"        ; VALID MAIN MENU COMMANDS
SMVCMCT:.EQU    $-SMVCMDS               ; COUNT OF COMMANDS

        ; TABLE: MAIN MENU COMMAND HANDLER DISPATCH
SMCMTAB:.DW     DBGMKY                  ; '.' (HIDDEN DEBUG MONKEY)
        .DW     SMMENU                  ; ?
        .DW     SMCMDB                  ; B
        .DW     SMCMDC                  ; C
        .DW     SMCMDE                  ; E
        .DW     SMCMDF                  ; F
        .DW     SMCMDG                  ; G
        .DW     SMCMDH                  ; H
        .DW     SMCMDI                  ; I
        .DW     SMCMDM                  ; M
        .DW     SMCMDO                  ; O
        .DW     SMCMDR                  ; R
        .DW     SMCMDT                  ; T
        .DW     SMCMDW                  ; W

        ; DISPATCH TABLE ENTRIES MUST MATCH NUMBER OF COMMANDS (AND ORDER)
        ASSERT( ($ - SMCMTAB)/2 = SMVCMCT )

DBGMKY: .EQU    $

        IMPORT "dbgmnky.asm"        ;; THE DEBUG MONKEY

        CALL    SMCCC
        RET

        ;; STUBS FOR COMMAND HANDLERS - MOVE TO INDIVIDUAL SOURCE FILES AS IMPLEMENTED
        ;; -------------------------------------------------------------
SMCMDB: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'B' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDC: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'C' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDE: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'E' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDF: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'F' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDG: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'G' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDH: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'H' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDI: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'I' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDM: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'M' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDO: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'O' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDR: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'R' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDT: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'T' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

SMCMDW: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'W' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET

        ;; -------------------------------------------------------------
        ;; END -- COMMAND VALIDATION AND HANDLER DISPATCH SECTION


        .DEPHASE
SYSMNE: .EQU    $               ; SYSTEM MONITOR END. TAG FOR RELOC & SIZE CALCS
SMSIZ:  .EQU    SYSMNE-SYSMNS-1 ; SIZE OF UTILITIES CODE (SYSMNE IS 1 BYTE *AFTER*)
        ;; -------------------------------------------------------------
