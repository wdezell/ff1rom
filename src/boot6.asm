#IFNDEF boot6_asm           ; TASM-specific guard
#DEFINE boot6_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT6

;; -------------------------------------------------------------
;; BOOT MODE 6
;; -------------------------------------------------------------

BOOT6:  .EQU    $

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

#ENDIF