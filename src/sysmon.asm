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


        ;; DISPLAY USER PROMPT AND PARSE INPUT
        ;; -------------------------------------------------------------
SMPRAP: .EQU    $

        ;; DISPLAY PROMPT
        CALL    PRINL
        .TEXT   CR,LF,"MON>",NULL

        ;; ---- CLEAR CONBUF (FOR EASE OF DEBUG DISPLAY BUT MAY KEEP) ----
        LD      HL,CONBUF
        LD      (HL),0
        LD      DE,CONBUF+1
        LD      BC,CNBSIZ-1
        LDIR
        ;; ---------------------------------------------------------------

        ;; GET USER INPUT
        LD      HL,CONBUF   ; RETURN BUFFER
        LD      B,CNBSIZ    ; BUFFER SIZE
        CALL    CONLIN      ; COUNT OF CHARS READ RETURNED IN A
        CP      0           ; NO CHARS READ (USER JUST PRESSED ENTER)
        JP      Z,SMPRAP    ; NO ENTRY - READ AGAIN
        LD      B,A         ; ELSE SAVE NUMBER OF CHARS IN BUFFER TO B

        ;; DEBUG - DISPLAY CONBUF FOR VERIFICATION
        CALL    PRINL       ; PUT US ON A NEW TERMINAL LINE FOR CLARITY
        .TEXT   CR,LF,NULL
        LD      HL,CONBUF
        CALL    PRSTRZ

        ;; PARSE MAIN INPUT BUFFER
        ;;
        ;;  THERE ARE POTENTIALLY 7 FIELDS SEPARATED BY ONE OR MORE SPACES.
        ;;  WE ONLY KNOW FOR SURE THAT THERE IS AT LEAST ONE INPUT CHARACTER AS B > 0 GOT US HERE.
        ;;
        ;;  COPY BYTES L-TO-R INTO DESTINATION BUFFERS FOR FURTHER VALIDATIONS,
        ;;   SWITCHING TO NEW BUFFER AS WE HIT DELIMITERS
        ;;
        CALL    _SMRSB      ; RESET TO FIRST TOKEN DESTINATION BUFFER
        LD      HL,CONBUF   ; POINT HL TO START OF USER INPUT BUFFER
_SMINBP:LD      A,(HL)      ; INSPECT CHARACTER
        CP      ' '         ; IS IT A SPACE?                    FIXME - INITIAL SPACE SHOULD NOT INC BUFFER!
        RST     10H
        JR      NZ,_SMNAS   ; NO - NOT A SPACE
        CALL    _SMNXB      ; YES - SWITCH TO NEXT DESTINATION BUFFER
        RST     10H
        ;DEC     B           ; ACCOUNT FOR THROW-AWAY CHAR
        INC     HL          ; POINT TO NEXT SOURCE BYTE
        DJNZ    _SMINBP
        RET

        ;; CHECK THAT INPUT IS NOT EXCEEDING DESTINATION BUFFER SIZE
        ;;  CARRY SET ON EXIT TO INDICATE BOUNDS EXCEEDED
_SMCKB:.EQU     $
        PUSH    AF
        PUSH    HL
        LD      HL,SMCBCC   ; GET CURRENT BUFFER CHARACTER COUNTER
        INC     (HL)        ; INCREMENT COUNT
        LD      A,SMPMSZ    ; LOAD SIZE LIMIT INTO A
        CP      (HL)        ; IF COUNT > A THEN CARRY = SET
        POP     HL
        POP     AF
        RET

_SMFSE: LD      HL,SMERR02  ; 'PARAM WIDTH' ERROR
        CALL    SMPRSE      ;

_SMNAS: .EQU    $           ; TESTING: PASS

        LD      C,A         ; CLEAR CONSECUTIVE-SPACE REF FLAG
        RST     10H
        CALL    _SMCKB      ; CHECK THAT INPUT NOT EXCEEDING BUFFER SIZE
        JP      C,_SMFSE    ; FIELD WIDTH EXCEEDS DESTINATION BUFFER -- ERROR BAIL
        LD      (DE),A      ; WRITE DATA TO LOCATION ADDRESSED BY DE
        RST     10H
        INC     HL          ; POINT TO NEXT SOURCE BYTE
        INC     DE          ; POINT TO NEXT DESTINATION BYTE
        RST     10H
        DJNZ    _SMINBP
        RET

        ;; SET NEXT TOKEN DESTINATION BUFFER
        ;;  GET POINTER TO NEXT BUFFER START INTO REG PAIR DE
        ;
        ; VERIFIED 20210118
_SMNXB: .EQU    $
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

        ;; RESET TOKEN DESTINATION BUFFER AND REG PAIR DE
        ;; VERIFIED 20210118
_SMRSB: PUSH    HL
        LD      HL,SMP0ADR      ; POINT HL TO *POINTER* TO FIRST BUFFER
        LD      (SMTKSL),HL     ; STORE POINTER INTO SELECTOR
        LD      E,(HL)          ; FETCH LOW BYTE OF ADDRESS ENTRY INTO E
        INC     HL              ;
        LD      D,(HL)          ; FETCH HIGH BYTE OF ADDRESS ENTRY INTO D
        LD      HL, SMCBCC      ; RESET CURRENT BUFFER CHARACTER COUNT TO ZERO
        LD      (HL),0
        POP     HL
        RET

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


        ;; DISPLAY MAIN MENU
        ;; -------------------------------------------------------------
SMMENU: .EQU    $

        CALL    CLSVT       ; CLEAR SCREEN (SEE IF CAN DO BOTH VT-100 AND LEAR-SIEGLER ADM3A)
        CALL    CLSA3

        CALL    PRINL
        .TEXT   HT, "SYSMON - AAAA-EEEE SIZE CCCC",CR,LF,CR,LF      ; FIXME - ADD DYNAMIC SPECS HERE
        .TEXT   HT, " Command                  Format",CR,LF
        .TEXT   HT, " --------------------     ----------------------------------------------",CR,LF
        ;; TODO       D(isassmble) memory      D   STARTADDR ENDADDR
        .TEXT   HT, " E(xamine) memory         E   STARTADDR ENDADDR",CR,LF
        .TEXT   HT, " M(odify) memory          M   ADDRESS",CR,LF
        .TEXT   HT, " G(o) execute memory      G   ADDRESS",CR,LF
        .TEXT   HT, " C(opy) memory            C   STARTADDR ENDADDR DESTADDR",CR,LF
        .TEXT   HT, " F(ill) memory            F   STARTADDR ENDADDR CONST",CR,LF
        .TEXT   HT, " T(est) memory            T   STARTADDR ENDADDR",CR,LF
        .TEXT   HT, " H(ex Load) memory        H   SERCHAN BAUD PARITY WORD STOP AUTOEXECUTE",CR,LF
        .TEXT   CR,LF
        .TEXT   HT, " R(ead) mass storage      R   UNIT TRACK SECTOR DESTADDR COUNT",CR,LF
        .TEXT   HT, " W(rite) mass storage     W   UNIT TRACK SECTOR STARTADDR ENDADDR",CR,LF
        .TEXT   HT, " B(oot)                   B   ?,M #, 1-7",CR,LF
        .TEXT   CR,LF
        .TEXT   HT, " I(nput) port             I   PORTNUM",CR,LF
        .TEXT   HT, " O(utput) port            O   PORTNUM CONST",CR,LF
        .TEXT   CR,LF
        .TEXT   HT, " ? (Help)                 ?",CR,LF
        .TEXT   HT, " X (Exit)                 X",CR,LF,CR,LF,NULL

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


        ;;CLEAR BUFFERS AND WORK VARS (THAT CAN RESET TO ZERO)
        ;; -------------------------------------------------------------
SMCLRB: .EQU    $
        LD      B,SMCLRE-SMCLRS
        LD      HL,SMCLRS   ; START OF CONTIGUOUS GROUP
_SMCB:  LD      (HL),0      ; WRITE A ZERO TO BYTE
        INC     HL          ; POINT TO NEXT
        DJNZ    _SMCB       ; REPEAT UNTIL ALL BYTES ZEROED
        RET

        ;; COMMAND VALIDATE AND DISPATCH
        ;; -------------------------------------------------------------
SMVAD:  .EQU    $

        ;; TODO -- YOU ARE HERE

        ;; -- BEGIN DEBUG
        ;; SIMPLE DISPLAY OF WHAT THE BUFFERS HAVE IN THEM
        ;CALL    CLSVT
        CALL    PRINL
        .TEXT   "DEBUG - INPUT AND PARSE BUFFERS:",CR,LF,NULL

        CALL    PRINL
        .TEXT   CR,LF,"CONBUF: ",NULL
        LD      HL,CONBUF
        LD      DE,DBSB
        LD      BC,CNBSIZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMP0: ",NULL
        LD      HL,SMP0
        LD      DE,DBSB
        LD      BC,SMPMSZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMP1: ",NULL
        LD      HL,SMP1
        LD      DE,DBSB
        LD      BC,SMPMSZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMP2: ",NULL
        LD      HL,SMP2
        LD      DE,DBSB
        LD      BC,SMPMSZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMP3: ",NULL
        LD      HL,SMP3
        LD      DE,DBSB
        LD      BC,SMPMSZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMP4: ",NULL
        LD      HL,SMP4
        LD      DE,DBSB
        LD      BC,SMPMSZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMP5: ",NULL
        LD      HL,SMP5
        LD      DE,DBSB
        LD      BC,SMPMSZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMP6: ",NULL
        LD      HL,SMP6
        LD      DE,DBSB
        LD      BC,SMPMSZ
        LDIR
        EX      DE,HL
        LD      (HL),0
        CALL    PRSTRZ

        ;; -- END DEBUG
        CALL    PRINL
        .TEXT   CR,LF,"PRESS ANY KEY",NULL
        CALL    CONCIN

        RST     10H         ; DEBUG
        RET

DBSB:   .DS     100         ; DEBUG SCRATCH BUFFER - REMOVE

        ;; INPUT & TOKENIZATION BUFFERS
        ;; -------------------------------------------------------------
SMPMSZ: .EQU    10          ; TOKEN BUFFER SIZE (SIZED TO FIT LARGEST FOR SIMPLICITY)

SMCLRS: .EQU    $           ; BUFFER/SCRATCH AREA START
SMCBCC: .DB     1           ; CURRENT BUFFER ACCUMULATED CHARACTER COUNT (NTE SMPMSZ)
SMP0:   .DS     SMPMSZ      ; TOKEN 0 (COMMAND)
SMP1:   .DS     SMPMSZ      ; TOKENS 1 - 6 (POSSIBLE PARAMETERS)
SMP2:   .DS     SMPMSZ      ;
SMP3:   .DS     SMPMSZ      ;
SMP4:   .DS     SMPMSZ      ;
SMP5:   .DS     SMPMSZ      ;
SMP6:   .DS     SMPMSZ      ;
SMCLRE: .EQU    $           ; BUFFER/SCRATCH AREA END
        ASSERT  ((SMCLRE-SMCLRS) < 256 )    ; SMCLRB RANGE LIMIT

        ;; -- TABLE START --
SMTKSL: .DW     0           ; BUFFER SELECTOR (ADDRESS OF DESTINATION BUFFER WE'RE PARSING INTO)
SMP0ADR:.DW     SMP0        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 0
SMP1ADR:.DW     SMP1        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 1
SMP2ADR:.DW     SMP2        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 2
SMP3ADR:.DW     SMP3        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 3
SMP4ADR:.DW     SMP4        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 4
SMP5ADR:.DW     SMP5        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 5
SMP6ADR:.DW     SMP6        ; POINTER - ADDRESS OF TOKEN PARSING BUFFER 6
        ;; -- TABLE END --

        ;; MISC EQUATES
        ;; -------------------------------------------------------------
SMVALCM:.TEXT   "EMGCFTHRWBIO?X"        ; VALID MAIN MENU COMMANDS
SMVALCT:.EQU    $-SMVALCM               ; COUNT OF COMMANDS
SMERR00:.TEXT   "00 SYNTAX ERROR",NULL  ; ERROR MESSAGES
SMERR01:.TEXT   "01 INVALID COMMAND",NULL;
SMERR02:.TEXT   "02 PARAM WIDTH",NULL   ;

        .DEPHASE
SYSMNE: .EQU    $               ; SYSTEM MONITOR END. TAG FOR RELOC & SIZE CALCS
SMSIZ:  .EQU    SYSMNE-SYSMNS-1 ; SIZE OF UTILITIES CODE (SYSMNE IS 1 BYTE *AFTER*)
        ;; -------------------------------------------------------------
