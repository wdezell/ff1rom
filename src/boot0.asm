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

BOOT0:  .EQU    $

        ;; DEBUG / REMOVE
        RST     08H
        CALL    INLPRT
        .TEXT   "BOOT 0\n\r\000"

        ;; SIMPLE READ & ECHO TEST
_READC: CALL    CONIN       ; READ A CHARACTER FROM CONSOLE INTO A
        LD      C,A         ; MOVE IT INTO C FOR OUTPUT
        RST     08H         ; DEBUG
        CALL    CONOUT      ; PRINT TO CONSOLE OUT
        JR      _READC

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

        ;; -------------------------------------------------------------
#ENDIF
