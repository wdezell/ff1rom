#IFNDEF bootdsp_asm         ; TASM-specific guard
#DEFINE bootdsp_asm  1

        ;; DISPATCH TABLE FOR BOOT MODE SWITCH
        ;;
BSWTAB: .EQU    $           ; BOOT SWITCH JUMP TABLE
        .DW     BOOT0       ; CONSOLE MENU -- DIAGNOSTICS, BOARD UTILS, MONITOR, LAUNCH OTHER MODES
        .DW     BOOT1       ; MONITOR
        .DW     BOOT2       ; CP/M
        .DW     BOOT3       ; FORTH
        .DW     BOOT4       ; BASIC
        .DW     BOOT5       ; RESERVED
        .DW     BOOT6       ; RESERVED
        .DW     BOOT7       ; RESERVED

        ;; -------------------------------------------------------------
#ENDIF
