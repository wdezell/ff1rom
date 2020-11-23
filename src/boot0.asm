#IFNDEF boot0_asm           ; TASM-specific guard
#DEFINE boot0_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT0

;; -------------------------------------------------------------
;; BOOT MODE 0 - DIAGNOSTICS
;; -------------------------------------------------------------

BOOT0:  .EQU    $

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

        ;; -------------------------------------------------------------
#ENDIF
