;; -----------------------------------------------------
;; RAM BUFFERS AND DEFINITIONS FOR THE REV 1 BOARD
;; -----------------------------------------------------
        .ORG    STACK-STKSIZ-CNBSIZ
CONBUF: .EQU    $           ; BUFFER FOR CONSOLE INPUT
CNBSIZ: .EQU    256         ; 256-CHARACTER TYPE-AHEAD BUFFER

        .ORG    MEMTOP
STACK:  .EQU    $           ; AT TOP OF RAM, GROWS DOWN
STKSIZ: .EQU    256         ; 256-BYTE STACK

