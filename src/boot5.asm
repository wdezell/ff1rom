;; -------------------------------------------------------------
;; BOOT MODE 5
;; -------------------------------------------------------------

BOOT5:  .EQU    $

        CALL    CLSVT

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 5",CR,LF,CR,LF,"PRESS ANY KEY",NULL

        CALL    CONCIN

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        JP      RESET         ; REBOOT

        ;; -------------------------------------------------------------
        
