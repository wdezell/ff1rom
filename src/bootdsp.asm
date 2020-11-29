#IFNDEF bootdsp_asm         ; TASM-specific guard
#DEFINE bootdsp_asm  1

        ;; DISPATCH TABLE FOR BOOT MODE SWITCH
        ;;
BSWTAB: .EQU    $           ; BOOT SWITCH JUMP TABLE
        .DW     BOOT0       ; SYSTEM MENU -- DIAGNOSTICS, BOARD UTILS, MONITOR, LAUNCH OTHER MODES
        .DW     BOOT1       ; CP/M
        .DW     BOOT2       ; FORTH
        .DW     BOOT3       ; BASIC
        .DW     BOOT4       ; REMOTE LOAD/EXECUTE SLAVE
        .DW     BOOT5       ; RESERVED
        .DW     BOOT6       ; RESERVED
        .DW     BOOT7       ; RESERVED

        ;; -------------------------------------------------------------
#ENDIF
