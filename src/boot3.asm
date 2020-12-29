;; -------------------------------------------------------------
;; BOOT MODE 3 - FORTH
;; -------------------------------------------------------------

BOOT3:  .EQU    $

        CALL    CLSVT

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 3",CR,LF,CR,LF,"PRESS ANY KEY",NULL

        CALL    CONCIN

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        JP      RESET         ; REBOOT

        ;; -------------------------------------------------------------
        
