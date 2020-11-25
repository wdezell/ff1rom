#IFNDEF boot7_asm           ; TASM-specific guard
#DEFINE boot7_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT7

;; -------------------------------------------------------------
;; BOOT MODE 7
;; -------------------------------------------------------------

BOOT7:  .EQU    $

        ;; DEBUG / REMOVE
        RST     08H
        CALL    INLPRT
        .TEXT   "BOOT 7\n\r\000"

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

        ;; -------------------------------------------------------------
#ENDIF
