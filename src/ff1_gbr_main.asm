
    ;;***********************************************************************
    ;;
    ;;  PROGRAM:  FF1GBR_MAIN -- GENERAL BOOT ROM FOR THE WDE8016 'FIREFLY' 
    ;;                           REVISION 1 BOARD
    ;;           
    ;;  AUTHOR:   WILLIAM D. EZELL      
    ;;  DATE:
    ;;
    ;;  ASSEMBLED USING 'ZMAC'
    ;;      zmac -P --oo lst,hex,cim ff1_gbr_main.asm
    ;;
    ;;  SOURCE FORMATTING NOTE:
    ;;    USING SOFT TABS @ 4 SPACES FOR COLUMNAR ALIGNMENT
    ;;    OPCODE IN COL 9, OPERAND IN COL 17, COMMENTS COL 25 OR 29 TYP
    ;;
    ;;
    ;;     #####   #######  #     #  #######  ######
    ;;    #     #  #     #  ##    #  #     #  #     #
    ;;    #        #     #  # #   #  #     #  #     #
    ;;    #        #     #  #  #  #  #     #  ######
    ;;    #        #     #  #   # #  #     #  #
    ;;    #     #  #     #  #    ##  #     #  #
    ;;     #####   #######  #     #  #######  #
    ;;
    ;;  THIS "BIOS" IS A BASKET, HOLDING MANY PIECES AND PRODUCING SEVERAL
    ;;  FINAL MEMORY CONFIGURATIONS.  THE "BASKET" IS A 32K ROM AND THE
    ;;  CONTIGUOUS LAYOUT PRESENTED BY THIS ASSEMBLED ROM IMAGE IS *NOT*
    ;;  REPRESENTATIVE OF HOW A GIVEN BOOTED MEMORY MAP WILL LOOK. THERE
    ;;  ALSO WILL LIKELY BE SOME REDUNDANCY IN THE BASKET BUT, SO LONG AS WE
    ;;  HAVE ADEQUATE SPACE, IT'S NOT WORTH THE EFFORT TO OPTIMIZE.
    ;;
    ;;  THE FIREFLY BOARD IS DESIGNED TO OPERATE IN MULTIPLE MODES, MAINLY TO
    ;;  SIMPLIFY DIFFERENT APPLICATIONS.  EIGHT (8) PRIMARY "BOOT MODES" ARE
    ;;  INDIVIDUALLY SELECTABLE BY THE THREE LOW-ORDER SWITCHES READABLE
    ;;  VIA PORT 0 -- REFERRED TO AS 'SYSCFG'.
    ;;
    ;;  THIS BIOS PERFORMS THE FOLLOWING FUNCTIONS:
    ;;
    ;;    1) IT DEFINES AND CONFIGURES THE ARCHITECTURAL PRIMITIVES NECESSARY
    ;;        FOR THE STARTUP OF THE ZILOG Z80 PROCESSOR, NAMELY ESTABLISHMENT
    ;;        OF PAGE ZERO INTERRUPT VECTOR STRUCTURE AND EXECUTABLE CODE AT
    ;;        LOCATION ZERO.
    ;;
    ;;    2) IT COPIES THE ENTIRE ROM IMAGE INTO RAM AT THE SAME LOCATION,
    ;;        "TURNS OFF" THE ROM, AND CLEARS THE UPPER 32K OF MEMORY.
    ;;        EXECUTION CONTINUES TRANSPARENTLY IN THE RAM-IMAGE COPY.
    ;;        A STACK IS ALSO DEFINED AT THE TOP OF RAM AT THIS POINT.
    ;;
    ;;    3) IT PERFORMS BASIC HARDWARE INITIALIZATION, PRIMARILY CONFIGURING
    ;;        SIO CHANNEL A AS A SERIAL CONSOLE FOR USER INTERACTION
    ;;
    ;;    4) IT HANDS OFF FURTHER INITIALIZATION/EXECUTION TO ONE OF EIGHT
    ;;        MODE-SPECIFIC BOOT HANDLERS. BOOT MODE 0 IS THE DEFAULT AND
    ;;        PRESENTS AN OPTION TO SELECT OTHERS VIA KEYBOARD INTERACTION
    ;;        BUT IF YOU ALWAYS WANT A CERTAIN MODE (E.G., CP/M) SET IT BY
    ;;        THE SWITCH.
    ;;
    ;;  WHAT A GIVEN BOOT HANDLER DOES IS ENTIRELY UP TO THE PURPOSE AND
    ;;  REQUIREMENTS OF THE BOOT MODE.  AS THE ROM IMAGE "BASKET" EXISTS IN
    ;;  RAM AT THIS POINT IT IS SUBJECT TO BE MODIFIED, REARRANGED, OR ERASED.
    ;;  SOME OF THE BOOT MODES WILL RUN CODE CONTAINED IN THIS IMAGE AND MAY
    ;;  USE UTILITY ROUTINES AS-IS.  OTHER BOOT MODES MAY "CHERRY PICK" AND
    ;;  RELOCATE SELECTED ROUTINES ELSEWHERE IN MEMORY IF THE ROUTINES ARE SO
    ;;  WRITTEN AS TO BE RELOCATABLE.  THE CP/M LOADER AND HEX MONITOR BOOT
    ;;  MODE HANDLERS ARE EXAMPLES OF THIS BEHAVIOR.
    ;;
    ;;  NOTE:  TASM REGRETABLY DOES NOT FULLY SUPPORT RELOCATABLE ASSEMBLY SO
    ;;         SOME KLUDGY SUB-OPTIMAL TRICKERY IS EMPLOYED. BUT IT WORKS.
    ;;
    ;; ***********************************************************************
        .TITLE "FF-ROM -- SYSTEM ROM FOR THE WDE8016 'FIREFLY' REV 1 BOARD"
        .Z80            ; USE Z80 MNEMONICS
;        .JPERROR 1      ; ADVISE IF CAN SHORTEN CODE

        ;; *** BOOTSTRAP ***
        .ORG    ROMBEG
        JP      RESET

        .ORG    03H

IS_RAM: .DB     0       ; USED BY ROM/RAM SWAP TO DETERMINE IF RAM ALREADY ACTIVE (0 = ROM)
SCRAT1: .DB     0       ; GENERAL USE SCRATCH BYTE
SCRAT2: .DB     0       ; GENERAL USE SCRATCH BYTE
SCRAT3: .DB     0       ; GENERAL USE SCRATCH BYTE
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
        LD      SP,STACK    ; INIT STACK POINTER SO WE CAN CALL SUBS

IMPORT "bldmemmap.asm"      ; INLINED

        ;; INITIALIZE SIO CHANNEL A ("CONSOLE") TO 9600 BAUD N-8-1
        CALL    CONINIT
        CALL    VTCLS       ; CLEAR SCREEN IF VT-52 COMPATIBLE TERM

        ;; BOOT SPLASH
        CALL    PRINL
        .TEXT   "\n\rFirefly Z80 Rev 1\n\r"
        .TEXT   "BIOS 0.2\n\r"
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
        LD      HL,BSWTAB   ; ADDRESS OF DISPATCH TABLE FOR BOOT SWITCH
        LD      B,8         ; NUMBER OF ENTRIES IN TABLE
        CALL    TABDSP

        ;; IF WE REACH THIS POINT TABLE DISPATCH RETURNED WITH AN ERROR (CARRY SET)
        RST     08H         ; OUTPUT OUR STOP LOCATION TO DEBUG DISPLAY
        HALT                ; TO-DO:  INDICATE AN ERROR OR SOMETHING
        JR      $

;; -------------------------------------------------------------
;; BOOT MODE INITIALIZERS
;;   EACH WILL FURTHER HANDLE SETUP AND LAUNCH FOR RESPECTIVE
;;   FUNCTIONAL MODE
;; -------------------------------------------------------------

        ;; DISPATCH TABLE FOR BOOT MODE SWITCH
        ;;
BSWTAB: .EQU    $           ; BOOT SWITCH JUMP TABLE
        .DW     BOOT0       ; CONSOLE MENU -- DIAGNOSTICS, BOARD UTILS, MONITOR, LAUNCH OTHER MODES
        .DW     SYSMNI      ; SYSTEM MONITOR VIA BOOT MODE 1 INSTALLER
        .DW     BOOT2       ; CP/M
        .DW     BOOT3       ; FORTH
        .DW     BOOT4       ; BASIC
        .DW     BOOT5       ; RESERVED
        .DW     BOOT6       ; RESERVED
        .DW     BOOT7       ; RESERVED

IMPORT "boot0.asm"
IMPORT "boot1.asm"
IMPORT "boot2.asm"
IMPORT "boot3.asm"
IMPORT "boot4.asm"
IMPORT "boot5.asm"
IMPORT "boot6.asm"
IMPORT "boot7.asm"

;; -------------------------------------------------------------
;; SUPPORT ROUTINES
;; -------------------------------------------------------------
IMPORT "bioscore.asm"       ;; CORE I/O
IMPORT "genutils.asm"       ;; GENERAL PURPOSE UTILTY ROUTINES
IMPORT "dbgutils.asm"       ;; MISC DEBUG TOOLS

;; -------------------------------------------------------------
;; END OF THE LINE MINUTIA
;; -------------------------------------------------------------
        ;; GENERATE AN INVALID STATEMENT TO THROW AN ERROR IF WATERLINE IS EXCEEDED
        ;;  THIS ALLOWS EASY INCREMENTAL FEATURE ADDITION WITHOUT WORRYING ABOUT CODE SIZE
        ;;
        ;; WARN AT 31K (EVENTUALLY SET TO 32K)
        ;;
        ASSERT ( $ < (ROMEND - 1024 ))  ;; *** ASSEMBLED CODE EXCEEDS WATERLINE ***

        .ORG     ROMEND-21
        .DB     "WDEZELL FIREFLY REV 1"

        ;; TOUCH A SINGLE BYTE AT THE END OF ROM IN ORDER TO GENERATE IMAGE
        ;; SIZED EXACTLY FOR THE ROM, ELSE CODE GENERATION WILL TOP AFTER
        ;; THE LAST INSTRUCTION OR DATA BLOCK DEFINITION.
        ;; -------------------------------------------------------------
        .ORG    ROMEND
        .DB     0

;; EQUATES
IMPORT "hwdefs.asm"
IMPORT "memdefs.asm"

        .END                ; CONCLUSION OF ROM CODE

