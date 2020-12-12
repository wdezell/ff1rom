;; -----------------------------------------------------
;; INITIAL MEMORY MAP UNTIL BOOT MODE LOADERS CHANGE IT
;; -----------------------------------------------------

        ;; BUFFER FOR CONSOLE INPUT
CONBUF: .EQU    STKBOT-STKSIZ
CNBSIZ: .EQU    256

        ;; 256-BYTE STACK
STACK:  .EQU    DBGUTL-1            ; STACK GROWS DOWN
STKSIZ: .EQU    256
STKBOT: .EQU    STACK-STKSIZ

        ;; DEBUG UTILITIES
DBGUTL: .EQU    GUTLS-DBSIZ

        ;; BOARD GENERAL UTILITIES
GUTLS:  .EQU    BBIOS-GUSIZ

        ;; BOARD BIOS AT TOP OF MEMORY
BBIOS:  .EQU    MEMTOP-BBSIZ
