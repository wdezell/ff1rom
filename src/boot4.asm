;; -------------------------------------------------------------
;; BOOT MODE 4 - BASIC
;; -------------------------------------------------------------

BOOT4:  .EQU    $

        CALL    VTCLS

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 4\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCHR

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
        
