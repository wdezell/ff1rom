DBGUTS: .EQU    $               ; GENERAL UTILITIES END. TAG FOR RELOC & SIZE CALCS
        .PHASE DBGUTL           ; ASSEMBLE RELATIVE TO EXECUTION LOCATION

;; -------------------------------------------------------------
;; MISC DEBUG TOOLS
;; -------------------------------------------------------------

        ;; OUTPUT ACCUMULATOR AND ADDRESS *FOLLOWING* CALLING RST 08H
        ;;  DS4L/R HEX DISPLAYS = ADDRESS
        ;;  DS2                 = ACCUMULATOR
        ;;
        ;; USAGE:   RST 08H
        ;; AFFECTS: NONE
        ;;
DRST08: .EQU    $

        EX      (SP),HL     ; GET CALLER RETURN ADDRESS INTO HL
        PUSH    AF          ; PRESERVE A & FLAGS
        LD      A,H         ; DISPLAY HIGH BYTE OF CALLER'S ADDRESS
        OUT     (DS4L),A
        LD      A,L         ; DISPLAY LOW BYTE OF CALLER'S ADDRESS
        OUT     (DS4R),A
        POP     AF          ; RESTORE A & FLAGS
        OUT     (DS2),A     ; DISPLAY CALLER'S A
        EX      (SP),HL     ; PUT CALLER RETURN ADDRESS & HL BACK
        RET

;; -------------------------------------------------------------
        .DEPHASE
DBGUTE: .EQU    $               ; GENERAL UTILITIES END. TAG FOR RELOC & SIZE CALCS
DBSIZ:  .EQU    DBGUTE-DBGUTS   ; SIZE OF UTILITIES CODE
