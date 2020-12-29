;; -------------------------------------------------------------
;; BOOT MODE 0 - CONSOLE MENU
;;  DIAGNOSTICS, BOARD UTILS, MONITOR, LAUNCH OTHER MODES
;; -------------------------------------------------------------
BOOT0C: .EQU    $           ; ENTRY POINT W/ SCREEN CLEAR
        CALL    CLSVT

BOOT0:  .EQU    $           ; ENTRY POINT PRESERVING SCREEN

        RST     10H         ; DEBUG DISPLAY

        ;; PRESENT MENU
        CALL    PRINL
        .TEXT   CR,LF,"CONSOLE MENU",CR,LF,CR,LF
        .TEXT   " 1  SYSTEM MONITOR",CR,LF
        .TEXT   " 2  BOARD UTILS",CR,LF
        .TEXT   " 3  DIAGNOSTICS",CR,LF,CR,LF
        .TEXT   "SELECT>",NULL


        ;; GET, VALIDATE, AND DISPATCH USER SELECTION
_READL: LD      HL,_B0INB   ; SET HL TO ADDRESS OF INPUT BUFFER
        LD      B,4         ; SET SIZE OF BUFFER
        CALL    CONLIN      ; CALL CONSOLE LINE READ

        CP      0           ; A = CHARS READ. ZERO?
        JR      Z,_READL    ; READ AGAIN (USER PROBABLY JUST PRESSED ENTER)

        LD      A,(_B0INB)  ; GET INPUT CHAR INTO A FOR INSPECTION (SINGLE DIGIT MENU SO FIRST BUFFER CHAR)
        CALL    TODIGIT     ; GET NUMERICAL VALUE OF INPUT INTO A
        JP      NC,BOOT0C   ; NOT A DIGIT

        CP      0           ; VALID RANGE HERE IS 1-4
        JP      Z,BOOT0C    ; NO

        CP      4           ; <= 4?
        JR      C,_B0VAL
        JR      Z,_B0VAL
        JP      BOOT0C      ; NO

_B0VAL: SUB     1           ; IN RANGE 1-4, NOW CONVERT TO ZERO-BASED

        ;; DISPATCH SELECTION
        LD      HL,_B0MTB   ; POINT TO ACTION DISPATCH TABLE
        LD      B,3         ; SET ENTRIES COUNT
        CALL    TABDSP      ; JUMP TO ENTRY INDEXED BY A

        ;; SHOULD NEVER REACH HERE AS INPUT IS RANGE VALIDATED
        RST     10H         ; DEBUG DISPLAY
        HALT
        JR      $

_B0MTB: .EQU    $           ;; MENU JUMP TABLE
        .DW     SYSMLD      ; SYSTEM MONITOR VIA BOOT MODE 1 INSTALLER
        .DW     BOOT2       ; TEST
        .DW     BOOT0C      ; NOT IMPL YET

_B0INB: .DS     4           ; USER INPUT BUFFER

        ;; -------------------------------------------------------------
