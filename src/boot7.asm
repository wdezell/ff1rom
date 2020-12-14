;; -------------------------------------------------------------
;; BOOT MODE 7
;; -------------------------------------------------------------

BOOT7:  .EQU    $

        CALL    VTCLS

        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 7\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCIN

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
        
