#IFNDEF memdefs_asm         ; TASM-specific guard
#DEFINE memdefs_asm  1

;; -----------------------------------------------------
;; RAM BUFFERS AND DEFINITIONS FOR THE REV 1 BOARD
;; -----------------------------------------------------
        .ORG    STACK-STKSIZ
CONBUF: .EQU    $           ; RING BUFFER FOR INTERRUPT MODE 2 CONSOLE INPUT
CNBSIZ: .EQU    80          ; 80-CHARACTER TYPE-AHEAD BUFFER

        .ORG    MEMTOP
STACK:  .EQU    $           ; AT TOP OF RAM, GROWS DOWN
STKSIZ: .EQU    256         ; 256-BYTE STACK

#ENDIF
