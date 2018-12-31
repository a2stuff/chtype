
;;;
        .org $2000

INBUF   := $200                 ;GETLN input buffer.
WAIT    := $FCA8                ;Monitor wait routine.
BELL    := $FF3A                ;Monitor bell routine
EXTRNCMD        := $BE06        ;External cmd JMP vector.
XTRNADDR        := $BE50        ;Ext cmd implementation addr.
XLEN    := $BE52                ;Length of command string-1.
XCNUM   := $BE53                ;CI cmd no. (ext cmd = 0).
PBITS   := $BE54                ;Command parameter bits.
VSLOT   := $BE61                ;Verified slot parameter.

;;;
;;; REMEMBER TO SAVE THE PREVIOUS COMMAND ADDRESS.
;;;
        LDA EXTRNCMD+1
        STA NXTCMD
        LDA EXTRNCMD+2
        STA NXTCMD+1
;;;
        LDA #>BEEPSLOT          ;Install the address of our
        STA EXTRNCMD+1          ; command handler in the
        LDA #<BEEPSLOT          ; external command JMP
        STA EXTRNCMD+2          ; vector.
        RTS
;;;
BEEPSLOT:       LDX #0          ;Check for our command.
NXTCHR: LDA INBUF,X             ;Get first character.
        CMP CMD,X               ;Does it match?
        BNE NOTOURS             ;NO, SO CONTINUE WITH NEXT CMD.
        INX                     ;Next character
        CPX #CMDLEN             ;All characters yet?
        BNE NXTCHR              ;No, read next one.
;;;
        LDA #CMDLEN-1           ;Our cmd! Put cmd length-1
        STA XLEN                ; in CI global XLEN.
        LDA #>EXECUTE           ;Point XTRNADDR to our
        STA XTRNADDR            ; command execution
        LDA #<EXECUTE           ; routine
        STA XTRNADDR+1
        LDA #0                  ;Mark the cmd number as
        STA XCNUM               ; zero (external).
;;;
        LDA #%00010000          ;Set at least one bit
        STA PBITS               ; in PBITS low byte!
;;;
        LDA #%00000100          ;And mark PBITS high byte
        STA PBITS+1             ; that slot & drive are legal.
        CLC                     ;Everything is OK.
        RTS                     ;Return to BASIC.SYSTEM
;;;
EXECUTE:        LDA VSLOT       ;Get slot parameter.
        TAX                     ;Transfer to index reg.
NXTBEEP:        JSR BELL        ;Else, beep once.
        LDA #$80                ;Set up the delay
        JSR WAIT                ; and wait.
        DEX                     ;decrement index and
        BNE NXTBEEP             ; repeat until x = 0.
        CLC                     ;All done successfully.
        RTS                     ;Back to BASIC.SYSTEM.
;;;
;;; IT'S NOT OUR COMMAND SO MAKE SURE YOU LET BASIC
;;; CHECK WHETER OR NOT IT'S THE NEXT COMMAND.
;;;
NOTOURS:        SEC             ;SET CARRY AND LET
        JMP (NXTCMD)            ; NEXT EXT CMD GO FOR IT.
;;;
CMD:    .byte   "BEEPSLOT"      ;Our command
        CMDLEN =  *-CMD         ;Our command length
NXTCMD: .word   0               ; STORE THE NEXT COMMAND'S
                                ; ADDRESS HERE.
