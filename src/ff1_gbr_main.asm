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
    ;;    EXPORT TASMOPTS='-80 -A -B -E -F00 -H -LAL -S -Y'
    ;;
    ;;    -80   Z80 INSTRUCTION SET
    ;;    -A    ENABLE ALL ASSEMBLY CONTROL CHECKS (WARNINGS)
    ;;    -B    RAW BINARY OBJECT FILE OUTPUT FORMAT (SUITABLE FOR PROMS)
    ;;          (-C 'CONTIGUOUS BLOCK' IS IMPLIED)
    ;;    -E    EXPAND SOURCE MACROS/INCLUDES
    ;;    -F    FILL UNUSED MEMORY WITH VALUE
    ;;    -H    INCLUDE HEX TABLE OF OBJECT FILE AT END OF LISTING
    ;;    -LAL  SHOW ALL LABELS IN LONG FORM
    ;;    -S    SYMBOL FILE GENERATION
    ;;    -Y    ENABLE ASSEMBLY TIMING
    ;;
    ;;  SOURCE FORMATTING NOTE:
    ;;    USING SOFT TABS @ 4 SPACES FOR COLUMNAR ALIGNMENT
    ;;    OPCODE IN COL 9, OPERAND IN COL 17, COMMENTS COL 25 OR 29 TYP
    ;;
    ;; **********************************************************************
        .CODES
        .TITLE "FF-ROM -- SYSTEM ROM FOR THE WDE8016 'FIREFLY' BOARD"
        .LIST
        .NOPAGE
                

        ;; *** BOOTSTRAP ***
        .ORG    ROMBEG
        JP      RESET

        .ORG    03H

IS_RAM: .DB     0       ; USED BY ROM/RAM SWAP TO DETERMINE IF RAM ALREADY ACTIVE (0 = ROM)
SCRAT1: .DB     0       ; GENERAL USE SCRATCH BYTE
SCRAT2: .DB     0       ; GENERAL USE SCRATCH BYTE
SCRAT3: .DB             ; GENERAL USE SCRATCH BYTE
SCRAT4: .DB     0       ; GENERAL USE SCRATCH BYTE

;; -------------------------------------------------------------
;; ZERO PAGE JUMP VECTORS & INTERRUPT HANDLERS
;; -------------------------------------------------------------
        ;; MODE 0 MASKABLE INTERRUPT VECTORS
        ;;  WE'RE NOT GOING TO USE IM0 BUT RATHER USE AS 1-BYTE
        ;;  SUBROUTINE CALLS, SO WE'LL USE RET RATHER THAN RETI
        
        .ORG    08H     ; RST 08H
        JP      DRST08  ; DEBUG -- OUTPUT PC OF CALLING RST 08H TO DS4L/R
    
        .ORG    10H     ; RST 10H
        RET             ; UNUSED
    
        .ORG    18H     ; RST 18H
        RET             ; UNUSED
    
        .ORG    20H     ; RST 20H
        RET             ; UNUSED
    
        .ORG    28H     ; RST 28H
        RET             ; UNUSED
    
        .ORG    30H     ; RST 30H
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

#INCLUDE "rom2ram.asm"      ; INLINED

        ;; INITIALIZE SIO CHANNEL A ("CONSOLE") TO 9600 BAUD E-7-1
        CALL    CONINIT

        ;; BOOT SPLASH
        CALL    INLPRT
        .TEXT   "Firefly Z80 Rev 1\n\r"
        .TEXT   "BIOS 0.0\n\r"
        .TEXT   "William D. Ezell\n\r"
        .TEXT   "2017-2020\n\r\n\r\n\r\000"

        ;; THE LOWER THREE (3) BITS OF THE BYTE READABLE FROM THE
        ;;  SYSCONFIG PORT (PORT 0) ALLOW FOR THE SELECTION OF EIGHT (8)
        ;;  USER-SELECTABLE ROUTINES.
        ;;
        ;; READ CONFIG SWITCH, GET BOOT MODE & ROUTE EXECUTION TO PATH
        ;;  SELECTED BY ONBOARD CONFIG SWITCH
        IN      A,(SYSCFG)
        AND     00000111B   ; MASK OFF THE BITS WE DON'T CARE ABOUT

        ;; TRANSFER EXECUTION TO ROUTINE RESPONSIBLE FOR MANAGING
        ;;  SELECTED BOOT MODE
        CALL    BOOTJP

        ;; IF WE REACH THIS POINT TABLE DISPATCH RETURNED WITH AN ERROR (CARRY SET)
        HALT                ; TO-DO:  INDICATE AN ERROR OR SOMETHING
        JR      $

;; -------------------------------------------------------------
;; BOOT MODE INITIALIZERS
;;   EACH WILL FURTHER HANDLE SETUP AND LAUNCH FOR RESPECTIVE
;;   FUNCTIONAL MODE
;; -------------------------------------------------------------
#INCLUDE "boot0.asm"        ; DIAGNOSTICS
#INCLUDE "boot1.asm"
#INCLUDE "boot2.asm"
#INCLUDE "boot3.asm"
#INCLUDE "boot4.asm"
#INCLUDE "boot5.asm"
#INCLUDE "boot6.asm"
#INCLUDE "boot7.asm"

;; -------------------------------------------------------------
;; SUPPORT ROUTINES
;; -------------------------------------------------------------
#INCLUDE "hwdefs.asm"       ;; I/O MAP AND HARDWARE CONSTANTS FOR THE REV 1 BOARD
#INCLUDE "memdefs.asm"      ;  MEMORY MAP FOR THE REV 1 BOARD
#INCLUDE "bootdsp.asm"      ;; SWITCH-DISPATCHED BOOT MENU
#INCLUDE "bioscore.asm"     ;; ROUTINES OF GENERAL PURPOSE TO MOST BOOT MODES
#INCLUDE "dbgutils.asm"     ;; MISC DEBUG TOOLS


;; -------------------------------------------------------------
;; END OF THE LINE MINUTIA
;; -------------------------------------------------------------
        ;; GENERATE AN INVALID STATEMENT TO THROW AN ERROR IF WATERLINE IS EXCEEDED
        ;;  THIS ALLOWS EASY INCREMENTAL FEATURE ADDITION WITHOUT WORRYING ABOUT CODE SIZE

#IF ( $ >= (ROMEND - 1024 ))    ;; WARN AT 31K (EVENTUALLY SET TO 32K)
        !!! CODE SIZE LIMIT EXCEEDED
#ENDIF

        .ORG     ROMCHK-21
        .DB     "WDEZELL FIREFLY REV 1"

        ;; FORCE TASM TO TOUCH A SINGLE BYTE AT THE END OF ROM IN ORDER
        ;; TO GENERATE IMAGE SIZED EXACTLY FOR THE ROM, ELSE CODE GENERATION
        ;; WILL STOP AFTER THE LAST INSTRUCTION OR DATA BLOCK DEFINITION.
        ;; -------------------------------------------------------------
ROMCHK: .ORG    ROMEND-1
        .CHK    LOWMEM  ; BYTE VALUE = CHECKSUM FROM ADDRESS 00H THRU PREV BYTE
        .END



