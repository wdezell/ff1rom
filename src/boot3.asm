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

        CALL    VTCLS

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 3\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCHR

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
#ENDIF
