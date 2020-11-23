#IFNDEF boot3_asm           ; TASM-specific guard
#DEFINE boot3_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT3

;; -------------------------------------------------------------
;; BOOT MODE 3 - FORTH
;; -------------------------------------------------------------

BOOT3:  .EQU    $

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

        ;; -------------------------------------------------------------
#ENDIF
