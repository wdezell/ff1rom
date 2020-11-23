#IFNDEF dbgutils_asm        ; TASM-specific guard
#DEFINE dbgutils_asm  1

.NOLIST
;;  USAGE:  INLINE INCLUSION
;;  DEPS:   HWDEFS.ASM
;;  STACK:  REQUIRED
.LIST
        .MODULE DEBUG_UTILS

;; -------------------------------------------------------------
;; MISC DEBUG TOOLS
;; -------------------------------------------------------------

;; DEBUG -- OUTPUT PC OF CALLING RST 08H TO DS4L/R HEX DISPLAYS
;;   USAGE:     RST 08H;
DRST08: .EQU    $

        EX      (SP),HL     ; GET CALLER RETURN ADDRESS INTO HL
        PUSH    AF          ; PRESERVE A
        LD      A,H         ; DISPLAY HIGH BYTE OF CALLER'S ADDRESS
        OUT     (DS4L),A
        LD      A,L         ; DISPLAY LOW BYTE OF CALLER'S ADDRESS
        OUT     (DS4R),A
        POP     AF          ; RESTORE A
        EX      (SP),HL     ; PUT CALLER RETURN ADDRESS & HL BACK
        RET

        ;; -------------------------------------------------------------
#ENDIF
