DBGMKY: .EQU    $

        ;; THE DEBUG MONKEY
IF 1
        ;; THIS FILE IS A FREE-FORM SCRATCH PAD TO INVOKE / TEST WHATEVER WITHOUT
        ;; BREAKING MAINLINE CODE.  WE WLL BE CALLED FROM THE MON> PROMPT BY THE
        ;; HIDDEN '.' COMMAND
        ;;
        ;; CONBUF AND SMPB0-6 ARE AVAILABLE OR WHATEVER ELSE.
        ;;

        CALL    PRINL
        .TEXT   CR,LF,"THE MONKEY NEEDS SOMETHING TO DO",CR,LF,NULL

IF 0

DMPBD:  ;; SIMPLE DISPLAY OF WHAT THE BUFFERS HAVE IN THEM
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
ENDIF


ENDIF
        ; CLEAR ACTIVE COMMAND REFERENCE
        CALL    SMCCC
        RET
