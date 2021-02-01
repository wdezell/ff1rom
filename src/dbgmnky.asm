
IF 0
        ;; THIS FILE IS A FREE-FORM SCRATCH PAD TO INVOKE / TEST WHATEVER WITHOUT
        ;; BREAKING MAINLINE CODE.  WE WLL BE CALLED FROM THE MON> PROMPT BY THE
        ;; HIDDEN '.' COMMAND
        ;;
        ;; CONBUF AND SMPB1-6 ARE AVAILABLE OR WHATEVER ELSE. SMPB0 WILL ALWAYS BE '.'
        ;;

        CALL    PRINL
        .TEXT   CR,LF,"THE MONKEY HAS NOTHING TO DO",CR,LF,NULL

ENDIF

IF 1
        ; VERIFY STRLEN USING CONBUF AS REFERENCE
        CALL    PRINL
        .TEXT   CR,LF,"CONBUF: ",NULL
        LD      HL,CONBUF
        CALL    PRSTRZ

        LD      HL,CONBUF
        CALL    STRLEN

        RST     10H


ENDIF

IF 0
        ;; TEST M168U
        ;;

        CALL    PRINL
        .TEXT   CR,LF,"TEST:  $3FB8(DE) x $2(A) = $7F70(A:HL)",CR,LF,NULL

        ;; INPUT:               OUTPUT:
        ;;  A = MULTIPLIER       A:HL = PRODUCT
        ;;  DE = MULTIPLICAND
        ;;  HL = 0
        ;;  C = 0
        LD      DE,16312    ; LESS THAN 1/2 32768
        LD      A,2
        LD      C,0
        LD      HL,0

        RST     10H         ; DUMP
        CALL    M168U       ; MULTIPLY
        RST     10H         ; DUMP

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,NULL

        ;; TEST M1616U
        ;;

        CALL    PRINL
        .TEXT   CR,LF,"TEST:  $7918(DE) x $2(BC) = $F230(DE:HL)",CR,LF,NULL

        ;; INPUT:                OUTPUT:
        ;;  DE = MULTIPLIER       DE:HL = PRODUCT
        ;;  BC = MULTIPLICAND
        ;;  HL = 0
        LD      DE,31000
        LD      BC,2
        LD      HL,0

        RST     10H         ; DUMP
        CALL    M1616U      ; MULTIPLY
        RST     10H         ; DUMP

        CALL    PRINL
        .TEXT   CR,LF,CR,LF,"PRESS ANY KEY",NULL

        CALL    CONCIN

ENDIF

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

