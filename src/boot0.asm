;; -------------------------------------------------------------
;; BOOT MODE 0 - CONSOLE MENU
;;  DIAGNOSTICS, BOARD UTILS, MONITOR, LAUNCH OTHER MODES
;; -------------------------------------------------------------
BOOT0C: .EQU    $           ; ENTRY POINT W/ SCREEN CLEAR
        CALL    VTCLS

BOOT0:  .EQU    $           ; ENTRY POINT PRESERVING SCREEN

        ;; PRESENT MENU
        CALL    PRINL
        .TEXT   "\n\rCONSOLE MENU\n\r\n\r"
        .TEXT   "1  SYSTEM MONITOR\n\r"
        .TEXT   "2  BOARD UTILS\n\r"
        .TEXT   "3  DIAGNOSTICS\n\r"
        .TEXT   "4  RESERVED\n\r"
        .TEXT   "5  REBOOT\n\r\n\r"
        .TEXT   "SELECT>\000"

        ;; GET, VALIDATE, AND DISPATCH USER SELECTION
_READC: .EQU    $
        LD      HL,_B0SCB   ; SET INPUT BUFFER
        LD      B,_B0SCBS    ; SIZE IS 4 BYTES
        CALL    CONLIN      ; READ USER CONSOLE INPUT
        CP      0           ; DID USER JUST PRESS ENTER?
        JR      Z,_READC    ; YES - READ AGAIN
        LD      A,(_B0SCB)  ; NO - GET FIRST CHARACTER IN BUFFER INTO A FOR EVAL
        SUB     30H         ; CONVERT ASCII INPUT IN A TO POSSIBLE NUMERIC
        CP      1           ; VERIFY IS 1 OR GREATER
        JP      C,BOOT0C    ; NO - DO AGAIN
        CP      5           ; VERIFY IS 5 OR LESS
        JP      NZ,BOOT0C   ; NO - DO AGAIN
        SUB     1           ; YES - IN RANGE, NOW CONVERT TO ZERO-BASED

        ;; USER PRESSED KEY 1-5                 TO-DO: MOD TO USE A "LINE IN" AND REQUIRE ENTER TO SUBMIT
        LD      HL,_MNUTB   ; POINT TO ACTION DISPATCH TABLE
        LD      B,5         ; SET ENTRIES COUNT
        CALL    TABDSP      ; JUMP TO ENTRY INDEXED BY A

        ;; SHOULD NEVER REACH HERE AS INPUT IS RANGE VALIDATED
        RST     08H
        HALT
        JR      $

_B0SCBS:.EQU    2           ; INPUT BUFFER SIZE
_B0SCB: .DS     _B0SCBS     ; INPUT BUFFER FOR USER PROMPT

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

