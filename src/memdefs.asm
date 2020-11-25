#IFNDEF memdefs_asm         ; TASM-specific guard
#DEFINE memdefs_asm  1

;; -----------------------------------------------------
;; COMMON MEMORY MAP DEFINITIONS
;; -----------------------------------------------------
        ;; STACK
STACK:  .EQU    MEMTOP      ; AT TOP OF RAM, GROWS DOWN
STKSIZ: .EQU    256         ; 256-BYTE STACK

        ;; RING BUFFER FOR INTERRUPT MODE 2 CONSOLE INPUT
CONBUF: .EQU    STACK-STKSIZ
CNBSIZ: .EQU    80          ; 80-CHARACTER TYPE-AHEAD BUFFER

#ENDIF
