
IF 0
        ;; THIS FILE IS A FREE-FORM SCRATCH PAD TO INVOKE / TEST WHATEVER WITHOUT
        ;; BREAKING MAINLINE CODE.  WE WLL BE CALLED FROM THE MON> PROMPT BY THE
        ;; HIDDEN '.' COMMAND
        ;;
        ;; CONBUF AND SMPB1-6 ARE AVAILABLE OR WHATEVER ELSE. SMPB0 WILL ALWAYS BE '.'
        ;;

        ;; ------------------------------------------------------------------------

IF 0
        ; RE-VERIFY M168U
        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"RE-TESTING M168U.",CR,LF
        .TEXT   "9 X 2634 = 23706  [9, A4A,5C9A]",CR,LF,NULL

        LD      DE,0A4AH
        LD      A,9
        CALL    M168U
        RST     10H
ENDIF
        ; TEST TOINT PARSING OF SMPB1, SMPB2 SMPB 3, SMPB4, AND SMPB5
        ; USAGE: . # #D #H #0 #B
        CALL    PRINL
        .TEXT   CR,LF,"CONBUF: ",NULL

        LD      HL,CONBUF
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,NULL
        ; ----------------------

        CALL    PRINL
        .TEXT   CR,LF,"SMPB1: ",NULL

        LD      HL,SMPB1
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,NULL

        LD      HL, SMPB1
        CALL    TOINT
        RST     10H
        ; ----------------------

        CALL    PRINL
        .TEXT   CR,LF,"SMPB2: ",NULL

        LD      HL,SMPB2
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,NULL

        LD      HL, SMPB2
        CALL    TOINT
        RST     10H
        ; ----------------------

        CALL    PRINL
        .TEXT   CR,LF,"SMPB3: ",NULL

        LD      HL,SMPB3
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,NULL

        LD      HL, SMPB3
        CALL    TOINT
        RST     10H
        ; ----------------------

        CALL    PRINL
        .TEXT   CR,LF,"SMPB4: ",NULL

        LD      HL,SMPB4
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,NULL

        LD      HL, SMPB4
        CALL    TOINT
        RST     10H
        ; ----------------------

        CALL    PRINL
        .TEXT   CR,LF,"SMPB5: ",NULL

        LD      HL,SMPB5
        CALL    PRSTRZ

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,NULL

        LD      HL, SMPB5
        CALL    TOINT
        RST     10H


        ; ------------------------------------------------------
ELSE
        CALL    PRINL
        .TEXT   CR,LF,"THE MONKEY HAS NOTHING TO DO",CR,LF,NULL

ENDIF

