
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
    ;;    1) DEFINES AND CONFIGURES THE ARCHITECTURAL PRIMITIVES NECESSARY
    ;;        FOR THE STARTUP OF THE ZILOG Z80 PROCESSOR, NAMELY ESTABLISHMENT
    ;;        OF PAGE ZERO INTERRUPT VECTOR STRUCTURE AND EXECUTABLE CODE AT
    ;;        LOCATION ZERO.
    ;;
    ;;    2) COPIES THE ENTIRE ROM IMAGE INTO THE UPPER 32K OF MEMORY,
    ;;        TOGGLES RAM INTO THE LOWER 32K IN PLACE OF THE ROM, COPIES
    ;;        THE DUPLICATED ROM CONTENTS BACK DOWN INTO THE ORIGINAL ADDRESS
    ;;        RANGE (NOW RAM), AND CLEARS THE UPPER 32K OF MEMORY. FINALLY,
    ;;        INITIAL BIOS AND SYSTEM MONITOR COMPONENTS ARE INSTALLED INTO
    ;;        EXECUTION MEMORY ADDRESS RANGES.
    ;;
    ;;        ROM IS NOW PERMANENTLY OFFLINE UNTIL A COLD RESET OR POWER CYCLE.
    ;;
    ;;    3) PERFORMS BASIC HARDWARE INITIALIZATION, PRIMARILY CONFIGURING A
    ;;        STACK AND SETTING SIO CHANNEL A AS A SERIAL CONSOLE FOR USER INTERACTION.
    ;;
    ;;    4) HANDS OFF FURTHER INITIALIZATION/EXECUTION TO ONE OF EIGHT
    ;;        MODE-SPECIFIC BOOT HANDLERS. BOOT MODE 0 IS THE DEFAULT AND
    ;;        SERVES PRIMARILY AS AN INTERACTIVE SYSTEM MONITOR.  OTHER (AVAILABLE)
    ;;        BOOT MODES MAY BE LAUNCHED FROM HERE VIA COMMAND.  HOWEVER,
    ;;        IF YOU ALWAYS WANT A CERTAIN MODE (E.G., CP/M) SET IT BY THE SWITCH.
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
RESRV1: .DB     0       ; USED BY BIOS DEBUG AIDS
RESRV2: .DB     0       ;
RESRV3: .DB     0       ;
RESRV4: .DB     0       ;

;; -------------------------------------------------------------
;; ZERO PAGE JUMP VECTORS & INTERRUPT HANDLERS
;; -------------------------------------------------------------
        ;; MODE 0 MASKABLE INTERRUPT VECTORS
        ;;  WE'RE NOT GOING TO USE IM0 BUT RATHER USE AS 1-BYTE
        ;;  SUBROUTINE CALLS, SO WE'LL USE RET RATHER THAN RETI
        
        .ORG    08H     ; RST 08H
        JP      DEBG08  ; DEBUG -- OUTPUT ADDRESS,ACCUMULATOR TO DS4L/R AND DS2
    
        .ORG    10H     ; RST 10H
        JP      DEBG10  ; DEBUG -- MORE COMPLETE DEBUG OUTPUT TO CONSOLE
    
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

    ;; 45 FREE BYTES HERE W/ CURRENT 38HNULL HANDLER
        
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

IMPORT "initmmgr.asm"

        ;; INITIALIZE SIO CHANNEL A ("CONSOLE") TO 9600 BAUD N-8-1
        CALL    CONINIT

        CALL    CLSVT       ; CLEAR SCREEN FOR VT-52 COMPATIBLE TERM
        CALL    CLSA3       ; CLEAR SCREEN FOR ADM-3A COMPATIBLE TERM
        CALL    CLDBDS      ; CLEAR FLOATING GARBAGE ON DEBUG DISPLAYS

        ;; BOOT SPLASH
        CALL    PRINL
        .TEXT   CR,LF,"Firefly Z80 Revison 1",CR,LF
        .TEXT   "BIOS 0.3",CR,LF
        .TEXT   "William D. Ezell  2017-2020",CR,LF,CR,LF,NULL


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
        JP      ABEND

;; -------------------------------------------------------------
;; BOOT MODE INITIALIZERS
;;   EACH WILL FURTHER HANDLE SETUP AND LAUNCH FOR RESPECTIVE
;;   FUNCTIONAL MODE
;; -------------------------------------------------------------

        ;; DISPATCH TABLE FOR BOOT MODE SWITCH
        ;;
BSWTAB: .EQU    $           ; BOOT SWITCH JUMP TABLE
        .DW     BOOT0       ; SYSTEM MONITOR
        .DW     BOOT1       ; TBD - REPORT AS UNASSIGNED
        .DW     BOOT2       ; TBD - REPORT AS UNASSIGNED
        .DW     BOOT3       ; TBD - REPORT AS UNASSIGNED
        .DW     BOOT4       ; TBD - REPORT AS UNASSIGNED
        .DW     BOOT5       ; TBD - REPORT AS UNASSIGNED
        .DW     BOOT6       ; TBD - REPORT AS UNASSIGNED
        .DW     BOOT7       ; TBD - REPORT AS UNASSIGNED

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
        ;; SIZED EXACTLY FOR THE ROM, ELSE CODE GENERATION WILL STOP AFTER
        ;; THE LAST INSTRUCTION OR DATA BLOCK DEFINITION.
        ;; -------------------------------------------------------------
        .ORG    ROMEND
        .DB     0

;; EQUATES
IMPORT "hwdefs.asm"
IMPORT "memmap.asm"

        .END                ; CONCLUSION OF ROM CODE

