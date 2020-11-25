#IFNDEF boot4_asm           ; TASM-specific guard
#DEFINE boot4_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT4

;; -------------------------------------------------------------
;; BOOT MODE 4 - CP/M V2.2
;; -------------------------------------------------------------

BOOT4:  .EQU    $

        ;; DEBUG / REMOVE
        RST     08H
        CALL    INLPRT
        .TEXT   "BOOT 4\n\r\000"

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

        ;; -------------------------------------------------------------
#ENDIF
