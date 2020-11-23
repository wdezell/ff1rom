#IFNDEF boot2_asm           ; TASM-specific guard
#DEFINE boot2_asm  1

.NOLIST
;;  USAGE:  INVOKED BY BOOT DISPATCH MODULE
;;  DEPS:   BOOTDSP.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE BOOT2

;; -------------------------------------------------------------
;; BOOT MODE 2 - BOARD UTILS
;; -------------------------------------------------------------

BOOT2:  .EQU    $

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        HALT
        JR      $

        ;; -------------------------------------------------------------
#ENDIF
