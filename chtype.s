
;;;
        .org $2000

INBUF   := $200                  ;GETLN input buffer.

WAIT    := $FCA8                 ;Monitor wait routine.
BELL    := $FF3A                 ;Monitor bell routine


;;; BASIC.SYSTEM global page

EXTRNCMD        := $BE06         ;External cmd JMP vector.
XTRNADDR        := $BE50         ;Ext cmd implementation addr.
XLEN    := $BE52                 ;Length of command string-1.
XCNUM   := $BE53                 ;CI cmd no. (ext cmd = 0).
PBITS   := $BE54                 ;Command parameter bits.
VSLOT   := $BE61                 ;Verified slot parameter.

;;; TODO: Relocate into ProDOS-allocated buffer

;;;
;;; Remember to save the previous command address.
;;;
        lda     EXTRNCMD+1
        sta     nxtcmd
        lda     EXTRNCMD+2
        sta     nxtcmd+1
;;;
        lda     #>beepslot      ;Install the address of our
        sta     EXTRNCMD+1      ; command handler in the
        lda     #<beepslot      ; external command JMP
        sta     EXTRNCMD+2      ; vector.
        RTS
;;;
beepslot:
        ldx     #0              ;Check for our command.
nxtchr: lda     INBUF,X         ;Get first character.
        cmp     cmd,X           ;Does it match?
        bne     notours         ;NO, SO CONTINUE WITH NEXT CMD.
        inx                     ;Next character
        cpx     #cmdlen         ;All characters yet?
        bne     nxtchr          ;No, read next one.
;;;
        lda     #cmdlen-1       ;Our cmd! Put cmd length-1
        sta     XLEN            ; in CI global XLEN.
        lda     #>execute       ;Point XTRNADDR to our
        sta     XTRNADDR        ; command execution
        lda     #<execute       ; routine
        sta     XTRNADDR+1
        lda     #0              ;Mark the cmd number as
        sta     XCNUM           ; zero (external).
;;;
        lda     #%00010000      ;Set at least one bit
        sta     PBITS           ; in PBITS low byte!
;;;
        lda     #%00000100      ;And mark PBITS high byte
        sta     PBITS+1         ; that slot & drive are legal.
        clc                     ;Everything is OK.
        rts                     ;Return to BASIC.SYSTEM
;;;
execute:
        lda     VSLOT           ;Get slot parameter.
        tax                     ;Transfer to index reg.
nxtbeep:
        jsr     BELL            ;Else, beep once.
        lda     #$80            ;Set up the delay
        jsr     WAIT            ; and wait.
        dex                     ;decrement index and
        bne     nxtbeep         ; repeat until x = 0.
        clc                     ;All done successfully.
        rts                     ;Back to BASIC.SYSTEM.
;;;
;;; IT'S NOT OUR COMMAND SO MAKE SURE YOU LET BASIC
;;; CHECK WHETER OR NOT IT'S THE NEXT COMMAND.
;;;
notours:        sec             ;SET CARRY AND LET
        jmp     (nxtcmd)        ; NEXT EXT CMD GO FOR IT.
;;;
cmd:    .byte   "BEEPSLOT"      ;Our command
        cmdlen  =  *-cmd        ;Our command length
nxtcmd: .word   0               ; STORE THE NEXT COMMAND'S
                                ; ADDRESS HERE.
