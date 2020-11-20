#IFNDEF boot5_asm           ; TASM-specific guard
#DEFINE boot5_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT5

;; -------------------------------------------------------------
;; BOOT MODE 5
;; -------------------------------------------------------------

BOOT5:  .EQU    $

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

#ENDIF