#IFNDEF boot0_asm           ; TASM-specific guard
#DEFINE boot0_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT0

;; -------------------------------------------------------------
;; BOOT MODE 0 - CONSOLE MENU
;;  DIAGNOSTICS, BOARD UTILS, MONITOR, LAUNCH OTHER MODES
;; -------------------------------------------------------------
BOOT0C: .EQU    $           ; ENTRY POINT W/ SCREEN CLEAR
        CALL    VTCLS

BOOT0:  .EQU    $           ; ENTRY POINT PRESERVING SCREEN
        CALL    INLPRT
        .TEXT   "\n\rBOOT 0 - SYSTEM MENU\n\r\n\r"
        .TEXT   "1  HEX MONITOR\n\r"
        .TEXT   "2  BOARD UTILS\n\r"
        .TEXT   "3  DIAGNOSTICS\n\r"
        .TEXT   "4  RESERVED\n\r"
        .TEXT   "5  REBOOT\n\r\n\r"
        .TEXT   "SELECT>\000"

_READC: CALL    CONIN
        RST     08H         ;                                                   <-- DEBUG REMOVE
        LD      C,A         ; MOVE IT INTO C FOR ECHO
        CALL    CONOUT      ; ECHO TO CONSOLE OUT
        RST     08H         ;                                                   <-- DEBUG REMOVE
        SUB     30H         ; CONVERT ASCII INPUT IN A TO NUMERIC
        CP      1           ; VERIFY IS 1 OR GREATER
        JP      C,BOOT0C    ; NO - DO AGAIN
        CP      6           ; VERIFY IS 5 OR LESS
        JP      C,BOOT0C    ; NO - DO AGAIN
        RST     08H         ;                                                   <-- DEBUG REMOVE

        ;; USER PRESSED KEY 1-5                 TO-DO: MOD TO USE A "LINE IN" AND REQUIRE ENTER TO SUBMIT
        LD      HL,_MNUTB   ; POINT TO ACTION DISPATCH TABLE
        LD      B,5         ; SET ENTRIES COUNT
        CALL    TABDSP      ; JUMP TO ENTRY INDEXED BY A

        ;; SHOULD NEVER REACH HERE
        RST     08H
        HALT
        JR      $

_MNUTB: .EQU    $           ; MENU JUMP TABLE
        .DW     BOOT0C      ; NOT IMPL YET
        .DW     BOOT0C      ; NOT IMPL YET
        .DW     BOOT0C      ; NOT IMPL YET
        .DW     BOOT0C      ; NOT IMPL YET
        .DW     RESET       ; RESTART
        ;; -------------------------------------------------------------
#ENDIF
