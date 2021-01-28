
        ;; COMMAND VALIDATION AND HANDLER DISPATCH
        ;;
        ;;  USER INPUT IS CHECKED AGAINST A LIST OF VALID COMMANDS.
        ;;  IF FOUND TO BE A LEGAL COMMAND, THE POSITION OF THE COMMAND
        ;;  IN THE VALIDATION REFERENCE STRING IS USED AS AN INDEX INTO
        ;;  THE COMMAND HANDLER DISPATCH TABLE.
        ;;
        ;;  FURTHER VALIDATION OF PARAMETERS (IF ANY) IS DEFERRED TO THE
        ;;  RESPECTIVE COMMAND HANDLER.
        ;;
        ;; -------------------------------------------------------------
SMVAD:  .EQU    $

        ;; VALIDATE COMMAND AND GET POSITION INDEX   (MAYBE MOVE TOUPPER HERE, YES? IS GOOD IDEA.)
        LD      HL,SMPB0    ; GET FIRST CHAR FROM COMMAND BUFFER INTO REG A
        LD      A,(HL)
        ;CALL    TOUPPER    ; NOTE - CALL HERE INSTEAD OF IN PARSE IF CMD-ONLY CASE CONVERSION
        LD      HL,SMVCMDS  ; POINT HL TO ORDERED LIST OF VALID COMMANDS
        LD      BC,SMVCMCT  ; SET SEARCH COUNTER TO NUMBER OF COMMANDS
        CPIR                ; SEARCH LIST FOR COMMAND MATCHING CHARACTER IN REG A
        JR      Z,_SMVM     ; WE MATCHED A VALID COMMAND
        LD      HL,SMERR01  ; NO MATCH - DISPLAY ERROR MESSAGE
        CALL    SMPRSE
        RET

        ;; COMMAND VALID - DERIVE DISPATCH INDEX FROM COMMAND POSITION IN REFERENCE LIST
_SMVM:  LD      HL,SMCURCM  ; UPDATE 'CURRENT COMMAND' REFERENCE BYTE
        LD      (HL),A
        LD      A,SMVCMCT-1 ; GET COUNT OF TOTAL COMMANDS IN A, ADJUST FOR ZERO-BASED TABLE INDEX
        SUB     C           ; SUBTRACT 'TRIES REMAINING' COUNT (B IS ZERO SO JUST LOOK AT C)

        ;; DISPATCH HANDLER FOR COMMAND
        LD      HL,SMCMTAB  ; POINT TO START OF DISPATCH TABLE
        LD      B,SMVCMCT   ; NUMBER OF ENTRIES IN TABLE
        CALL    TABDSP      ; INVOKE COMMAND HANDLER
        RET


_SMVDZ: ;; -- BEGIN DEBUG  -- MOD TO DO THIS FOR ~ COMMAND      TODO: REPLACE THIS WITH BETTER
        ;; SIMPLE DISPLAY OF WHAT THE BUFFERS HAVE IN THEM
        ;CALL    CLSVT
        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"DEBUG - INPUT AND PARSE BUFFERS:",CR,LF,NULL

        CALL    PRINL
        .TEXT   CR,LF,"CONBUF: ",NULL
        LD      HL,CONBUF
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMPB0: ",NULL
        LD      HL,SMPB0
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMPB1: ",NULL
        LD      HL,SMPB1
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMPB2: ",NULL
        LD      HL,SMPB2
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMPB3: ",NULL
        LD      HL,SMPB3
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMPB4: ",NULL
        LD      HL,SMPB4
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMPB5: ",NULL
        LD      HL,SMPB5
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,"SMPB6: ",NULL
        LD      HL,SMPB6
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,NULL
        RST     10H

        ; CLEAR ACTIVE COMMAND REFERENCE
        CALL    SMCCC
        RET
        ;; -- END DEBUG


        ;; VALIDATION AND DISPATCH WORKING STORAGE
SMCURCM:.DB     ' '                     ; CURRENT COMMAND MODE
SMVCMDS:.TEXT   ".?BCEFGHIMORTW"        ; VALID MAIN MENU COMMANDS
SMVCMCT:.EQU    $-SMVCMDS               ; COUNT OF COMMANDS

        ; MAIN MENU COMMAND HANDLER DISPATCH TABLE
SMCMTAB:.DW     _SMVDZ                  ; HANDLER FOR '.' (HIDDEN DEBUG MONKEY)
        .DW     SMMENU                  ; ?
        .DW     SMCMDB                  ; B
        .DW     SMCMDC                  ; C
        .DW     SMCMDE                  ; E
        .DW     SMCMDF                  ; F
        .DW     SMCMDG                  ; G
        .DW     SMCMDH                  ; H
        .DW     SMCMDI                  ; I
        .DW     SMCMDM                  ; M
        .DW     SMCMDO                  ; O
        .DW     SMCMDR                  ; R
        .DW     SMCMDT                  ; T
        .DW     SMCMDW                  ; W

        ; DISPATCH TABLE ENTRIES MUST MATCH NUMBER OF COMMANDS (AND ORDER)
        ASSERT( ($ - SMCMTAB)/2 = SMVCMCT )

        ;; STUBS FOR COMMAND HANDLERS - MOVE TO INDIVIDUAL SOURCE FILES AS IMPLEMENTED
        ;; -------------------------------------------------------------
SMCMDB: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'B' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDC: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'C' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDE: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'E' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDF: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'F' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDG: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'G' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDH: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'H' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDI: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'I' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDM: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'M' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDO: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'O' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDR: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'R' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDT: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'T' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDW: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'W' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
SMCMDX: CALL    PRINL
        .TEXT   CR,LF,"COMMAND 'X' NOT YET IMPLEMENTED",NULL
        CALL    SMCCC
        RET
        
        ;; -------------------------------------------------------------
        ;; END -- COMMAND VALIDATION AND HANDLER DISPATCH
