;; -------------------------------------------------------------
;; BOOT MODE 3 - UNASSIGNED
;; -------------------------------------------------------------

BOOT3:  .EQU    $

        CALL    CLSVT
        RST     10H

        CALL    PRINL
        .TEXT   "BOOT 3 UNASSIGNED",NULL

        HALT
        JR      $

        ;; -------------------------------------------------------------
