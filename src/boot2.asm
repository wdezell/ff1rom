;; -------------------------------------------------------------
;; BOOT MODE 2 - UNASSIGNED
;; -------------------------------------------------------------

BOOT2:  .EQU    $

        CALL    CLSVT
        RST     10H

        CALL    PRINL
        .TEXT   "BOOT 2 UNASSIGNED",NULL

        HALT
        JR      $

        ;; -------------------------------------------------------------
