;; -------------------------------------------------------------
;; BOOT MODE 7 - UNASSIGNED
;; -------------------------------------------------------------

BOOT7:  .EQU    $

        CALL    CLSVT
        RST     10H

        CALL    PRINL
        .TEXT   "BOOT 7 UNASSIGNED",NULL

        HALT
        JR      $

        ;; -------------------------------------------------------------
