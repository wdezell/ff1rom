;;----------------------------------------------------------------------
;; INITIAL MEMORY MANAGER -- INLINED CODE PERFORMING THE FOLLOWING TASKS:
;;
;;  1) REPLACE LOWER 32K MEMORY WITH AN EXACT IMAGE OF ROM BUT IN RAM
;;  2) INSTALL COMPONENTS CARRIED IN ROM TO EXECUTION LOCATIONS
;;     IN RAM (TYPICALLY UPPER 32K REGION)
;;
;;----------------------------------------------------------------------

ROM2RAM:    .EQU    $
        ;; -------------------------------------------------------------
        ;; REPLACE ROM IN LOWMEM WITH A FULL COPY OF BOOTROM IMAGE
        ;;  RUNNING IN RAM (SKIP COPY/SWAP IF RAM IS ALREADY ACTIVE,
        ;;  CURRENT HIMEM CONTENTS WILL NOT BE DISRUPTED)
        ;;
        ;;  USAGE:  INLINE INCLUSION  (NO STACK ALLOWED YET)
        ;; -------------------------------------------------------------

        ;; SEE IF FLAG SAYS WE'VE ALREADY GOT RAM IN LOWMEM
        LD      A,(IS_RAM)
        CP      0           ; DOES IT MATCH THE ROM DEFAULT VALUE? (RAM = ANYTHING BUT 0)
        JR      NZ,_NXTLN   ; NOT ROM DEFAULT VALUE OF 0, MUST ALREADY HAVE RAM ENABLED SO SKIP SWAP

        ;; COPY LOWER 32K ROM TO UPPER 32K RAM
        LD      HL,ROMBEG   ; HL = SOURCE STARTING ADDRESS
        LD      DE,HIMEM    ; DE = DESTINATION STARTING ADDRESS
        LD      BC,ROMSIZ   ; SET NUMBER OF BYTES TO COPY
        LDIR                ; COPY

        ;; NOW THERE'S AN EXACT COPY OF THE BOOT ROM IMAGE IN HIGH MEMORY 8000H-FFFFH

        ;; EXECUTE THE "NEXT" LINE OF CODE -- BUT NOT THE ONE IN LOWMEM ROM, THE ONE UP IN THE HIMEM RAM
        ;; COPY.  THIS STEP MOVES EXECUTION OUT OF LOW MEMORY SO THE BANK SWITCH DOESN'T PULL THE RUG
        ;; OUT FROM UNDER US.
        JP      $+3+ROMSIZ  ; ABSOLUTE JUMP = 3 BYTES ($, $+1, AND $+2).  JUMP TO CODE AT 'HERE' + 3 + 32K OFFSET

        ;; NOW THAT WE'RE RUNNING IN HIMEM SWAP OUT ROM FOR RAM BY WRITING TO THE CONTROL PORT (ANY VALUE WILL DO)
        OUT     (RAMCTL),A

        ;; COPY EVERYTHING BACK TO LOW-MEMORY WHICH IS NOW RAM
        LD      HL,HIMEM
        LD      DE,LOWMEM
        LD      BC,ROMSIZ
        LDIR

        ;; AND CHANGE ROM/RAM CANARY VALUE FROM ROM DEFAULT OF 0 TO RAM INDICATOR OF 1
        LD      A,1
        LD      (IS_RAM),A
        LD      A,(IS_RAM)  ; VERIFY
        CP      0           ; ROM-DEFAULT VALUE OF 0
        JP      NZ,_WIPE    ; IS RAM - LONG JUMP TO THE LOWMEM VERSION MEM WIPE

        HALT                ; ROM/RAM SWAP FAILED -- HALT
        JR      $

        ;; WIPE UPPER MEMORY TO CLEAR TEMP COPY OF ROM, LEAVE NEAT AND TIDY
_WIPE:  LD      A,0         ; PUT A ZERO IN THE FIRST BYTE OF UPPER MEMORY
        LD      (HIMEM),A
        LD      HL,HIMEM    ; AND DUPLICATE IT INTO THE REST
        LD      DE,HIMEM+1
        LD      BC,HIMSIZ-1
        LDIR

_NXTLN: .EQU $              ; WHEN ASSEMBLED THIS LABEL MARKED THE NEXT ADDRESS IN LOWMEM

        ;; --------------------- END ROM2RAM ---------------------------

        ;; --------------------- UNPACK --------------------------------
        ; INSTALL ROM COMPONENTS TO EXECUTION LOCATIONS
        LD      HL,BBIOSS   ; ROM COPY OF BOARD BIOS CODE
        LD      DE,BBIOS    ; GOES HERE IN RAM
        LD      BC,BBSIZ    ; THIS MANY BYTES
        LDIR                ; COPY IT THERE

        LD      HL,GUTLSS   ; GENERAL UTILITIES
        LD      DE,GUTLS
        LD      BC,GUSIZ
        LDIR

        LD      HL,DBGUTS   ; DEBUG UTILITIES
        LD      DE,DBGUTL
        LD      BC,DBSIZ
        LDIR

        ; AND CLEAR THE LOWMEM LOCATIONS THAT HELD THE UNINSTALLED CODE
        LD      A,0         ; PUT A ZERO IN THE FIRST BYTE OF SRC BLOCK
        LD      (BBIOSS),A  ;
        LD      HL,BBIOSS   ; SET SOURCE ADDRESS
        LD      DE,BBIOSS   ; SET DEST ADDRESS (OK TO BE SAME)
        LD      BC,BBSIZ    ; SET SIZE OF BLOCK
        LDIR                ; ZERO FILL

        LD      A,0         ;
        LD      (GUTLSS),A  ;
        LD      HL,GUTLSS   ;
        LD      DE,GUTLSS   ;
        LD      BC,GUSIZ    ;
        LDIR                ;

        LD      A,0         ;
        LD      (DBGUTS),A  ;
        LD      HL,DBGUTS   ;
        LD      DE,DBGUTS   ;
        LD      BC,DBSIZ    ;
        LDIR                ;

        ;; --------------------- END UNPACK ----------------------------
