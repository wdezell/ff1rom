#IFNDEF boot1_asm           ; TASM-specific guard
#DEFINE boot1_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT1

;; -------------------------------------------------------------
;; BOOT MODE 1 - MONITOR
;; -------------------------------------------------------------

BOOT1:  .EQU    $

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 1\n\r\000"

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

        ;; -------------------------------------------------------------
#ENDIF
