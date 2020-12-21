;; -------------------------------------------------------------
;; BOOT MODE 3 - FORTH
;; -------------------------------------------------------------

BOOT3:  .EQU    $

        CALL    CLSVT

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 3\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCIN

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
        
