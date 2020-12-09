;; -------------------------------------------------------------
;; BOOT MODE 6
;; -------------------------------------------------------------

BOOT6:  .EQU    $

        CALL    VTCLS

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 6\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCHR

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
        
