;; -------------------------------------------------------------
;; BOOT MODE 2 - CP/M V2.2
;; -------------------------------------------------------------

BOOT2:  .EQU    $

        CALL    CLSVT

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 2\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCIN

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
        
