
IF 1
        ;; THIS FILE IS A FREE-FORM SCRATCH PAD TO INVOKE / TEST WHATEVER WITHOUT
        ;; BREAKING MAINLINE CODE.  WE WLL BE CALLED FROM THE MON> PROMPT BY THE
        ;; HIDDEN '.' COMMAND
        ;;
        ;; CONBUF AND SMPB1-6 ARE AVAILABLE OR WHATEVER ELSE. SMPB0 WILL ALWAYS BE '.'
        ;;

        ;; ------------------------------------------------------------------------

        ; TESTING DLY25B
        LD      HL, SMPB1   ; DELAY COUNT PASSED IN AS PARAM
        CALL    TOINT       ; CONVERT
        JR      NC,_DM1     ; CONVERSION ERROR

        LD      A,D         ; LIMIT TO 0-255
        CP      0
        JR      NZ,_DM2     ; HIGH BYTE WAS NON-ZERO

        CALL    PRINL
        .TEXT   CR,LF,"  START",CR,LF,NULL

        LD      B,E         ; DELAY COUNT INTO B
        CALL    DLY25B

        CALL    PRINL
        .TEXT   "  STOP",CR,LF,CR,LF,NULL

        JR      _DMFIN

_DM1:   CALL    PRINL
        .TEXT   CR,LF,CR,LF,"NUMERIC CONVERSION ERROR",CR,LF,NULL
        JP      ABEND

_DM2:   CALL    PRINL
        .TEXT   CR,LF,CR,LF,"PARAM MUST BE 0-255",CR,LF,NULL
        JP      ABEND

_DMFIN: .EQU $

        ; ------------------------------------------------------
ELSE
        CALL    PRINL
        .TEXT   CR,LF,"THE MONKEY HAS NOTHING TO DO",CR,LF,NULL

ENDIF

