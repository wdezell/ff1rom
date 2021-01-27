
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

        ;; TODO -- YOU ARE HERE

_SMVDZ: ;; -- BEGIN DEBUG
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
        ;; -- END DEBUG
        RET


        ;; VALIDATION AND DISPATCH WORKING STORAGE
SMCURCM:.DB     ' '                     ; CURRENT COMMAND MODE
SMVCMDS:.TEXT   "?BCEFGHIMORTWX"        ; VALID MAIN MENU COMMANDS IN UPPERCASE
SMVCMCT:.EQU    $-SMVCMDS               ; COUNT OF COMMANDS

        ; MAIN MENU COMMAND HANDLER DISPATCH TABLE
SMCMTAB:.DW     SMDUMMY                 ; ADDRESS FOR COMMAND HANDLER FOR '?'
        .DW     SMDUMMY                 ; B
        .DW     SMDUMMY                 ; C
        .DW     SMDUMMY                 ; E
        .DW     SMDUMMY                 ; F
        .DW     SMDUMMY                 ; G
        .DW     SMDUMMY                 ; H
        .DW     SMDUMMY                 ; I
        .DW     SMDUMMY                 ; M
        .DW     SMDUMMY                 ; O
        .DW     SMDUMMY                 ; R
        .DW     SMDUMMY                 ; T
        .DW     SMDUMMY                 ; W
        .DW     SMDUMMY                 ; X

        ; DISPATCH TABLE ENTRIES MUST MATCH ORDER AND NUMBER OF COMMANDS
        ASSERT( ($ - SMCMTAB)/2 = SMVCMCT )

SMDUMMY:.EQU    $                       ; DUMMY ADDRESS -- DELETE AS HAVE IMPLEMENTATIONS

        ;; -------------------------------------------------------------
        ;; END -- COMMAND VALIDATION AND HANDLER DISPATCH
