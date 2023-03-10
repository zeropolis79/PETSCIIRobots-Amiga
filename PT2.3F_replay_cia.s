	xdef	_SetCIAInt__Fv
	xdef	_ResetCIAInt__Fv
	xdef	_mt_init__FPUc
	xdef	_mt_music__Fv
	xdef	_mt_end__Fv
	xdef	_mt_chan1temp
	xdef	_mt_chan2temp
	xdef	_mt_chan3temp
	xdef	_mt_chan4temp
	xdef	_mt_SampleStarts
	xdef	_mt_data
	xdef	_mt_speed
	xdef	_mt_SongPos
	xdef	_mt_Enable
	xdef	_mt_PatternPos
	xdef	_mt_chan1input
	xdef	_mt_chan2input
	xdef	_mt_chan3input
	xdef	_mt_chan4input

	section	code

;*************************************************
;*  ----- ProTracker V2.3F Replay Routine -----  *
;*************************************************

; CIA Version:
; Call SetCIAInt to install the interrupt server. Then call mt_init
; to initialize the song. Playback starts when the mt_enable flag
; is set to a non-zero value. To end the song and turn off all voices,
; call mt_end. At last, call ResetCIAInt to remove the interrupt.
;
; This replay routine is modified to work exactly like the tracker replayer,
; thus it is super accurate but not not optimized in any way. The only
; difference is that it fully supports loop points above 65535.
;
; You can use this routine to play a module. Just remove the semicolons.
; Also change the module path in mt_data at the very bottom of this file.
; Exit by pressing both mouse buttons.
;
;main	BSR.S	SetCIAInt
;	BSR	mt_init
;	ST	mt_Enable
;	MOVE.L	4.W,A6
;	LEA	DOSname(PC),A1
;	MOVEQ	#0,D0
;	JSR	LVOOpenLibrary(A6)
;	TST.L	D0
;	BEQ.S	theend
;	MOVE.L	D0,A6
;wloop	MOVEQ	#10,D1
;	JSR	LVODelay(A6)
;	BTST	#6,$BFE001
;	BNE.S	wloop
;	BTST	#2,$DFF016
;	BNE.S	wloop
;	MOVE.L	A6,A1
;	MOVE.L	4.W,A6
;	JSR	LVOCloseLibrary(A6)
;theend	BSR	mt_end
;	BSR	ResetCIAInt
;	RTS

;DOSname	dc.b "dos.library",0

;---- CIA Interrupt ----

AddICRVector	equ   -6
RemICRVector	equ  -12
LVOOpenResource	equ -498
LVOOpenLibrary	equ -552
LVOCloseLibrary	equ -414
LVODelay	equ -198

ciatalo	equ $400
ciatahi	equ $500
ciatblo	equ $600
ciatbhi	equ $700
ciacra	equ $E00
ciacrb	equ $F00

_SetCIAInt__Fv
	movem.l	d0-d7/a0-a5,-(sp)

	MOVEQ	#2,D6
	LEA	$BFD000,A5
	MOVE.B	#'b',CIAAname+3
SetCIALoop
	MOVEQ	#0,D0
	LEA	CIAAname(PC),A1
	MOVE.L	4.W,A6
	JSR	LVOOpenResource(A6)
	MOVE.L	D0,CIAAbase
	BEQ	mt_ReturnToC

	LEA	GfxName(PC),A1
	MOVEQ	#0,D0
	JSR	LVOOpenLibrary(A6)
	TST.L	D0
	BEQ	_ResetCIAInt__Fv
	MOVE.L	D0,A1
	MOVE.W	206(A1),D0		; DisplayFlags
	BTST	#2,D0			; PAL?
	BEQ.S	WasNTSC
	MOVE.L	#1773447,D7 		; PAL
	BRA.S	sciask
WasNTSC	MOVE.L	#1789773,D7 		; NTSC
sciask	MOVE.L	D7,TimerValue
	DIVU	#125,D7 		; Default to normal 50 Hz timer
	JSR	LVOCloseLibrary(A6)

	MOVE.L	CIAAbase(PC),A6
	CMP.W	#2,D6
	BEQ.S	TryTimerA
TryTimerB
	LEA	MusicIntServer(PC),A1
	MOVEQ	#1,D0			; Bit 1: Timer B
	JSR	AddICRVector(A6)
	MOVE.L	#1,TimerFlag
	TST.L	D0
	BNE.S	CIAError
	MOVE.L	A5,CIAAaddr
	MOVE.B	D7,ciatblo(A5)
	LSR.W	#8,D7
	MOVE.B	D7,ciatbhi(A5)
	BSET	#0,ciacrb(A5)

	movem.l	(sp)+,d0-d7/a0-a5
	RTS

TryTimerA
	LEA	MusicIntServer(PC),A1
	MOVEQ	#0,D0			; Bit 0: Timer A
	JSR	AddICRVector(A6)
	CLR.L	TimerFlag
	TST.L	D0
	BNE.S	CIAError
	MOVE.L	A5,CIAAaddr
	MOVE.B	D7,ciatalo(A5)
	LSR.W	#8,D7
	MOVE.B	D7,ciatahi(A5)
	BSET	#0,ciacra(A5)

	movem.l	(sp)+,d0-d7/a0-a5
	RTS

CIAError
	MOVE.B	#'a',CIAAname+3
	LEA	$BFE001,A5
	SUBQ.W	#1,D6
	BNE	SetCIALoop
	CLR.L	CIAAbase

	movem.l	(sp)+,d0-d7/a0-a5
	RTS

_ResetCIAInt__Fv
	tst.l	CIAAaddr
	bne.s	ResCIAInt
	rts

ResCIAInt
	movem.l	d0-d7/a0-a5,-(sp)

	MOVE.L	CIAAbase(PC),D0
	BEQ	mt_ReturnToC
	CLR.L	CIAAbase
	MOVE.L	D0,A6
	MOVE.L	CIAAaddr(PC),A5
	TST.L	TimerFlag
	BEQ.S	ResTimerA

	BCLR	#0,ciacrb(A5)
	MOVEQ	#1,D0
	BRA.S	RemInt

ResTimerA
	BCLR	#0,ciacra(A5)
	MOVEQ	#0,D0
RemInt	LEA	MusicIntServer(PC),A1
	MOVEQ	#0,d0
	JSR	RemICRVector(A6)

mt_ReturnToC
	movem.l	(sp)+,d0-d7/a0-a5
	RTS


;---- Tempo ----

SetTempo
	MOVE.L	CIAAbase(PC),D2
	BEQ	mt_Return
	CMP.W	#32,D0
	BHS.S	setemsk
	MOVEQ	#32,D0
setemsk	MOVE.W	D0,RealTempo
	MOVE.L	TimerValue(PC),D2
	DIVU	D0,D2
	MOVE.L	CIAAaddr(PC),A4
	MOVE.L	TimerFlag(PC),D0
	BEQ.S	SetTemA
	MOVE.B	D2,ciatblo(A4)
	LSR.W	#8,D2
	MOVE.B	D2,ciatbhi(A4)
	RTS

SetTemA	MOVE.B	D2,ciatalo(A4)
	LSR.W	#8,D2
	MOVE.B	D2,ciatahi(A4)
	RTS

RealTempo	dc.w 125
CIAAaddr	dc.l 0
CIAAname	dc.b "ciaa.resource",0
CIAAbase	dc.l 0
TimerFlag	dc.l 0
TimerValue	dc.l 0
GfxName		dc.b "graphics.library",0,0

MusicIntServer
	dc.l 0,0
	dc.b 2,5 ; type, priority
	dc.l musintname
	dc.l 0,mt_music

musintname	dc.b "Attack of the PETSCII Robots CIA",0,0

;---- Playroutine ----

n_note		EQU 0  ; W
n_cmd		EQU 2  ; W
n_cmdlo		EQU 3  ; B
n_start		EQU 4  ; L
n_length	EQU 8  ; W
n_loopstart	EQU 10 ; L
n_replen	EQU 14 ; W
n_period	EQU 16 ; W
n_finetune	EQU 18 ; B
n_volume	EQU 19 ; B
n_dmabit	EQU 20 ; W
n_toneportdirec	EQU 22 ; B
n_toneportspeed	EQU 23 ; B
n_wantedperiod	EQU 24 ; W
n_vibratocmd	EQU 26 ; B
n_vibratopos	EQU 27 ; B
n_tremolocmd	EQU 28 ; B
n_tremolopos	EQU 29 ; B
n_wavecontrol	EQU 30 ; B
n_glissfunk	EQU 31 ; B
n_sampleoffset	EQU 32 ; B
n_pattpos	EQU 33 ; B
n_loopcount	EQU 34 ; B
n_funkoffset	EQU 35 ; B
n_wavestart	EQU 36 ; L

_mt_init__FPUc
	movem.l	d2-d3/a2/a4,-(sp)

	MOVE.L	A0,mt_SongDataPtr
	
	; count number of patterns (find highest referred pattern)
	MOVE.L	A0,A1
	LEA	952(A1),A1	; order list address
	MOVEQ	#128-1,D0	; 128 order list entries
	MOVEQ	#0,D1
mtloop	MOVE.L	D1,D2
	SUBQ.W	#1,D0
mtloop2	MOVE.B	(A1)+,D1
	CMP.B	D2,D1
	BGT.S	mtloop
	DBRA	D0,mtloop2
	ADDQ.B	#1,D2
	
	; generate mt_SampleStarts list and fix samples
	LEA	mt_SampleStarts,A1
	ASL.L	#8,D2
	ASL.L	#2,D2
	ADD.L	#1084,D2
	ADD.L	A0,D2
	MOVE.L	D2,A2		; A2 is now the address of first sample's data
	MOVEQ	#15-1,D0	; handle 15 samples
mtloop3
	MOVE.W  28(A0),D3	; get replen
	TST.W   D3		; replen is zero?
	BNE.S   mtskip		; no
	MOVE.W  #1,28(A0)	; yes, set to 1 (fixes lock-up)
mtskip
	CMP.W   #1,D3		; loop enabled?
	BHI.S   mtskip2		; yes
	CLR.W   (A2)		; no, clear first two bytes of sample
mtskip2
	MOVE.L	A2,(A1)+	; move sample address into mt_SampleStarts slot
	MOVEQ	#0,D1
	MOVE.W	42(A0),D1 	; get sample length
	ADD.L	D1,D1		; turn into real sample length
	ADD.L	D1,A2		; add to address
	ADD.L	#30,A0		; skip to next sample list entry
	DBRA	D0,mtloop3

	; initialize stuff
	;OR.B	#2,$BFE001
	move.l	#$00010000,mt_chan1temp+20
	move.l	#$00020000,mt_chan2temp+20
	move.l	#$00040000,mt_chan3temp+20
	move.l	#$00080000,mt_chan4temp+20
	MOVE.B	#6,mt_speed
	CLR.B	mt_counter
	CLR.B	mt_SongPos
	CLR.W	mt_PatternPos
	move.w	#125,d0
	bsr	SetTempo
	movem.l	(sp)+,d2-d3/a2/a4

_mt_end__Fv
	SF	mt_Enable
	LEA	$DFF000,A0
	CLR.W	$A8(A0)
	CLR.W	$B8(A0)
	CLR.W	$C8(A0)
	CLR.W	$D8(A0)
	MOVE.W	#$000F,$DFF096
	RTS

_mt_music__Fv
mt_music
	MOVEM.L	D0-D7/A0-A6,-(SP)
	TST.B	mt_Enable
	BEQ	mt_exit
	ADDQ.B	#1,mt_counter
	MOVE.B	mt_counter,D0
	CMP.B	mt_speed,D0
	BLO.S	mt_NoNewNote
	CLR.B	mt_counter
	TST.B	mt_PattDelTime2
	BEQ.S	mt_GetNewNote
	BSR.S	mt_NoNewAllChannels
	BRA	mt_dskip

mt_NoNewNote
	BSR.S	mt_NoNewAllChannels
	BRA	mt_NoNewPosYet

mt_NoNewAllChannels
	LEA	$DFF0A0,A5
	LEA	mt_chan1temp,A6
	BSR	mt_CheckEffects
	LEA	$DFF0B0,A5
	LEA	mt_chan2temp,A6
	BSR	mt_CheckEffects
	LEA	$DFF0C0,A5
	LEA	mt_chan3temp,A6
	BSR	mt_CheckEffects
	LEA	$DFF0D0,A5
	LEA	mt_chan4temp,A6
	BRA	mt_CheckEffects

mt_GetNewNote
	MOVE.L	mt_SongDataPtr,A0
	LEA	12(A0),A3
	LEA	952(A0),A2	;pattpo
	LEA	1084(A0),A0	;patterndata
	MOVEQ	#0,D0
	MOVEQ	#0,D1
	MOVE.B	mt_SongPos,D0
	MOVE.B	(A2,D0.W),D1
	ASL.L	#8,D1
	ASL.L	#2,D1
	ADD.W	mt_PatternPos,D1
	CLR.W	mt_DMACONtemp

	LEA	$DFF0A0,A5
	movem.l	a0/d1,-(sp)
	tst.l	mt_chan1input
	beq.s	mt_PlayChannel1
	lea	mt_chan1input,a0
	moveq	#0,d1
mt_PlayChannel1
	LEA	mt_chan1temp,A6
	BSR	mt_PlayVoice
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	clr.l	mt_chan1input

	LEA	$DFF0B0,A5
	move.l	(sp),a0
	move.l	4(sp),d1
	addq	#4,d1
	tst.l	mt_chan2input
	beq.s	mt_PlayChannel2
	lea	mt_chan2input,a0
	moveq	#0,d1
mt_PlayChannel2
	LEA	mt_chan2temp,A6
	BSR	mt_PlayVoice
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	clr.l	mt_chan2input

	LEA	$DFF0C0,A5
	move.l	(sp),a0
	move.l	4(sp),d1
	addq	#8,d1
	tst.l	mt_chan3input
	beq.s	mt_PlayChannel3
	lea	mt_chan3input,a0
	moveq	#0,d1
mt_PlayChannel3
	LEA	mt_chan3temp,A6
	BSR	mt_PlayVoice
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	clr.l	mt_chan3input

	LEA	$DFF0D0,A5
	movem.l	(sp)+,a0/d1
	add.l	#12,d1
	tst.l	mt_chan4input
	beq.s	mt_PlayChannel4
	lea	mt_chan4input,a0
	moveq	#0,d1
mt_PlayChannel4
	LEA	mt_chan4temp,A6
	BSR	mt_PlayVoice
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	MOVE.W	D0,8(A5)
	clr.l	mt_chan4input
	BRA	mt_SetDMA

mt_PlayVoice
	TST.L	(A6)
	BNE.S	mt_plvskip
	BSR	mt_PerNop
mt_plvskip
	MOVE.L	(A0,D1.L),(A6)	; Read note from pattern
;	ADDQ.L	#4,D1
	MOVEQ	#0,D2
	MOVE.B	n_cmd(A6),D2	; Get lower 4 bits of instrument
	AND.B	#$F0,D2
	LSR.B	#4,D2
	MOVE.B	(A6),D0		; Get higher 4 bits of instrument
	AND.B	#$F0,D0
	OR.B	D0,D2
	TST.B	D2
	BEQ	mt_SetRegs	; Instrument was zero
	MOVEQ	#0,D3
	LEA	mt_SampleStarts,A1
	MOVE	D2,D4
	SUBQ.L	#1,D2
	ASL.L	#2,D2
	MULU	#30,D4
	MOVE.L	(A1,D2.L),n_start(A6)
	MOVE.W	(A3,D4.L),n_length(A6)
	MOVE.B	2(A3,D4.L),n_finetune(A6)
	AND.B	#$0F,n_finetune(A6)	; --PT2.3D bug fix: mask finetune...
	MOVE.B	3(A3,D4.L),n_volume(A6)
	MOVE.W	4(A3,D4.L),D3		; Get repeat
	TST.W	D3
	BEQ.S	mt_NoLoop
	MOVE.L	n_start(A6),D2		; Get start
	ADD.L	D3,D3			; PT2.3D bug fix: 128kB sample support
	ADD.L	D3,D2			; Add repeat
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	4(A3,D4.L),D0		; Get repeat
	ADD.W	6(A3,D4.L),D0		; Add replen
	MOVE.W	D0,n_length(A6)
	MOVE.W	6(A3,D4.L),n_replen(A6)	; Save replen
	BRA.S	mt_SetRegs

mt_NoLoop
	MOVE.L	n_start(A6),D2
	ADD.L	D3,D2
	MOVE.L	D2,n_loopstart(A6)
	MOVE.L	D2,n_wavestart(A6)
	MOVE.W	6(A3,D4.L),n_replen(A6)	; Save replen
mt_SetRegs
	MOVE.W	(A6),D0
	AND.W	#$0FFF,D0
	BEQ	mt_CheckMoreEfx		; If no note
	MOVE.W	2(A6),D0
	AND.W	#$0FF0,D0
	CMP.W	#$0E50,D0 		; finetune
	BEQ.S	mt_DoSetFineTune
	MOVE.B	2(A6),D0
	AND.B	#$0F,D0
	CMP.B	#3,D0			; TonePortamento
	BEQ.S	mt_ChkTonePorta
	CMP.B	#5,D0			; TonePortamento + VolSlide
	BEQ.S	mt_ChkTonePorta
	CMP.B	#9,D0			; Sample Offset
	BNE.S	mt_SetPeriod
	BSR	mt_CheckMoreEfx
	BRA.S	mt_SetPeriod

mt_DoSetFineTune
	BSR	mt_SetFineTune
	BRA.S	mt_SetPeriod

mt_ChkTonePorta
	BSR	mt_SetTonePorta
	BRA	mt_CheckMoreEfx

mt_SetPeriod
	MOVEM.L	D0/D1/A0/A1,-(SP)
	MOVE.W	(A6),D1
	AND.W	#$0FFF,D1
	LEA	mt_PeriodTable(PC),A1
	MOVEQ	#0,D0
	MOVEQ	#$24,D7
mt_ftuloop
	CMP.W	(A1,D0.W),D1
	BHS.S	mt_ftufound
	ADDQ.L	#2,D0
	DBRA	D7,mt_ftuloop
mt_ftufound
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	MULU	#37*2,D1
	ADD.L	D1,A1
	MOVE.W	(A1,D0.W),n_period(A6)
	MOVEM.L	(SP)+,D0/D1/A0/A1

	MOVE.W	2(A6),D0
	AND.W	#$0FF0,D0
	CMP.W	#$0ED0,D0 		; Notedelay
	BEQ	mt_CheckMoreEfx

	MOVE.W	n_dmabit(A6),$DFF096
	BTST	#2,n_wavecontrol(A6)
	BNE.S	mt_vibnoc
	CLR.B	n_vibratopos(A6)
mt_vibnoc
	BTST	#6,n_wavecontrol(A6)
	BNE.S	mt_trenoc
	CLR.B	n_tremolopos(A6)
mt_trenoc
	MOVE.W	n_length(A6),4(A5)	; Set length
	MOVE.L	n_start(A6),(A5)	; Set start
	BNE.S   mt_sdmaskp
	CLR.L	n_loopstart(A6)
	MOVEQ	#1,D0
	MOVE.W	D0,4(A5)
	MOVE.W	D0,n_replen(A6)
mt_sdmaskp
	MOVE.W	n_period(A6),D0
	MOVE.W	D0,6(A5)		; Set period
	MOVE.W	n_dmabit(A6),D0
	OR.W	D0,mt_DMACONtemp
	BRA	mt_CheckMoreEfx
 
mt_SetDMA
	MOVE.L	A0,-(SP)
	MOVE.L	D1,-(SP)
	LEA	$DFF006,A0
	MOVEQ	#7-1,D1
lineloop4
	MOVE.B	(A0),D0
waiteol4
	CMP.B	(A0),D0
	BEQ.B	waiteol4
	DBRA	D1,lineloop4

	MOVE.W	mt_DMACONtemp,D0
	OR.W	#$8000,D0		; Set bits
	MOVE.W	D0,$DFF096
	
	MOVEQ	#7-1,D1
lineloop5
	MOVE.B	(A0),D0
waiteol5
	CMP.B	(A0),D0
	BEQ.B	waiteol5
	DBRA	D1,lineloop5
	MOVE.L	(SP)+,D1
	MOVE.L	(SP)+,A0
	
	LEA	$DFF000,A5
	LEA	mt_chan4temp,A6
	MOVE.L	n_loopstart(A6),$D0(A5)
	MOVE.W	n_replen(A6),$D4(A5)
	LEA	mt_chan3temp,A6
	MOVE.L	n_loopstart(A6),$C0(A5)
	MOVE.W	n_replen(A6),$C4(A5)
	LEA	mt_chan2temp,A6
	MOVE.L	n_loopstart(A6),$B0(A5)
	MOVE.W	n_replen(A6),$B4(A5)
	LEA	mt_chan1temp,A6
	MOVE.L	n_loopstart(A6),$A0(A5)
	MOVE.W	n_replen(A6),$A4(A5)

mt_dskip
	ADD.W	#16,mt_PatternPos
	MOVE.B	mt_PattDelTime,D0
	BEQ.S	mt_dskpc
	MOVE.B	D0,mt_PattDelTime2
	CLR.B	mt_PattDelTime
mt_dskpc	TST.B	mt_PattDelTime2
	BEQ.S	mt_dskpa
	SUBQ.B	#1,mt_PattDelTime2
	BEQ.S	mt_dskpa
	SUB.W	#16,mt_PatternPos
mt_dskpa	TST.B	mt_PBreakFlag
	BEQ.S	mt_nnpysk
	SF	mt_PBreakFlag
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos,D0
	LSL.W	#4,D0
	MOVE.W	D0,mt_PatternPos
	CLR.B	mt_PBreakPos
mt_nnpysk
	CMP.W	#1024,mt_PatternPos
	BLO.S	mt_NoNewPosYet
mt_NextPosition	
	MOVEQ	#0,D0
	MOVE.B	mt_PBreakPos,D0
	LSL.W	#4,D0
	MOVE.W	D0,mt_PatternPos
	CLR.B	mt_PBreakPos
	CLR.B	mt_PosJumpFlag
	ADDQ.B	#1,mt_SongPos
	AND.B	#$7F,mt_SongPos
	MOVE.B	mt_SongPos,D1
	MOVE.L	mt_SongDataPtr,A0
	CMP.B	950(A0),D1
	BLO.S	mt_NoNewPosYet
	CLR.B	mt_SongPos
	
mt_NoNewPosYet	
	TST.B	mt_PosJumpFlag
	BNE.S	mt_NextPosition
mt_exit	MOVEM.L	(SP)+,D0-D7/A0-A6
	RTS

mt_CheckEffects
	BSR	mt_UpdateFunk
	MOVE.W	n_cmd(A6),D0
	AND.W	#$0FFF,D0
	BEQ.S	mt_Return
	MOVE.B	n_cmd(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_Arpeggio
	CMP.B	#1,D0
	BEQ	mt_PortaUp
	CMP.B	#2,D0
	BEQ	mt_PortaDown
	CMP.B	#3,D0
	BEQ	mt_TonePortamento
	CMP.B	#4,D0
	BEQ	mt_Vibrato
	CMP.B	#5,D0
	BEQ	mt_TonePlusVolSlide
	CMP.B	#6,D0
	BEQ	mt_VibratoPlusVolSlide
	CMP.B	#$E,D0
	BEQ	mt_E_Commands
SetBack	MOVE.W	n_period(A6),6(A5)
	CMP.B	#7,D0
	BEQ	mt_Tremolo
	CMP.B	#$A,D0
	BEQ	mt_VolumeSlide
mt_Return
	RTS

mt_PerNop
	MOVE.W	n_period(A6),6(A5)
	RTS

mt_Arpeggio
	MOVEQ	#0,D0
	MOVE.B	mt_counter,D0
	DIVS	#3,D0
	SWAP	D0
	CMP.W	#1,D0
	BEQ.S	mt_Arpeggio1
	CMP.W	#2,D0
	BEQ.S	mt_Arpeggio2
mt_Arpeggio0
	MOVE.W	n_period(A6),D2
	BRA mt_ArpeggioSet
	
mt_Arpeggio1
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	LSR.B	#4,D0
	BRA.S	mt_ArpeggioFind

mt_Arpeggio2
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#15,D0
mt_ArpeggioFind
	ADD.W	D0,D0
	MOVEQ	#0,D1
	MOVE.B	n_finetune(A6),D1
	MULU	#36*2,D1
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D1,A0
	MOVEQ	#0,D1
	MOVE.W	n_period(A6),D1
	MOVEQ	#36,D3
mt_arploop
	MOVE.W	(A0,D0.W),D2
	CMP.W	(A0),D1
	BHS.S	mt_ArpeggioSet
	ADDQ.L	#2,A0
	DBRA	D3,mt_arploop
	RTS

mt_ArpeggioSet
	MOVE.W	D2,6(A5)
	RTS

mt_FinePortaUp
	TST.B	mt_counter
	BNE.S	mt_Return
	MOVE.B	#$0F,mt_LowMask
mt_PortaUp
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	mt_LowMask,D0
	MOVE.B	#$FF,mt_LowMask
	SUB.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#$0071,D0
	BPL.S	mt_PortaUskip
	AND.W	#$F000,n_period(A6)
	OR.W	#$0071,n_period(A6)
mt_PortaUskip
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	MOVE.W	D0,6(A5)
	RTS	
 
mt_FinePortaDown
	TST.B	mt_counter
	BNE	mt_Return
	MOVE.B	#$0F,mt_LowMask
mt_PortaDown
	CLR.W	D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	mt_LowMask,D0
	MOVE.B	#$FF,mt_LowMask
	ADD.W	D0,n_period(A6)
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	CMP.W	#$0358,D0
	BMI.S	mt_PortaDskip
	AND.W	#$F000,n_period(A6)
	OR.W	#$0358,n_period(A6)
mt_PortaDskip
	MOVE.W	n_period(A6),D0
	AND.W	#$0FFF,D0
	MOVE.W	D0,6(A5)
	RTS

mt_SetTonePorta
	MOVE.L	A0,-(SP)
	MOVE.W	(A6),D2
	AND.W	#$0FFF,D2
	MOVEQ	#0,D0
	MOVE.B	n_finetune(A6),D0
	MULU	#37*2,D0
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D0,A0
	MOVEQ	#0,D0
mt_StpLoop
	CMP.W	(A0,D0.W),D2
	BHS.S	mt_StpFound
	ADDQ.W	#2,D0
	CMP.W	#37*2,D0
	BLO.S	mt_StpLoop
	MOVEQ	#35*2,D0
mt_StpFound
	MOVE.B	n_finetune(A6),D2
	AND.B	#8,D2
	BEQ.S	mt_StpGoss
	TST.W	D0
	BEQ.S	mt_StpGoss
	SUBQ.W	#2,D0
mt_StpGoss
	MOVE.W	(A0,D0.W),D2
	MOVE.L	(SP)+,A0
	MOVE.W	D2,n_wantedperiod(A6)
	MOVE.W	n_period(A6),D0
	CLR.B	n_toneportdirec(A6)
	CMP.W	D0,D2
	BEQ.S	mt_ClearTonePorta
	BGE	mt_Return
	MOVE.B	#1,n_toneportdirec(A6)
	RTS

mt_ClearTonePorta
	CLR.W	n_wantedperiod(A6)
	RTS

mt_TonePortamento
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_TonePortNoChange
	MOVE.B	D0,n_toneportspeed(A6)
	CLR.B	n_cmdlo(A6)
mt_TonePortNoChange
	TST.W	n_wantedperiod(A6)
	BEQ	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_toneportspeed(A6),D0
	TST.B	n_toneportdirec(A6)
	BNE.S	mt_TonePortaUp
mt_TonePortaDown
	ADD.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BGT.S	mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)
	BRA.S	mt_TonePortaSetPer

mt_TonePortaUp
	SUB.W	D0,n_period(A6)
	MOVE.W	n_wantedperiod(A6),D0
	CMP.W	n_period(A6),D0
	BLT.S	mt_TonePortaSetPer
	MOVE.W	n_wantedperiod(A6),n_period(A6)
	CLR.W	n_wantedperiod(A6)

mt_TonePortaSetPer
	MOVE.W	n_period(A6),D2
	MOVE.B	n_glissfunk(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_GlissSkip
	MOVEQ	#0,D0
	MOVE.B	n_finetune(A6),D0
	MULU	#37*2,D0
	LEA	mt_PeriodTable(PC),A0
	ADD.L	D0,A0
	MOVEQ	#0,D0
mt_GlissLoop
	CMP.W	(A0,D0.W),D2
	BHS.S	mt_GlissFound
	ADDQ.W	#2,D0
	CMP.W	#37*2,D0
	BLO.S	mt_GlissLoop
	MOVEQ	#35*2,D0
mt_GlissFound
	MOVE.W	(A0,D0.W),D2
mt_GlissSkip
	MOVE.W	D2,6(A5) ; Set period
	RTS

mt_Vibrato
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Vibrato2
	MOVE.B	n_vibratocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	mt_vibskip
	AND.B	#$F0,D2
	OR.B	D0,D2
mt_vibskip
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	mt_vibskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
mt_vibskip2
	MOVE.B	D2,n_vibratocmd(A6)
mt_Vibrato2
	MOVE.B	n_vibratopos(A6),D0
	LEA	mt_VibratoTable(PC),A4
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	AND.B	#3,D2
	BEQ.S	mt_vib_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	mt_vib_rampdown
	MOVE.B	#255,D2
	BRA.S	mt_vib_set
mt_vib_rampdown
	TST.B	n_vibratopos(A6)
	BPL.S	mt_vib_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	mt_vib_set
mt_vib_rampdown2
	MOVE.B	D0,D2
	BRA.S	mt_vib_set
mt_vib_sine
	MOVE.B	(A4,D0.W),D2
mt_vib_set
	MOVE.B	n_vibratocmd(A6),D0
	AND.W	#15,D0
	MULU	D0,D2
	LSR.W	#7,D2
	MOVE.W	n_period(A6),D0
	TST.B	n_vibratopos(A6)
	BMI.S	mt_VibratoNeg
	ADD.W	D2,D0
	BRA.S	mt_Vibrato3
mt_VibratoNeg
	SUB.W	D2,D0
mt_Vibrato3
	MOVE.W	D0,6(A5)
	MOVE.B	n_vibratocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_vibratopos(A6)
	RTS

mt_TonePlusVolSlide
	BSR	mt_TonePortNoChange
	BRA	mt_VolumeSlide

mt_VibratoPlusVolSlide
	BSR.S	mt_Vibrato2
	BRA	mt_VolumeSlide

mt_Tremolo
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_Tremolo2
	MOVE.B	n_tremolocmd(A6),D2
	AND.B	#$0F,D0
	BEQ.S	mt_treskip
	AND.B	#$F0,D2
	OR.B	D0,D2
mt_treskip
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	BEQ.S	mt_treskip2
	AND.B	#$0F,D2
	OR.B	D0,D2
mt_treskip2
	MOVE.B	D2,n_tremolocmd(A6)
mt_Tremolo2
	MOVE.B	n_tremolopos(A6),D0
	LEA	mt_VibratoTable(PC),A4
	LSR.W	#2,D0
	AND.W	#$001F,D0
	MOVEQ	#0,D2
	MOVE.B	n_wavecontrol(A6),D2
	LSR.B	#4,D2
	AND.B	#3,D2
	BEQ.S	mt_tre_sine
	LSL.B	#3,D0
	CMP.B	#1,D2
	BEQ.S	mt_tre_rampdown
	MOVE.B	#255,D2
	BRA.S	mt_tre_set
mt_tre_rampdown
	TST.B	n_vibratopos(A6)
	BPL.S	mt_tre_rampdown2
	MOVE.B	#255,D2
	SUB.B	D0,D2
	BRA.S	mt_tre_set
mt_tre_rampdown2
	MOVE.B	D0,D2
	BRA.S	mt_tre_set
mt_tre_sine
	MOVE.B	(A4,D0.W),D2
mt_tre_set
	MOVE.B	n_tremolocmd(A6),D0
	AND.W	#15,D0
	MULU	D0,D2
	LSR.W	#6,D2
	MOVEQ	#0,D0
	MOVE.B	n_volume(A6),D0
	TST.B	n_tremolopos(A6)
	BMI.S	mt_TremoloNeg
	ADD.W	D2,D0
	BRA.S	mt_Tremolo3
mt_TremoloNeg
	SUB.W	D2,D0
mt_Tremolo3
	BPL.S	mt_TremoloSkip
	CLR.W	D0
mt_TremoloSkip
	CMP.W	#$40,D0
	BLS.S	mt_TremoloOk
	MOVE.W	#$40,D0
mt_TremoloOk
	MOVE.W	D0,8(A5)
	MOVE.B	n_tremolocmd(A6),D0
	LSR.W	#2,D0
	AND.W	#$003C,D0
	ADD.B	D0,n_tremolopos(A6)
	RTS

mt_SampleOffset
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	BEQ.S	mt_sononew
	MOVE.B	D0,n_sampleoffset(A6)
mt_sononew
	MOVE.B	n_sampleoffset(A6),D0
	LSL.W	#7,D0
	CMP.W	n_length(A6),D0
	BGE.S	mt_sofskip
	SUB.W	D0,n_length(A6)
	LSL.W	#1,D0
	ADD.L	D0,n_start(A6)
	RTS
mt_sofskip
	MOVE.W	#$0001,n_length(A6)
	RTS

mt_VolumeSlide
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	LSR.B	#4,D0
	TST.B	D0
	BEQ.S	mt_VolSlideDown
mt_VolSlideUp
	ADD.B	D0,n_volume(A6)
	CMP.B	#$40,n_volume(A6)
	BMI.S	mt_vsuskip
	MOVE.B	#$40,n_volume(A6)
mt_vsuskip
	MOVE.B	n_volume(A6),D0
	RTS

mt_VolSlideDown
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
mt_VolSlideDown2
	SUB.B	D0,n_volume(A6)
	BPL.S	mt_vsdskip
	CLR.B	n_volume(A6)
mt_vsdskip
	MOVE.B	n_volume(A6),D0
	RTS

mt_PositionJump
	MOVE.B	n_cmdlo(A6),D0
	SUBQ.B	#1,D0
	MOVE.B	D0,mt_SongPos
mt_pj2	CLR.B	mt_PBreakPos
	ST 	mt_PosJumpFlag
	RTS

mt_VolumeChange
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	CMP.B	#$40,D0
	BLS.S	mt_VolumeOk
	MOVEQ	#$40,D0
mt_VolumeOk
	MOVE.B	D0,n_volume(A6)
	RTS

mt_PatternBreak
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	MOVE.L	D0,D2
	LSR.B	#4,D0
	MULU	#10,D0
	AND.B	#$0F,D2
	ADD.B	D2,D0
	CMP.B	#63,D0
	BHI.S	mt_pj2
	MOVE.B	D0,mt_PBreakPos
	ST	mt_PosJumpFlag
	RTS

mt_SetSpeed
	MOVEQ	#0,D0
	MOVE.B	3(A6),D0
	BEQ	_mt_end__Fv
	CMP.B	#32,D0
	BHS	SetTempo
	CLR.B	mt_counter
	MOVE.B	D0,mt_speed
	RTS

mt_CheckMoreEfx
	MOVE.B	2(A6),D0
	AND.B	#$0F,D0
	CMP.B	#$9,D0
	BEQ	mt_SampleOffset
	CMP.B	#$B,D0
	BEQ	mt_PositionJump
	CMP.B	#$D,D0
	BEQ.S	mt_PatternBreak
	CMP.B	#$E,D0
	BEQ.S	mt_E_Commands
	CMP.B	#$F,D0
	BEQ.S	mt_SetSpeed
	CMP.B	#$C,D0
	BEQ	mt_VolumeChange
	BRA	mt_PerNop

mt_E_Commands
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F0,D0
	LSR.B	#4,D0
	BEQ.S	mt_FilterOnOff
	CMP.B	#1,D0
	BEQ	mt_FinePortaUp
	CMP.B	#2,D0
	BEQ	mt_FinePortaDown
	CMP.B	#3,D0
	BEQ.S	mt_SetGlissControl
	CMP.B	#4,D0
	BEQ	mt_SetVibratoControl
	CMP.B	#5,D0
	BEQ	mt_SetFineTune
	CMP.B	#6,D0
	BEQ	mt_JumpLoop
	CMP.B	#7,D0
	BEQ	mt_SetTremoloControl
	CMP.B	#9,D0
	BEQ	mt_RetrigNote
	CMP.B	#$A,D0
	BEQ	mt_VolumeFineUp
	CMP.B	#$B,D0
	BEQ	mt_VolumeFineDown
	CMP.B	#$C,D0
	BEQ	mt_NoteCut
	CMP.B	#$D,D0
	BEQ	mt_NoteDelay
	CMP.B	#$E,D0
	BEQ	mt_PatternDelay
	CMP.B	#$F,D0
	BEQ	mt_FunkIt
	RTS

mt_FilterOnOff
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#1,D0
	ADD.B	D0,D0
	AND.B	#$FD,$BFE001
	OR.B	D0,$BFE001
	RTS	

mt_SetGlissControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_glissfunk(A6)
	OR.B	D0,n_glissfunk(A6)
	RTS

mt_SetVibratoControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	AND.B	#$F0,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS

mt_SetFineTune
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	MOVE.B	D0,n_finetune(A6)
	RTS

mt_JumpLoop
	TST.B	mt_counter
	BNE	mt_Return
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_SetLoop
	TST.B	n_loopcount(A6)
	BEQ.S	mt_jumpcnt
	SUBQ.B	#1,n_loopcount(A6)
	BEQ	mt_Return
mt_jmploop	MOVE.B	n_pattpos(A6),mt_PBreakPos
	ST	mt_PBreakFlag
	RTS

mt_jumpcnt
	MOVE.B	D0,n_loopcount(A6)
	BRA.S	mt_jmploop

mt_SetLoop
	MOVE.W	mt_PatternPos,D0
	LSR.W	#4,D0
	AND.B	#63,D0
	MOVE.B	D0,n_pattpos(A6)
	RTS

mt_SetTremoloControl
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	AND.B	#$0F,n_wavecontrol(A6)
	OR.B	D0,n_wavecontrol(A6)
	RTS

mt_RetrigNote
	MOVE.L	D1,-(SP)
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BEQ.S	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter,D1
	BNE.S	mt_rtnskp
	MOVE.W	n_note(A6),D1
	AND.W	#$0FFF,D1
	BNE.S	mt_rtnend
	MOVEQ	#0,D1
	MOVE.B	mt_counter,D1
mt_rtnskp
	DIVU	D0,D1
	SWAP	D1
	TST.W	D1
	BNE.S	mt_rtnend
mt_DoRetrig
	MOVE.W	n_dmabit(A6),$DFF096	; Channel DMA off
	MOVE.L	n_start(A6),(A5)	; Set sampledata pointer
	MOVE.W	n_length(A6),4(A5)	; Set length
	MOVE.W	n_period(A6),6(A5)  	; Set period
	
    MOVE.L	A0,-(SP)
	LEA	$DFF006,A0
	MOVEQ	#7-1,D1
lineloop6
	MOVE.B	(A0),D0
waiteol6
	CMP.B	(A0),D0
	BEQ.B	waiteol6
	DBRA	D1,lineloop6
		
	MOVE.W	n_dmabit(A6),D0
	BSET	#15,D0	; Set bits
	MOVE.W	D0,$DFF096
	
	MOVEQ	#7-1,D1
lineloop7
	MOVE.B	(A0),D0
waiteol7
	CMP.B	(A0),D0
	BEQ.B	waiteol7
	DBRA	D1,lineloop7
    MOVE.L	(SP)+,A0

	MOVE.L	n_loopstart(A6),(A5)
	MOVE.L	n_replen(A6),4(A5)
mt_rtnend
	MOVE.L	(SP)+,D1
	RTS

mt_VolumeFineUp
	TST.B	mt_counter
	BNE	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$F,D0
	BRA	mt_VolSlideUp

mt_VolumeFineDown
	TST.B	mt_counter
	BNE	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	BRA	mt_VolSlideDown2

mt_NoteCut
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	CMP.B	mt_counter,D0
	BNE	mt_Return
	CLR.B	n_volume(A6)
	RTS

mt_NoteDelay
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	CMP.B	mt_counter,D0
	BNE	mt_Return
	MOVE.W	(A6),D0
	AND.W	#$0FFF,D0
	BEQ	mt_Return
	MOVE.L	D1,-(SP)
	BRA	mt_DoRetrig

mt_PatternDelay
	TST.B	mt_counter
	BNE	mt_Return
	MOVEQ	#0,D0
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	TST.B	mt_PattDelTime2
	BNE	mt_Return
	ADDQ.B	#1,D0
	MOVE.B	D0,mt_PattDelTime
	RTS

mt_FunkIt
	TST.B	mt_counter
	BNE	mt_Return
	MOVE.B	n_cmdlo(A6),D0
	AND.B	#$0F,D0
	LSL.B	#4,D0
	AND.B	#$0F,n_glissfunk(A6)
	OR.B	D0,n_glissfunk(A6)
	TST.B	D0
	BEQ	mt_Return
mt_UpdateFunk
	MOVE.L	D1,-(SP)
	MOVE.L	A0,-(SP)
	MOVEQ	#0,D0
	MOVE.B	n_glissfunk(A6),D0
	LSR.B	#4,D0
	BEQ.S	mt_funkend
	LEA mt_FunkTable(PC),A0
	MOVE.B	(A0,D0.W),D0
	ADD.B	D0,n_funkoffset(A6)
	BTST	#7,n_funkoffset(A6)
	BEQ.S	mt_funkend
	CLR.B	n_funkoffset(A6)
	MOVE.L	n_wavestart(A6),A0
	CMP.L	#0,A0
	BEQ.B	mt_funkend
	MOVE.L	n_loopstart(A6),D0
	MOVEQ	#0,D1
	MOVE.W	n_replen(A6),D1
	ADD.L	D1,D0
	ADD.L	D1,D0
	ADDQ.L	#1,A0
	CMP.L	D0,A0
	BLO.S	mt_funkok
	MOVE.L	n_loopstart(A6),A0
mt_funkok
	MOVE.L	A0,n_wavestart(A6)
	MOVEQ	#-1,D0
	SUB.B	(A0),D0
	MOVE.B	D0,(A0)
mt_funkend
	MOVE.L	(SP)+,A0
	MOVE.L	(SP)+,D1
	RTS


mt_FunkTable dc.b 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

mt_VibratoTable	
	dc.b 0,24,49,74,97,120,141,161
	dc.b 180,197,212,224,235,244,250,253
	dc.b 255,253,250,244,235,224,212,197
	dc.b 180,161,141,120,97,74,49,24

mt_PeriodTable
; Tuning 0, Normal
	dc.w	856,808,762,720,678,640,604,570,538,508,480,453
	dc.w	428,404,381,360,339,320,302,285,269,254,240,226
	dc.w	214,202,190,180,170,160,151,143,135,127,120,113,0
; Tuning 1
	dc.w	850,802,757,715,674,637,601,567,535,505,477,450
	dc.w	425,401,379,357,337,318,300,284,268,253,239,225
	dc.w	213,201,189,179,169,159,150,142,134,126,119,113,0
; Tuning 2
	dc.w	844,796,752,709,670,632,597,563,532,502,474,447
	dc.w	422,398,376,355,335,316,298,282,266,251,237,224
	dc.w	211,199,188,177,167,158,149,141,133,125,118,112,0
; Tuning 3
	dc.w	838,791,746,704,665,628,592,559,528,498,470,444
	dc.w	419,395,373,352,332,314,296,280,264,249,235,222
	dc.w	209,198,187,176,166,157,148,140,132,125,118,111,0
; Tuning 4
	dc.w	832,785,741,699,660,623,588,555,524,495,467,441
	dc.w	416,392,370,350,330,312,294,278,262,247,233,220
	dc.w	208,196,185,175,165,156,147,139,131,124,117,110,0
; Tuning 5
	dc.w	826,779,736,694,655,619,584,551,520,491,463,437
	dc.w	413,390,368,347,328,309,292,276,260,245,232,219
	dc.w	206,195,184,174,164,155,146,138,130,123,116,109,0
; Tuning 6
	dc.w	820,774,730,689,651,614,580,547,516,487,460,434
	dc.w	410,387,365,345,325,307,290,274,258,244,230,217
	dc.w	205,193,183,172,163,154,145,137,129,122,115,109,0
; Tuning 7
	dc.w	814,768,725,684,646,610,575,543,513,484,457,431
	dc.w	407,384,363,342,323,305,288,272,256,242,228,216
	dc.w	204,192,181,171,161,152,144,136,128,121,114,108,0
; Tuning -8
	dc.w	907,856,808,762,720,678,640,604,570,538,508,480
	dc.w	453,428,404,381,360,339,320,302,285,269,254,240
	dc.w	226,214,202,190,180,170,160,151,143,135,127,120,0
; Tuning -7
	dc.w	900,850,802,757,715,675,636,601,567,535,505,477
	dc.w	450,425,401,379,357,337,318,300,284,268,253,238
	dc.w	225,212,200,189,179,169,159,150,142,134,126,119,0
; Tuning -6
	dc.w	894,844,796,752,709,670,632,597,563,532,502,474
	dc.w	447,422,398,376,355,335,316,298,282,266,251,237
	dc.w	223,211,199,188,177,167,158,149,141,133,125,118,0
; Tuning -5
	dc.w	887,838,791,746,704,665,628,592,559,528,498,470
	dc.w	444,419,395,373,352,332,314,296,280,264,249,235
	dc.w	222,209,198,187,176,166,157,148,140,132,125,118,0
; Tuning -4
	dc.w	881,832,785,741,699,660,623,588,555,524,494,467
	dc.w	441,416,392,370,350,330,312,294,278,262,247,233
	dc.w	220,208,196,185,175,165,156,147,139,131,123,117,0
; Tuning -3
	dc.w	875,826,779,736,694,655,619,584,551,520,491,463
	dc.w	437,413,390,368,347,328,309,292,276,260,245,232
	dc.w	219,206,195,184,174,164,155,146,138,130,123,116,0
; Tuning -2
	dc.w	868,820,774,730,689,651,614,580,547,516,487,460
	dc.w	434,410,387,365,345,325,307,290,274,258,244,230
	dc.w	217,205,193,183,172,163,154,145,137,129,122,115,0
; Tuning -1
	dc.w	862,814,768,725,684,646,610,575,543,513,484,457
	dc.w	431,407,384,363,342,323,305,288,272,256,242,228
	dc.w	216,203,192,181,171,161,152,144,136,128,121,114,0

	section	__MERGED,bss

_mt_chan1temp:
mt_chan1temp	ds.w	21
_mt_chan2temp:
mt_chan2temp	ds.w	21
_mt_chan3temp:
mt_chan3temp	ds.w	21
_mt_chan4temp:
mt_chan4temp	ds.w	21
				
_mt_SampleStarts
mt_SampleStarts
	ds.l	31

_mt_data:
mt_SongDataPtr	ds.l 1
_mt_speed:
mt_speed	ds.b 1
mt_counter	ds.b 1
_mt_SongPos
mt_SongPos	ds.b 1
mt_PBreakPos	ds.b 1
mt_PosJumpFlag	ds.b 1
mt_PBreakFlag	ds.b 1
mt_LowMask	ds.b 1
mt_PattDelTime	ds.b 1
mt_PattDelTime2	ds.b 1
_mt_Enable:
mt_Enable	ds.b 1
_mt_PatternPos:
mt_PatternPos	ds.w 1
mt_DMACONtemp	ds.w 1
_mt_chan1input:
mt_chan1input:	ds.l 1
_mt_chan2input:
mt_chan2input:	ds.l 1
_mt_chan3input:
mt_chan3input:	ds.l 1
_mt_chan4input:
mt_chan4input:	ds.l 1

	end
