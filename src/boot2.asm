;; -------------------------------------------------------------
;; BOOT MODE 2 - CP/M V2.2
;; -------------------------------------------------------------

BOOT2:  .EQU    $

        CALL    CLSVT

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 2",CR,LF,CR,LF,"PRESS ANY KEY",NULL

        CALL    CONCIN

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        JP      RESET         ; REBOOT

        ;; -------------------------------------------------------------
        
