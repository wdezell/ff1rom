
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
        RST     10H
        CALL    TABDSP      ; INVOKE COMMAND HANDLER
        RET


_SMVDZ: ;; -- BEGIN DEBUG  -- MOD TO DO THIS FOR ~ COMMAND
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
SMVCMDS:.TEXT   ".?BCEFGHIMORTWX"       ; VALID MAIN MENU COMMANDS
SMVCMCT:.EQU    $-SMVCMDS               ; COUNT OF COMMANDS

        ; MAIN MENU COMMAND HANDLER DISPATCH TABLE
SMCMTAB:.DW     _SMVDZ                  ; HANDLER FOR '.' (HIDDEN DEBUG MONKEY)
        .DW     SMMENU                  ; ?
        .DW     SMCNYI                  ; B
        .DW     SMCNYI                  ; C
        .DW     SMCNYI                  ; E
        .DW     SMCNYI                  ; F
        .DW     SMCNYI                  ; G
        .DW     SMCNYI                  ; H
        .DW     SMCNYI                  ; I
        .DW     SMCNYI                  ; M
        .DW     SMCNYI                  ; O
        .DW     SMCNYI                  ; R
        .DW     SMCNYI                  ; T
        .DW     SMCNYI                  ; W
        .DW     SMCNYI                  ; X

        ; DISPATCH TABLE ENTRIES MUST MATCH NUMBER OF COMMANDS (AND ORDER)
        ASSERT( ($ - SMCMTAB)/2 = SMVCMCT )

        ;; DISPLAY SIMPLE 'NOT YET IMPLEMENTED' MESSAGE FOR COMMAND
        ;; -------------------------------------------------------------
SMCNYI: LD      HL,SMERR03
        CALL    SMPRSE
        AND     A           ; CLEAR CARRY AND ERROR STATUS
        RET
        
        ;; -------------------------------------------------------------
        ;; END -- COMMAND VALIDATION AND HANDLER DISPATCH
