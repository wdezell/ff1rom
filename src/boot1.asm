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
        ;; RELOCATER to move all of this stuff from our ROM-origined basket to HIMEM and wire it up
        ;;
        ;; EXAMINE MEMORY
        ;; CHANGE MEMORY
        ;; EXAMINE REGISTERS
        ;; CHANGE REGISTERS
        ;; EXECUTE AT LOCATION
        ;; SERIAL LOAD INTEL OBJECT CODE STREAM
        ;; DISPLAY HELP

        ;; And oh, BTW, this all must be written as relocatable code that will be copied to TBD location in HIMEM.
        ;; That means we have to duplicate and take with us any core routines we use since LOWMEM where they reside
        ;; is expected to be cleared as one giant proto-CP/M work area.  So they, too, must be converted to be
        ;; relocatable.
        ;;
        ;;   CONCHR
        ;;   CONLIN
        ;;   CONOUT
        ;;   CONOUTW (?)
        ;;     (serial init stuff not needed as boot code will already have handled)
        ;;
        ;;   Support utils like HEX2ASC, etc, need to come along as well

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 1\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCHR

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
#ENDIF
