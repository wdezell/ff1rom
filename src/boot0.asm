;; -------------------------------------------------------------
;; BOOT MODE 0 - SYSTEM MONITOR LOADER
;;
;; TODO- VERIFY FF REV 1 COLD RESET CIRCUIT FUNCTION
;;       WE WILL NEED ROM BACK IN MEMORY FOR REBOOT
;; -------------------------------------------------------------

        ;; INC MONITOR SOURCE FOR ASSEMBLY
IMPORT "smmain.asm"

BOOT0: .EQU    $

        CALL    PRINL
        .TEXT   "LOADING SYSTEM MONITOR...",CR,LF,NULL

        ;; INSTALL MONITOR FROM ROM-ASSEMBLY STORAGE TO EXECUTION LOCATION
        LD      HL,SYSMNS
        LD      DE,HISTOP-SMSIZ
        LD      BC,SMSIZ
        LDIR

        ;; START MONITOR
        JP      SYSMON      ; ONE-WAY TRIP

        ; TODO - THIS LOADER WILL EVENTUALLY HAVE TO TUCK AWAY THE OTHER LOADERS TO HIMEM AS SYSMON INIT CLEARS LOWMEM
