;; -------------------------------------------------------------
;; BOOT MODE 1 - MONITOR
;; -------------------------------------------------------------

BOOT1:  .EQU    $

        CALL    VTCLS

        ;; TODO - IMPLEMENT
        ;;
        ;; Monitor losely based on Big Board PFM-80 command set with extensions
        ;;
        ;; Command                  Format
        ;; --------------------     ----------------------------------------------
        ;; E(xamine) memory         E   STARTADDR ENDADDR
        ;; M(odify) memory          M   ADDRESS
        ;; G(o) execute memory      G   ADDRESS
        ;; C(opy) memory            C   STARTADDR ENDADDR DESTADDR
        ;; F(ill) memory            F   STARTADDR ENDADDR CONST
        ;; T(est) memory            T   STARTADDR ENDADDR
        ;; H(ex Load) memory        H   SERPORT BAUD PARITY WORD STOP AUTOEXECUTE
        ;;
        ;; R(ead) mass storage      R   UNIT TRACK SECTOR
        ;; W(rite) mass storage     W   UNIT TRACK SECTOR STARTADDR ENDADDR
        ;; B(oot) mass storage      B
        ;;
        ;; I(nput) port             I   PORTNUM
        ;; O(utput) port            O   PORTNUM CONST
        ;;
        ;; ? (Help)                 ?
        ;; X (Exit)                 X
        ;;


        ;; DEBUG / REMOVE
        RST     08H
        CALL    PRINL
        .TEXT   "BOOT 1\n\r\n\r\n\rPRESS ANY KEY\000"

        CALL    CONCIN

        ;; PLACEHOLDER -- ADAPT AS PER FINAL ROUTINE REQUIREMENTS
        RST     00H         ; REBOOT

        ;; -------------------------------------------------------------
        
