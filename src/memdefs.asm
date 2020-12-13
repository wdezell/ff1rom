;; -----------------------------------------------------
;; INITIAL MEMORY MAP UNTIL BOOT MODE LOADERS CHANGE IT
;; -----------------------------------------------------

        ;; DEBUG UTILITIES
DBGUTL: .EQU    GUTLS-DBSIZ

        ;; BOARD GENERAL UTILITIES
GUTLS:  .EQU    BBIOS-GUSIZ

        ;; BOARD BIOS
BBIOS:  .EQU    CONBUF-BBSIZ

        ;; BUFFER FOR CONSOLE INPUT
CONBUF: .EQU    STKBOT-CNBSIZ
CNBSIZ: .EQU    256

        ;; STACK AT TOP OF MEMORY
STACK:  .EQU    MEMTOP              ; STACK GROWS DOWN
STKSIZ: .EQU    256
STKBOT: .EQU    STACK-STKSIZ
