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


        ;; MODULAR SOURCE FILE INCLUSIONS
IMPORT  "smparse.asm"
IMPORT  "smvad.asm"


        .DEPHASE
SYSMNE: .EQU    $               ; SYSTEM MONITOR END. TAG FOR RELOC & SIZE CALCS
SMSIZ:  .EQU    SYSMNE-SYSMNS-1 ; SIZE OF UTILITIES CODE (SYSMNE IS 1 BYTE *AFTER*)
        ;; -------------------------------------------------------------
