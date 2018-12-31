
;;;
        .org $2000

INBUF   := $200                  ;GETLN input buffer.

;;; ============================================================
;;; ROM routines

WAIT    := $FCA8                 ;Monitor wait routine.
BELL    := $FF3A                 ;Monitor bell routine

CROUT   := $FD8E
PRBYTE  := $FDDA
COUT    := $FDED

;;; ============================================================
;;; BASIC.SYSTEM global page

EXTRNCMD        := $BE06         ; External cmd JMP vector.
ERROUT          := $BE09         ; Error routine vector.
ERRCODE         := $BE0F         ; Error code
XTRNADDR        := $BE50         ; Ext cmd implementation addr.

XLEN    := $BE52                 ;Length of command string-1.
XCNUM   := $BE53                 ;CI cmd no. (ext cmd = 0).

PBITS   := $BE54                 ; Command parameter bits.
FBITS   := $BE56                 ; Found parameter bits.

VADDR   := $BE58                 ; Address parameter
VSLOT   := $BE61                 ; Slot parameter
VTYPE   := $BE6A                 ; Type parameter
VPATH1  := $BE6C                 ; Pathname buffer

GOSYSTEM := $BE70               ; Use instead of MLI

SSGINFO := $BEB4                ; Get/Set Info Parameter block (set size to set=7 or get=$A)
FIFNAME := $BEB5                ; Should be implcitly linked already
FIFILID := $BEB8
FIAUXID := $BEB9

;;; ============================================================

;;; TODO: Relocate into ProDOS-allocated buffer

;;;
;;; Remember to save the previous command address.
;;;
        lda     EXTRNCMD+1
        sta     nxtcmd
        lda     EXTRNCMD+2
        sta     nxtcmd+1
;;;
        lda     #<handler      ;Install the address of our
        sta     EXTRNCMD+1      ; command handler in the
        lda     #>handler      ; external command JMP
        sta     EXTRNCMD+2      ; vector.
        rts
;;;
handler:
        ldx     #0              ;Check for our command.
nxtchr: lda     INBUF,x         ;Get first character.

        and     #$7F            ;Convert to ASCII

        cmp     #'a'            ;Convert to upper-case
        bcc     :+
        cmp     #'z'+1
        bcs     :+
        and     #$DF

:       cmp     cmd,x           ;Does it match?
        bne     notours         ;NO, SO CONTINUE WITH NEXT CMD.
        inx                     ;Next character
        cpx     #cmdlen         ;All characters yet?
        bne     nxtchr          ;No, read next one.
;;;
        lda     #cmdlen-1       ;Our cmd! Put cmd length-1
        sta     XLEN            ; in CI global XLEN.
        lda     #<execute       ;Point XTRNADDR to our
        sta     XTRNADDR        ; command execution
        lda     #>execute       ; routine
        sta     XTRNADDR+1
        lda     #0              ;Mark the cmd number as
        sta     XCNUM           ; zero (external).
;;;
        ;; Must set at least one bit in PBITS low byte.

        lda     #%10000000      ; bit 7 = Address
        sta     PBITS+1
;;;
        lda     #%00000101      ; bit 8 = filename req'd, bit 10 = Type
        sta     PBITS
        clc                     ;Everything is OK.
        rts                     ;Return to BASIC.SYSTEM

;;; ============================================================

notours:
        sec                     ;SET CARRY AND LET
        jmp     (nxtcmd)        ; NEXT EXT CMD GO FOR IT.

;;; ============================================================

execute:
        ;; Filename?
        lda     FBITS
        and     #%00000001      ; Filename?
        bne     :+
        lda     #$10            ; SYNTAX ERROR
        sec
        rts
:

        ;; Type?
        lda     FBITS
        and     #%00000100      ; Type?
        bne     :+
        lda     #$B             ; INVALID PARAMETER
        sec
        rts
:

        ;; Show Filename
        lda     #'P'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT

        ptr := $06
        lda     VPATH1
        sta     ptr
        lda     VPATH1+1
        sta     ptr+1

        ldy     #0
        lda     (ptr),y
        tax
        iny

:       lda     (ptr),y
        ora     #$80
        jsr     COUT
        iny
        dex
        bne     :-
        jsr     CROUT

        ;; Show Type
        lda     #'T'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT
        lda     #'$'|$80
        jsr     COUT
        lda     VTYPE
        jsr     PRBYTE
        jsr     CROUT

        ;; Addr?
        lda     FBITS+1
        and     #%10000000      ; Addr?
        beq     :+

        lda     #'A'|$80
        jsr     COUT
        lda     #'='|$80
        jsr     COUT
        lda     #'$'|$80
        jsr     COUT
        lda     VADDR+1         ; hi
        jsr     PRBYTE
        lda     VADDR           ; lo
        jsr     PRBYTE
        jsr     CROUT
:

        ;; Get/Set File Info

        ;; GET_FILE_INFO
        lda     #$A
        sta     SSGINFO
        lda     #$C4            ; GET_FILE_INFO
        jsr     GOSYSTEM
        bcs     rts1

        ;; SET_FILE_INFO
        lda     #$7
        sta     SSGINFO
        lda     VTYPE
        sta     FIFILID
        ;; TODO: optional Aux Type
        lda     #$C3            ; SET_FILE_INFO
        jsr     GOSYSTEM
        bcs     rts1

        clc                     ;All done successfully.
rts1:   rts                     ;Back to BASIC.SYSTEM.

;;; ============================================================
;;; Data

cmd:    .byte   "CHTYPE"        ;Our command
        cmdlen  =  *-cmd        ;Our command length
nxtcmd: .word   0               ; STORE THE NEXT COMMAND'S
                                ; ADDRESS HERE.
