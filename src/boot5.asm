;; -------------------------------------------------------------
;; BOOT MODE 5 - UNASSIGNED
;; -------------------------------------------------------------

BOOT5:  .EQU    $

        CALL    CLSVT
        RST     10H

        CALL    PRINL
        .TEXT   "BOOT 5 UNASSIGNED",NULL

        HALT
        JR      $

        ;; -------------------------------------------------------------
