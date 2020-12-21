;; -------------------------------------------------------------
;; BOOT MODE 1 - SYSTEM MONITOR INSTALLER
;;
;; TODO- VERIFY FF REV 1 COLD RESET CIRCUIT FUNCTION
;;       WE WILL NEED ROM BACK IN MEMORY FOR REBOOT
;; -------------------------------------------------------------

SYSMNI:  .EQU    $          ; "SYSMON VIA BOOT MODE 1 INSTALLER"

        ;; INSTALL MONITOR FROM ROM-ASSEMBLY STORAGE TO EXECUTION LOCATION
        LD      HL,SYSMNS
        LD      DE,HISTOP-SMSIZ
        LD      BC,SMSIZ
        LDIR

IF 1
        ;; CLEAR LOW MEMORY FROM PAGE 1 UP TO LAST BYTE BELOW MONITOR
        LD      A,0
        LD      (RESET),A
        LD      HL,RESET
        LD      DE,RESET
        LD      BC,HISTOP-SMSIZ-RESET-1
        LDIR
ENDIF

        ;; START MONITOR
        JP      SYSMON      ; ONE-WAY TRIP

        ;; INC MONITOR SOURCE FOR ASSEMBLY
IMPORT "sysmon.asm"
