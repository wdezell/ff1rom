;; -------------------------------------------------------------
;; BOOT MODE 0 - CONSOLE MENU
;;  DIAGNOSTICS, BOARD UTILS, MONITOR, LAUNCH OTHER MODES
;; -------------------------------------------------------------
BOOT0C: .EQU    $           ; ENTRY POINT W/ SCREEN CLEAR
        CALL    CLSVT

BOOT0:  .EQU    $           ; ENTRY POINT PRESERVING SCREEN

        ;; PRESENT MENU
        CALL    PRINL
        .TEXT   CR,LF,"CONSOLE MENU",CR,LF,CR,LF
        .TEXT   "1  SYSTEM MONITOR",CR,LF
        .TEXT   "2  BOARD UTILS",CR,LF
        .TEXT   "3  DIAGNOSTICS",CR,LF
        .TEXT   "4  RESERVED",CR,LF
        .TEXT   "5  REBOOT",CR,LF,CR,LF
        .TEXT   "SELECT>",NULL

        ;; GET, VALIDATE, AND DISPATCH USER SELECTION
_READL: LD      HL,_B0INB   ; SET HL TO ADDRESS OF INPUT BUFFER
        LD      B,4         ; SET SIZE OF BUFFER
        CALL    CONLIN      ; CALL CONSOLE LINE READ
        CP      0           ; A = CHARS READ. ZERO?
        JR      Z,_READL    ; READ AGAIN (USER PROBABLY JUST PRESSED ENTER)
        LD      A,(_B0INB)  ; GET CHAR INTO A FOR INSPECTION (ONLY SINGLE DIGIT VALID HERE)
        SUB     30H         ; CONVERT ASCII INPUT IN A TO POSSIBLE NUMERIC
        CP      1           ; VERIFY IS 1 OR GREATER
        JP      C,BOOT0C    ; NO - DO AGAIN
        CP      5           ; VERIFY IS 5 OR LESS
        JP      NZ,BOOT0C   ; NO - DO AGAIN
        SUB     1           ; YES - IN RANGE, NOW CONVERT TO ZERO-BASED

        ;; USER PRESSED KEY 1-5
        LD      HL,_MNUTB   ; POINT TO ACTION DISPATCH TABLE
        LD      B,5         ; SET ENTRIES COUNT
        RST     08H         ; DEBUG DISPLAY
        CALL    TABDSP      ; JUMP TO ENTRY INDEXED BY A

        ;; SHOULD NEVER REACH HERE AS INPUT IS RANGE VALIDATED
        RST     08H
        HALT
        JR      $

_B0INB: .DS     4           ; USER INPUT BUFFER

_MNUTB: .EQU    $           ; MENU JUMP TABLE

        ;; NB: BOOT MODES ARE NOT REQUIRED TO CORRESPOND WITH CONSOLE MENU ENTRIES
        .DW     SYSMNI      ; SYSTEM MONITOR VIA BOOT MODE 1 INSTALLER
        .DW     BDUTLS      ; NOT IMPL YET
        .DW     BOOT0C      ; NOT IMPL YET
        .DW     BOOT0C      ; NOT IMPL YET
        .DW     RESET       ; RESTART
        ;; -------------------------------------------------------------

        ;; TODO: IMPLEMENT AS SEPARATE SRC
BDUTLS: .DW     BOOT0C      ; REDIRECT STUB

