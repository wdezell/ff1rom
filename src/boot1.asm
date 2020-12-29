;; -------------------------------------------------------------
;; BOOT MODE 1 - SYSTEM MONITOR LOADER
;;
;; TODO- VERIFY FF REV 1 COLD RESET CIRCUIT FUNCTION
;;       WE WILL NEED ROM BACK IN MEMORY FOR REBOOT
;; -------------------------------------------------------------

        ;; INC MONITOR SOURCE FOR ASSEMBLY
IMPORT "sysmon.asm"

SYSMLD: .EQU    $

        CALL    CLSVT
        CALL    PRINL
        .TEXT   "SYSTEM MONITOR LOADER",CR,LF,NULL

        ;; INSTALL MONITOR FROM ROM-ASSEMBLY STORAGE TO EXECUTION LOCATION
        LD      HL,SYSMNS
        LD      DE,HISTOP-SMSIZ
        LD      BC,SMSIZ
        LDIR

        RST     10H         ; DEBUG CHECKPOINT -- REMOVE

        ;; START MONITOR
        JP      SYSMON      ; ONE-WAY TRIP
