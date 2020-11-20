#IFNDEF bootdsp_asm         ; TASM-specific guard
#DEFINE bootdsp_asm  1

.NOLIST
;;  USAGE:  CALLABLE SUBROUTINE
;;  DEPS:   HWDESFS.ASM
;;  STACK:  REQUIRED
;;
;;  TO-DO:  MOD TO USE RAM LOCATIONS FOR VALUES _NMSUB AND _JMPTB
;;          SO THAT WE CAN USE AS A GENERALIZED TABLE DISPATCH
.LIST

;; -------------------------------------------------------------
;; ROUTE EXECUTION TO TABLE SUBROUTINE AT INDEX
;;   USAGE:  INDEX IN REG A
;;   ALTERS: AF
;;
;; ADAPTED FROM LANCE LEVANTHAL '9H JUMP TABLE (JTAB)'
;; -------------------------------------------------------------
        .MODULE BOOT_DISPATCH

BOOTJP: .EQU    $           ; GROUNDWORK TO ALLOW GENERALIZED USE OF
                            ;  TABLE DISPATCH SUBROUTINE.  EVENTUALLY
                            ;  WILL USE THIS ENTRY POINT TO SET _NMSUB
                            ;  AND _JMPTB FOR BOOT USE.  FOR NOW JUST
                            ;  AN ALTERNATE ENTRY POINT NAME

JTAB:   ;; EXIT WITH CARRY SET IF ROUTINE NUMBER IS INVALID,
        ;; THAT IS, IF IT IS TOO LARGE FOR TABLE (> _NMSUB-1)
        CP      _NMSUB      ; COMPARE ROUTINE NUMBER, TABLE SIZE
        CCF                 ; COMPLIMENT CARRY FOR ERROR INDICATOR
        RET     C           ; RETURN IF ROUTINE NUMBER TOO LARGE
                            ;  WITH CARRY SET

        ;; INDEX INTO TABLE OF WORD-LENGTH ADDRESSES
        ;; LEAVE REGISTER PAIRS UNCHANGED SO THEY CAN BE USED FOR PASSING PARAMS
        PUSH    HL          ; SAVE HL
        ADD     A,A         ; DOUBLE INDEX FOR WORD-LENGTH ENTRIES
        LD      HL,_JMPTB   ; INDEX INTO TABLE USING 8-BIT ADDITION
        ADD     A,L         ; TO AVOID DISTURBING ANOTHER REGISTER PAIR
        LD      L,A
        LD      A,0
        ADC     A,H
        LD      H,A         ; ACCESS ROUTINE ADDRESS

        ;; OBTAIN ROUTINE ADDRESS FROM TABLE AND TRANSFER CONTROL TO IT,
        ;;  LEAVING ALL REGISTER PAIRS UNCHANGED
        LD      A,(HL)      ; MOVE ROUTINE ADDRESS TO HL
        INC     HL
        LD      H,(HL)
        LD      L,A
        EX      (SP),HL     ;RESTORE OLD HL, PUSH ROUTINE ADDRESS

        RET                 ; JUMP TO ROUTINE

_NMSUB: .EQU    3           ; NUMBER OF SUBROUTINES IN TABLE

_JMPTB:                     ; JUMP TABLE
        .DW     BOOT0       ; DIAGNOSTICS
        .DW     BOOT1       ; TBD
        .DW     BOOT2       ; TBD
        .DW     BOOT3       ; TBD
        .DW     BOOT4       ; TBD
        .DW     BOOT5       ; TBD
        .DW     BOOT6       ; TBD
        .DW     BOOT7       ; TBD

#ENDIF