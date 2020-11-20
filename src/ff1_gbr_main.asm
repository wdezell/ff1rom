    .NOCODES
    ;;**********************************************************************
    ;;
    ;;  PROGRAM:  FF1GBR_MAIN -- GENERAL BOOT ROM FOR THE WDE8016 'FIREFLY' 
    ;;                           REVISION 1 BOARD
    ;;           
    ;;  AUTHOR:   WILLIAM D. EZELL      
    ;;  DATE:     
    ;;                                                               
    ;;  PURPOSE:  PERFORMS BOARD INITIALIZATION, DISPATCH TO LAUNCH HIGHER-LEVEL
    ;;            OPERATIONS, DIAGNOSTIC UTILITIES, AND CORE ROUTINES FOR USE BY
    ;;            HIGHER-LEVEL SOFTWARE
    ;;
    ;;
    ;;  ASSEMBLED USING THE TELEMARK ASSEMBLER (TASM) VERSION 3.1 
    ;;  BY THOMAS N. ANDERSON, SQUAK VALLEY SOFTWARE
    ;;
    ;;  USING THE FOLLOWING TASM SETTINGS:
    ;;    EXPORT TASMOPTS='-80 -A -B -E -F00 -LAL -S -Y'     
    ;;
    ;;    -80   Z80 INSTRUCTION SET
    ;;    -A    ENABLE ALL ASSEMBLY CONTROL CHECKS (WARNINGS)
    ;;    -B    RAW BINARY OBJECT FILE OUTPUT FORMAT (SUITABLE FOR PROMS)
    ;;          (-C 'CONTIGUOUS BLOCK' IS IMPLIED)
    ;;    -E    EXPAND SOURCE MACROS/INCLUDES
    ;;    -F    FILL UNUSED MEMORY WITH VALUE
    ;;    -LAL  SHOW ALL LABELS IN LONG FORM
    ;;    -S    SYMBOL FILE GENERATION
    ;;    -Y    ENABLE ASSEMBLY TIMING
    ;;
    ;;  SOURCE FORMATTING NOTE:
    ;;    USING SOFT TABS @ 4 SPACES FOR COLUMNAR ALIGNMENT
    ;;    OPCODE IN COL 9, OPERAND IN COL 17, COMMENTS COL 25 TYP
    ;;
    ;; **********************************************************************
        .CODES
        .TITLE "FF-ROM -- SYSTEM ROM FOR THE WDE8016 'FIREFLY' BOARD"
        .LIST
        .NOPAGE
                

        ;; *** BOOTSTRAP ***
        .ORG    ROM
        JP      RESET

        .ORG    03H
        
RSRVD1: .DS     1       ; RESERVED
IS_RAM: .DB     0       ; USED BY ROM/RAM SWAP TO DETERMINE IF RAM ALREADY ACTIVE (0 = ROM)
SPARE1: .DS     0       ; SPARE BYTE
SPARE2: .DS     0       ; SPARE BYTE
SPARE3: .DS     0       ; SPARE BYTE

;; -------------------------------------------------------------
;; ZERO PAGE JUMP VECTORS & INTERRUPT HANDLERS
;; -------------------------------------------------------------
        ;; MODE 0 MASKABLE INTERRUPT VECTORS
        ;; NB - RET INSTEAD OF RETI/RETN SINCE WE'RE NOT GOING TO USE IM1 BUT RATHER CALL AS SUBS
        ;;      (SO NO USE UNTIL AFTER STACK HAS BEEN ESTABLISHED :) )
        
        .ORG    08H     ; RST08 
        RET             ; UNUSED
    
        .ORG    10H     ; RST10 
        RET             ; UNUSED
    
        .ORG    18H     ; RST18 
        RET             ; UNUSED
    
        .ORG    20H     ; RST20 
        RET             ; UNUSED
    
        .ORG    28H     ; RST28 
        RET             ; UNUSED
    
        .ORG    30H     ; RST30 
        RET             ; UNUSED
        

        ;; MODE 1 MASKABLE INTERRUPT HANDLER
MSKISR: .ORG    38H
        EI
        RETI            ; UNUSED

        
    ;; NON-MASKABLE INTERRUPT HANDLER
NMIISR: .ORG    66H        
        RETN            ; UNUSED
        
                
        ;; MODE 2 PROGRAMMABLE INTERRUPT VECTORS
INTVEC: .ORG    $ & 0FFFF0H | 10H

        ;; WIP

        
        .ORG    100H
;; -------------------------------------------------------------
;; MAIN START
;; -------------------------------------------------------------
RESET:  .EQU    $
        DI                  ; NO INTERRUPTS UNTIL WE WANT THEM
        LD      SP, STACK   ; INIT STACK POINTER SO WE CAN CALL SUBS

;; SWAP OUT LOWER 32K ROM FOR RAM (EXECUTION CONTINUES IN RAM IMAGE OF ROM)
#INCLUDE "rom2ram.asm"      ; INLINED
        
        
    
        ;; WIP CALL SWITCH READ & GET MODES


;; -------------------------------------------------------------
;; SUPPORT MODULES;; -------------------------------------------------------------
#INCLUDE "hwdefs.asm"       ;; I/O MAP AND CONSTANTS FOR THE REV 1 BOARD

;; INSTALL MISC RESIDENT HELPERS
        // TO-DO:  WRITE THE RST08 DEBUG HELPER 7 SET UP VECTOR TABLE


;; -------------------------------------------------------------
;; TASM ROM MARKER
;;
;; FORCE TASM TO TOUCH A SINGLE BYTE AT THE END OF ROM IN ORDER
;; IMAGE SIZED EXACTLY FOR THE ROM, ELSE CODE GENERATION WILL 
;; STOP AFTER THE LAST INSTRUCTION OR DATA BLOCK DEFINITION.
;; -------------------------------------------------------------
        .ORG    ROMEND-1
        .CHK    LOWMEM  ; BYTE VALUE = CHECKSUM FROM ADDRESS 00H THRU PREV BYTE
        .END



