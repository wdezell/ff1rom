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

        CALL    VTCLS

        ;; TODO - IMPLEMENT
        ;;
        ;; EXAMINE MEMORY
        ;; CHANGE MEMORY
        ;; EXAMINE REGISTERS
        ;; CHANGE REGISTERS
        ;; EXECUTE AT LOCATION
        ;; SERIAL LOAD INTEL OBJECT CODE STREAM
        ;; DISPLAY HELP



        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 1\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCHR

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
#ENDIF
