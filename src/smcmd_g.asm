
        ;; G(O)     EXECUTE AT MEMORY LOCATION SPECIFIED
        ;;
        ;; FORMAT:  G  ADDRESS
        ;;
        ;;   THE GO COMMAND TRANSFERS EXECUTION TO THE MEMORY LOCATION SPECIFIED.
        ;;   FURTHER BEHAVIOR, INCLUDING WHETHER CONTROL RETURNS TO THE MONITOR OR NOT,
        ;;   IS ENTIRELY DEPENDENT UPON THE CODE EXECUTED.
        ;;
        ;; --------------------------------------------------------------------------------

SMCMDG: .EQU    $

        ;; VALIDATE CALLED CONDITIONS
        ;;
        ;; --------------------------------------------------------------------------------
        ; VERIFY SMPB1 CONTAINS A VALID INT ADDRESS
        LD      HL,SMPB1    ; PARAM BUFFER 1
        CALL    STRLEN      ; CHECK FOR STRING LENGTH = 0
        LD      A,B         ; LENGTH RETURNED AS BC PAIR, ENSURE BOTH REGS ARE 0
        OR      C           ;
        JP      Z,_SMEROS   ; BLANK, DISPLAY ERROR AND EXIT
        CALL    TOINT       ; NOT BLANK = SPECIFIED ADDRESS. DOES IT CONVERT TO A NUMBER?
        JP      NC,_SMEROS  ; NO
        EX      DE,HL       ; YES - MOVE ADDRESS INTO HL


        ; PUT THE ADDRESS ON THE STACK AND LET 'RET' DO WHAT IT DOES BEST
        ;EX      (SP),HL
        PUSH     HL
        RET                 ; EXECUTION XFERS TO ADDRESS WE JUST PUT ON STACK


        ;------ END SMCMD_G --------------------------------