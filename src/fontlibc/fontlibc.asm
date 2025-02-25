;-------------------------------------------------------------------------------
include '../include/library.inc'
include '../include/include_library.inc'
;-------------------------------------------------------------------------------

library 'FONTLIBC',2

;-------------------------------------------------------------------------------
; Dependencies
;-------------------------------------------------------------------------------
include_library '../graphx/graphx.asm'

;-------------------------------------------------------------------------------
; v1 functions
;-------------------------------------------------------------------------------
	export fontlib_SetWindow
	export fontlib_SetWindowFullScreen
	export fontlib_GetWindowXMin
	export fontlib_GetWindowYMin
	export fontlib_GetWindowWidth
	export fontlib_GetWindowHeight
	export fontlib_SetCursorPosition
	export fontlib_GetCursorX
	export fontlib_GetCursorY
	export fontlib_ShiftCursorPosition
	export fontlib_SetFont
	export fontlib_SetForegroundColor
	export fontlib_SetBackgroundColor
	export fontlib_SetColors
	export fontlib_GetForegroundColor
	export fontlib_GetBackgroundColor
	export fontlib_SetTransparency
	export fontlib_GetTransparency
	export fontlib_SetLineSpacing
	export fontlib_GetSpaceAbove
	export fontlib_GetSpaceBelow
	export fontlib_SetItalicSpacingAdjustment
	export fontlib_GetItalicSpacingAdjustment
	export fontlib_GetCurrentFontHeight
	export fontlib_ValidateCodePoint
	export fontlib_GetTotalGlyphs
	export fontlib_GetFirstGlyph
	export fontlib_SetNewlineCode
	export fontlib_GetNewlineCode
	export fontlib_SetAlternateStopCode
	export fontlib_GetAlternateStopCode
	export fontlib_SetFirstPrintableCodePoint
	export fontlib_GetFirstPrintableCodePoint
	export fontlib_SetDrawIntCodePoints
	export fontlib_GetDrawIntMinus
	export fontlib_GetDrawIntZero
	export fontlib_GetGlyphWidth
	export fontlib_GetStringWidth
	export fontlib_GetStringWidthL
	export fontlib_GetLastCharacterRead
	export fontlib_DrawGlyph
	export fontlib_DrawString
	export fontlib_DrawStringL
	export fontlib_DrawInt
	export fontlib_DrawUInt
	export fontlib_ClearEOL
	export fontlib_ClearWindow
	export fontlib_Newline
	export fontlib_SetNewlineOptions
	export fontlib_GetNewlineOptions
;-------------------------------------------------------------------------------
; v1 font pack functions
;-------------------------------------------------------------------------------
	export fontlib_GetFontPackName
	export fontlib_GetFontByIndex
	export fontlib_GetFontByIndexRaw
	export fontlib_GetFontByStyle
	export fontlib_GetFontByStyleRaw
;-------------------------------------------------------------------------------
; v2 functions
;-------------------------------------------------------------------------------
	export fontlib_ScrollWindowDown
	export fontlib_ScrollWindowUp
	export fontlib_Home
	export fontlib_HomeUp


;-------------------------------------------------------------------------------
CurrentBuffer	:= ti.mpLcdLpbase
TEXT_FG_COLOR	:= 0
TEXT_BG_COLOR	:= 255
local2		:= -9
local1		:= -6
local0		:= -3
arg00		:= 0
arg0		:= 3
arg1		:= 6
arg2		:= 9
arg3		:= 12
arg4		:= 15
arg5		:= 18
arg6		:= 21
chFirstPrintingCode := $10
chNewline	:= $0A
bEnableAutoWrap	:= 0
mEnableAutoWrap	:= 1 shl bEnableAutoWrap
bAutoClearToEOL	:= 1
mAutoClearToEOL	:= 1 shl bAutoClearToEOL
bPreclearNewline := 2
mPreclearNewline := 1 shl bPreclearNewline
bWasNewline	:= 7
mWasNewline	:= 1 shl bWasNewline
bAutoScroll	:= 3
mAutoScroll	:= 1 shl bAutoScroll


;-------------------------------------------------------------------------------
; Declare the structure of a raw font
struc strucFont
	label .: 15
	.version			rb	1
	.height				rb	1
	.totalGlyphs			rb	1
	.firstGlyph			rb	1
	.widthsTablePtr			rl	1
	.bitmapsTablePtr		rl	1
	.italicSpaceAdjust		rb	1
	.spaceAbove			rb	1
	.spaceBelow			rb	1
	.weight				rb	1
	.style				rb	1
end struc
virtual at 0
strucFont strucFont
end virtual
strucFont.fontPropertiesSize := strucFont.italicSpaceAdjust
struc strucFontPackHeader
	label .: 13
	.identifier			rb	8
	.metadatOffset			rl	1
	.fontCount			rb	1
	.fontList			rl	1
end struc
virtual at 0
strucFontPackHeader strucFontPackHeader
end virtual


;-------------------------------------------------------------------------------
macro mIsHLLessThanDE?
	or	a,a
	sbc	hl,de
	add	hl,hl
	jp	po,$+5
	ccf
end macro
macro mIsHLLessThanBC?
	or	a,a
	sbc	hl,bc
	add	hl,hl
	jp	po,$+5
	ccf
end macro
macro s8 op,imm
	local i
 	i = imm
	assert i >= -128 & i < 128
	op,i
end macro

;-------------------------------------------------------------------------------
macro setSmcBytes name*
	local addr,data
	postpone
		virtual at addr
			irpv each,name
				if % = 1
					db %%
				end if
				assert each >= addr + 1 + 2*%%
				dw each - $ - 2
			end irpv
			load data: $-$$ from $$
		end virtual
	end postpone

	call	_SetSmcBytes
addr	db	data
end macro

macro setSmcBytesFast name*
	local temp,list
	postpone
		temp equ each
		irpv each,name
			temp equ temp,each
		end irpv
		list equ temp
	end postpone

	pop	de			; de = return vetor
	ex	(sp),hl			; l = byte
	ld	a,l			; a = byte
	match expand,list
		iterate expand
			if % = 1
				ld	hl,each
				ld	c,(hl)
				ld	(hl),a
			else
				ld	(each),a
			end if
		end iterate
	end match
	ld	a,c			; a = old byte
	ex	de,hl			; hl = return vector
	jp	(hl)
end macro

macro smcByte name*,addr: $-1
	local link
	link := addr
	name equ link
end macro

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
fontlib_SetWindowFullScreen:
; Sets the bounds of the box all text will appear in to be the full screen
; Arguments:
;  None
; Returns:
;  Nothing
	ld	hl,_TextDefaultWindow
	ld	de,_TextXMin
	jp	ti.Mov8b


;-------------------------------------------------------------------------------
fontlib_SetWindow:
; Sets the bounds of the box all text will appear in
; Arguments:
;  arg0: X min
;  arg1: Y min
;  arg2: width
;  arg3: height
; Returns:
;  Nothing
	pop	de			; de = return vector
	pop	hl			; hl = xmin
	ld	(_TextXMin),hl
	pop	bc			; c = ymin
	ld	a,c			; a = ymin
	ld	(_TextYMin),a
	pop	bc			; bc = width
	add	hl,bc			; hl = xmin + width = xmax
	ld	(_TextXMax),hl
	ex	(sp),hl			; l = height
	add	a,l			; a = ymin + height = ymax
	ld	(_TextYMax),a
	push	hl
	push	hl
	push	hl			; sp -> arg0
	ex	de,hl			; hl = return vector
	jp	(hl)


;-------------------------------------------------------------------------------
fontlib_GetWindowXMin:
; Returns the starting column of the current text window
; Arguments:
;  None
; Returns:
;  Data
	ld	hl,(_TextXMin)
	ret


;-------------------------------------------------------------------------------
fontlib_GetWindowYMin:
; Returns the starting row of the current text window
; Arguments:
;  None
; Returns:
;  Data
	ld	a,(_TextYMin)
	ret


;-------------------------------------------------------------------------------
fontlib_GetWindowWidth:
; Returns the width of the current text window
; Arguments:
;  None
; Returns:
;  Data
; Should preserve DE, as window scrolling needs DE preserved
	ld	hl,(_TextXMax)
	ld	bc,(_TextXMin)
	or	a,a
	sbc	hl,bc
	ret


;-------------------------------------------------------------------------------
fontlib_GetWindowHeight:
; Returns the height of the current text window
; Arguments:
;  None
; Returns:
;  Data
	ld	a,(_TextYMax)
	ld	hl,_TextYMin
	sub	a,(hl)
	ret


;-------------------------------------------------------------------------------
fontlib_SetCursorPosition:
; Sets the cursor position for text drawing
; Arguments:
;  arg0: X
;  arg1: Y
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	de,_TextX
	ld	bc,4
	ldir
	ret


;-------------------------------------------------------------------------------
fontlib_GetCursorX:
; Gets the cursor column
; Arguments:
;  None
; Returns:
;  Column
	ld	hl,(_TextX)
	ret


;-------------------------------------------------------------------------------
fontlib_GetCursorY:
; Gets the cursor row
; Arguments:
;  None
; Returns:
;  Row
	ld	a,(_TextY)
	ret


;-------------------------------------------------------------------------------
fontlib_ShiftCursorPosition:
; Shifts the cursor position by a given signed delta.
; By limiting x to 0xFFFF and y to 0xFF, the cursor can't get far enough out of
; VRAM to cause corruption of any other regions of memory.
; Arguments:
;  arg0: delta X
;  arg1: delta Y
; Returns:
;  Nothing
	pop	de			; de = return vector
; Shift x
	pop	bc			; bc = dx
	ld	hl,(_TextX)		; hl = x
	add.s	hl,bc			; hl = (x + dx) & 0xFFFF
	ld	(_TextX),hl		; x = x + dx
; Shift y
	pop	bc			; bc = dy
	ld	hl,_TextY
	ld	a,(hl)			; a = y
	add	a,c			; a = (y + dy) & 0xFF
	ld	(hl),a			; y = (y + dy) & 0xFF
; Finish
	push	hl
	push	hl			; sp -> arg0
	ex	de,hl			; hl = return vector
	jp	(hl)


;-------------------------------------------------------------------------------
fontlib_HomeUp:
; Moves the cursor to the upper left corner of the text window
; Arguments:
;  None
; Returns:
;  Nothing
	ld	a,(_TextYMin)
	ld	(_TextY),a
; Fall through to fontlib_Home
assert $ = fontlib_Home


;-------------------------------------------------------------------------------
; Moves the cursor back to the start of the current line
fontlib_Home:
; Arguments:
;  None
; Returns:
;  Nothing
	ld	hl,(_TextXMin)
	ld	(_TextX),hl
	ret


;-------------------------------------------------------------------------------
fontlib_SetFont:
; Sets the current font to the data at the pointer given
; Arguments:
;  arg0: Pointer to font
;  arg1: Load flags
; Returns:
;  bool:
;     - true if font loaded successfully
;     - false on failure (invalid font, or you tried to use the version byte)
	ld	hl,arg0
	add	hl,sp
	ld	hl,(hl)
; Verify version byte is zero like it's supposed to be
; The literal only reason there's any validation here at all is to
; enforce keeping the version byte reserved.
	xor	a,a
	cp	a,(hl)
	ret	nz
; Load font data
	ld	(_CurrentFontRoot),hl
	push	hl
	ld	de,_CurrentFontProperties
	ld	bc,strucFont.fontPropertiesSize
	ldir
	pop	bc
	ld	iy,_CurrentFontProperties
; Verify height at least looks semi-reasonable
	ld	a,(iy + strucFont.height)
	or	a,a
	ret	z			; Also unreasonable: a zero-height font
	and	a,$80
	jr	nz,.false
	ld	a,63
	cp	a,(iy + strucFont.spaceAbove)
	jr	c,.false
	cp	a,(iy + strucFont.spaceBelow)
	jr	c,.false
.validateOffsets:
; Now convert offsets into actual pointers
; Validate that offset is at least semi-reasonable
	ld	de,$ff00		; Maximum reasonable font data size
	ld	hl,(iy + strucFont.widthsTablePtr)
	sbc	hl,de			; Doesn't really matter if we're off-by-one here
	ret	nc
	add	hl,de
	add	hl,bc
	ld	(iy + strucFont.widthsTablePtr),hl
	ld	hl,(iy + strucFont.bitmapsTablePtr)
	sbc	hl,de			; C reset from ADD HL,BC above
	ret	nc			; (we're in Crazytown if there was carry)
	add	hl,de
	add	hl,bc
	ld	(iy + strucFont.bitmapsTablePtr),hl
; Check for the ignore ling spacing flag
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	or	a
	jr	z,.true
	lea	hl,iy + strucFont.spaceAbove
	xor	a
	ld	(hl),a
	inc	hl
	ld	(hl),a
.true:	ld	a,1
	ret
.false:
	xor	a,a
	ret


;-------------------------------------------------------------------------------
fontlib_DrawGlyph:
; Draws a glyph to the current cursor position
; Arguments:
;  arg0: codepoint
; Returns:
;  New X cursor value
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	push	ix			; _DrawGlyphRaw destroys IX
; Compute write pointer
	ld	hl,(_TextY)
	ld	h,ti.lcdWidth / 2
	mlt	hl
	add	hl,hl
	ld	de,(_TextX)
	push	de
	add	hl,de
	ld	de,(CurrentBuffer)
	add	hl,de
	call	util.DrawGlyphRaw	; Draw glyph
; Update _TextX
	lea.sis	de,iy + 0
	pop	hl
	add	hl,de
	ld	a,(_CurrentFontProperties.italicSpaceAdjust)
	pop	ix
	ld	e,a
	sbc	hl,de
	ld	(_TextX),hl
	ret


;-------------------------------------------------------------------------------
util.DrawGlyphRaw:
; Handles the actual main work of drawing a glyph.
; Arguments:
;  HL: Draw pointer
;  A: Glyph index
;  Font properties variables
; Returns:
;  IYL: Width of glyph (not including any italicSpaceAdjust)
;  IYH: Zero
;  IYU: Untouched
;  Glyph drawn
; Destroys:
;  Basically everything except shadow and configuration registers.
;  And don't count on that not changing.
	push	hl
; Subtract out firstGlyph
	ld	hl,_CurrentFontProperties.firstGlyph
	sub	a,(hl)
; Get glyph width
	ld	c,a
	or	a,a
	sbc	hl,hl
	ld	l,a
	ld	de,(_CurrentFontProperties.widthsTablePtr)
	add	hl,de
	ld	a,(hl)
	pop	de
	call	gfx_Wait
;	jp	util.DrawGlyphRawKnownWidth
assert $ = util.DrawGlyphRawKnownWidth


;-------------------------------------------------------------------------------
util.DrawGlyphRawKnownWidth:
; Handles the actual main work of drawing a glyph.
; Arguments:
;  DE: Draw pointer
;  C: Glyph index, with _CurrentFontProperties.firstGlyph subtracted out
;  A: Glyph width
;  Font properties variables
; Returns:
;  IYL: Width of glyph (not including any italicSpaceAdjust)
;  IYH: Zero
;  IYU: Untouched
;  Glyph drawn
; Destroys:
;  Basically everything except shadow and configuration registers.
;  And don't count on that not changing.

; Update loop controls
	ld	iyl,a
	dec	a
	rra
	srl	a
	srl	a
	inc	a
	ld	(_TextStraightBytesPerRow),a
	ld	a,320 and 255
	sub	a,iyl
	ld	(_TextStraightRowDelta - 2),a
; Get pointer to bitmap
	ld	hl,(_CurrentFontProperties.bitmapsTablePtr)
	ld	b,2
	mlt	bc			; Performs both the multiply and zeros BCU
	add	hl,bc
	ld	ix,(hl)
	lea.sis	ix,ix + 0		; Truncate to 16-bits
	ld	bc,(_CurrentFontRoot)
	add	ix,bc
; Write SMC
	ld	a,(_TextTransparentMode)
	ld	b,a
	ld	a,.unsetColumnLoopStart - (.unsetColumnLoopJr1 + 2)
	ld	c,.unsetColumnLoopStart - (.unsetColumnLoopJr2 + 2)
	djnz	.writeSmc
	ld	a,.unsetColumnLoopMiddleTransparent - (.unsetColumnLoopJr1 + 2)
	ld	c,.unsetColumnLoopMiddleTransparent - (.unsetColumnLoopJr2 + 2)
.writeSmc:
	ld	(.unsetColumnLoopJr1 + 1),a
	ld	a,c
	ld	(.unsetColumnLoopJr2 + 1),a
	push	bc
; Now deal with the spaceAbove metric
	ld	a,(_CurrentFontProperties.spaceAbove)
	or	a,a
	call	nz,util.DrawEmptyLines
	ld	c,TEXT_FG_COLOR		; SMCd to have correct foreground color
smcByte _TextStraightForegroundColor
	ld	a,(_CurrentFontProperties.height)
	ld	iyh,a
	ld	a,c

; Registers:
;  B: Bit counter for each row
;  C: Foreground color
;  IYL: Glyph data width
;  IYH: Row counter
;  IX: Read pointer
;  DE: Write pointer
;  HL: Current line bitmap
; This is split into three loops: one for set pixels, one for unset pixels that
; are transparent, and one for unset pixels that are opaque.
; The idea is that pixels are not randomly black or white; rather, there tend
; to be horizontal lines in text, giving straight runs of pixels the same color.
; Thus, we can optimize for that case.
.rowLoop:
	ld	hl,(ix)
	lea	ix,ix + 0		; SMCd to have correct byte count per row
smcByte _TextStraightBytesPerRow
	ld	b,iyl
.columnLoopStart:
	add	hl,hl
.unsetColumnLoopJr1:
	jr	nc,.unsetColumnLoopStart

; For set pixels
.setColumnLoopStart:
	ld	a,c
	ld	(de),a
	inc	de
	dec	b
	jr	z,.columnLoopEnd
.setColumnLoop:
	add	hl,hl
.unsetColumnLoopJr2:
	jr	nc,.unsetColumnLoopStart
.setColumnLoopMiddle:
	ld	(de),a
	inc	de
	djnz	.setColumnLoop
	jr	.columnLoopEnd

; For unset pixels, we use a special loop if transparency is requested
.unsetColumnLoopTransparent:
	add	hl,hl
	jr	c,.setColumnLoopMiddle
.unsetColumnLoopMiddleTransparent:
	inc	de
	djnz	.unsetColumnLoopTransparent
	jr	.columnLoopEnd

; For unset pixels with opacity on
.unsetColumnLoopStart:
	ld	a,TEXT_BG_COLOR		; SMCd to have correct background color
smcByte _TextStraightBackgroundColor
	ld	(de),a
	inc	de
	dec	b
	jr	z,.columnLoopEnd
.unsetColumnLoop:
	add	hl,hl
	jr	c,.setColumnLoopStart
.unsetColumnLoopMiddle:
	ld	(de),a
	inc	de
	djnz	.unsetColumnLoop

.columnLoopEnd:
	ld	hl,ti.lcdWidth - 0		; SMCd to have correct row delta
smcByte _TextStraightRowDelta
	add	hl,de
	ex	de,hl
	dec	iyh
	jr	nz,.rowLoop

; OK done with the main work!
; Now deal with the spaceBelow metric
	pop	bc
	ld	a,(_CurrentFontProperties.spaceBelow)
	or	a,a
	ret	z

util.DrawEmptyLines:
; Internal routine that draws empty space for a glyph
; Arguments:
;  A: Number of lines to draw (nonzero)
;  B: -1 = opaque, 0 = transparent
;  IYL: Width of line to draw
;  DE: Drawing target
;  (_TextStraightRowDelta - 2): Row delta
; Returns:
;  Lines drawn
; Destroys:
;  AF
;  BC
;  HL
	ex	de,hl
	ld	c,a
	inc	b
	jr	nz,.transparentLines
; Deal with clearing out pixels
	ld	a,(_TextStraightBackgroundColor)
	ld	de,(_TextStraightRowDelta - 2)
.clearLinesLoop:
	ld	b,iyl
.clearLinesInnerLoop:
	ld	(hl),a
	inc	hl
	djnz	.clearLinesInnerLoop
	add	hl,de
	dec	c
	jr	nz,.clearLinesLoop
	ex	de,hl
	ret
.transparentLines:
	ld	b,ti.lcdWidth / 2
	mlt	bc
	add	hl,bc
	add	hl,bc
	ex	de,hl
	ret


;-------------------------------------------------------------------------------
fontlib_DrawString:
; Draws a string,ending when either:
;  an unknown control code is encountered (or NULL), or there is no more space
;  left in the window.
; Arguments:
;  arg0: Pointer to string
;  arg1: Maximum number of characters have been printed
; Returns:
;  New X cursor value
	pop	bc
	ld	(.retter + 1),bc
	pop	de
	scf
	sbc	hl,hl
	push	hl
	push	de
	call	fontlib_DrawStringL
	pop	de
.retter:
	jp	0


;-------------------------------------------------------------------------------
fontlib_DrawStringL:
; Draws a string, ending when any of the following is true:
;  arg1 characters have been printed;
;  an unknown control code is encountered (or NULL); or,
;  there is no more space left in the window.
; Arguments:
;  arg0: Pointer to string
;  arg1: Maximum number of characters have been printed
; Returns:
;  New X cursor value
	push	ix
; Since reentrancy isn't likely to be needed. . . .
; Instead of using stack locals, just access all our local and global
; variables via the (IX + offset) addressing mode.
	ld	ix,DataBaseAddr
	res	bWasNewline,(ix + newlineControl)
	ld	iy,0
	add	iy,sp
	ld	hl,(iy + arg1)
	dec	hl			; We're reading the string with pre-increment,
	ld	(ix + strReadPtr),hl	; so we need an initial pre-decrement
	ld	hl,(iy + arg2)
	ld	(ix + charactersLeft),hl
.restartX:
; Compute target drawing address
	ld	hl,(_TextY)
	ld	h,ti.lcdWidth / 2
	mlt	hl
	add	hl,hl
	ld	bc,(ix + textX)
	add	hl,bc
	ld	bc,(CurrentBuffer)
	add	hl,bc
	ex	de,hl
	call	gfx_Wait
.mainLoop:
; Check that we haven't exceeded our glyph printing limit
	ld	bc,(ix + charactersLeft)
	sbc	hl,hl
	adc	hl,bc
	jr	z,.exit
	dec	bc
	ld	(ix + charactersLeft),bc
; Read & validate glyph
	ld	hl,(ix + strReadPtr)
	inc	hl
	ld	(ix + strReadPtr),hl
; Read character
	ld	a,(hl)
; Check if control code
	cp	a,(ix + firstPrintableCodePoint)
	jr	nc,.notControlCode
	or	a,a
	jr	z,.exit
	cp	a,(ix + newLineCode)
	jr	z,.printNewline
.exit:	ld	hl,(ix + textX)
	pop	ix
	ret
.notControlCode:
	cp	a,(ix + alternateStopCode)
	jr	z,.exit
; Check if font has given codepoint
	sub	a,(ix + strucFont.firstGlyph)
	jr	c,.exit
	sbc	hl,hl			; Zero for later
	ld	l,a
	sub	a,(ix + strucFont.totalGlyphs)
	jr	c,.definitelyValid
	cp	a,l			; 0 = 256 total glyphs,so check for zero
	jr	nz,.exit		; Z iff L == A, which is true iff totalGlyphs == 0
.definitelyValid:
	ld	(ix + readCharacter),l
; Look up width
	ld	bc,(ix + strucFont.widthsTablePtr)
	add	hl,bc
	ld	a,(hl)
; Check if glyph will fit in window
	ld	hl,(ix + textX)
	ld	bc,0
	ld	c,a
	add	hl,bc
	ld	bc,(ix + textXMax)
;	or	a,a			; C should already be reset from ADD HL,BC
	sbc	hl,bc
	add	hl,bc
	jr	z,.colOK
	jr	nc,.newline
; Correct for italicness
.colOK:	ld	c,(ix + strucFont.italicSpaceAdjust)
	ld	b,0
	or	a,a
	sbc	hl,bc
	ld	(ix + textX),hl
; OK,ready to draw the glyph
	ld	c,(ix + readCharacter)
	push	de
	call	util.DrawGlyphRawKnownWidth
	pop	de
	ld	ix,DataBaseAddr
; Update write pointer
	ld	a,iyl
	sub	a,(ix + strucFont.italicSpaceAdjust)
	sbc	hl,hl			; Sign-extend A for HL
	ld	l,a
	add	hl,de
	ex	de,hl
	jr	.mainLoop
.printNewline:
; Keep track of whether or not printing the current character needs to be retried
	set	bWasNewline,(ix + newlineControl)
.newline:
	bit	bWasNewline,(ix + newlineControl)
	jr	nz,.doNewline
	bit	bEnableAutoWrap,(ix + newlineControl)
	jr	z,.exit
.doNewline:
	call	fontlib_Newline
	or	a,a
	jr	nz,.exit
	bit	bWasNewline,(ix + newlineControl)
	res	bWasNewline,(ix + newlineControl)
	jp	nz,.restartX
	ld	hl,(ix + strReadPtr)
	dec	hl
	ld	(ix + strReadPtr),hl
	jp	.restartX


;-------------------------------------------------------------------------------
fontlib_DrawInt:
; Places an int at the current cursor position
; Shamelessly ripped from GraphX, which admittedly adapted it from Z80 Bits
; Arguments:
;  arg0 : Number to print
;  arg1 : Number of characters to print
; Returns:
;  None
	pop	de
	pop	hl
	push	hl
	push	de
	add	hl,hl
	db	$3E			; xor a,a -> ld a,*

;-------------------------------------------------------------------------------
fontlib_DrawUInt:
; Places an unsigned int at the current cursor position
; Arguments:
;  arg0 : Number to print
;  arg1 : Minimum number of characters to print
; Returns:
;  None
	xor	a,a
	pop	de
	pop	hl			; hl = uint
	pop	bc			; c = min num chars
	push	bc
	push	hl
	push	de
	jr	nc,.begin		; c ==> actually a negative int
	ex	de,hl
	or	a,a
	sbc	hl,hl
	sbc	hl,de			; hl = -int
	ld	a,'-'
smcByte _DrawIntMinus
	call	.printchar
	dec	c
	jr	nz,.begin
	inc	c
.begin:
	ld	de,-10000000
	call	.num1
	ld	de,-1000000
	call	.num1
	ld	de,-100000
	call	.num1
	ld	de,-10000
	call	.num1
	ld	de,-1000
	call	.num1
	ld	de,-100
	call	.num1
	ld	de,-10
	call	.num1
	ld	de,-1
.num1:
	xor	a,a
.num2:
	inc	a
	add	hl,de
	jr	c,.num2
	sbc	hl,de
	dec	a			; a = next digit
	jr	nz,.printdigit		; z ==> digit is zero, maybe don't print
	ld	a,c
	inc	c
	cp	a,8
	ret	c			; nc ==> a digit has already been
					;        printed, or must start printing
					;        to satisfy min num chars
	xor	a,a
.printdigit:
	add	a,'0'
smcByte _DrawIntZero
	ld	c,a			; mark that a digit has been printed
.printchar:
	push	bc
	push	hl
	ld	c,a
	push	bc
	call	fontlib_DrawGlyph
	pop	bc
	pop	hl
	pop	bc
	ret


;-------------------------------------------------------------------------------
fontlib_SetForegroundColor:
; Sets the foreground color
; Arguments:
;  arg0: Color
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	(_TextStraightForegroundColor),a
	ret


;-------------------------------------------------------------------------------
fontlib_SetBackgroundColor:
; Sets the background color
; Arguments:
;  arg0: Color
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	(_TextStraightBackgroundColor),a
	ret


;-------------------------------------------------------------------------------
fontlib_SetColors:
; Sets both foreground and background color
; Arguments:
;  arg0: Foreground color
;  arg1: Background color
; Returns:
;  Nothing
	ld	iy,0
	add	iy,sp
	ld	a,(iy + arg0)
	ld	(_TextStraightForegroundColor),a
	ld	a,(iy + arg1)
	ld	(_TextStraightBackgroundColor),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetForegroundColor:
; Gets the foreground color
; Arguments:
;  None
; Returns:
;  Current color
	ld	a,(_TextStraightForegroundColor)
	ret


;-------------------------------------------------------------------------------
fontlib_GetBackgroundColor:
; Gets the background color
; Arguments:
;  None
; Returns:
;  Current color
	ld	a,(_TextStraightBackgroundColor)
	ret


;-------------------------------------------------------------------------------
fontlib_SetTransparency:
; Controls whether transparent background mode is used
; Arguments:
;  arg0: Non-zero for transparent mode, zero for opaque
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	sub	a,1			; Set carry if A = 0
	sbc	a,a			; 0 => -1, else => 0
	inc	a			; 0 => 0, else => 1
	ld	(_TextTransparentMode),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetTransparency:
; Returns whether transparent background mode is being used
; Arguments:
;  None
; Returns:
;  1 if transparent, 0 if opaque
	ld	a,(_TextTransparentMode)
	ret


;-------------------------------------------------------------------------------
fontlib_SetLineSpacing:
; Sets line spacing
; Arguments:
;  arg0: Space above
;  arg1: Space below
; Returns:
;  Nothing
	ld	iy,0
	add	iy,sp
	ld	a,(iy + arg0)
	ld	(_CurrentFontProperties.spaceAbove),a
	ld	a,(iy + arg1)
	ld	(_CurrentFontProperties.spaceBelow),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetSpaceAbove:
; Returns current padding space above
; Arguments:
;  None
; Returns:
;  Padding space above
	ld	a,(_CurrentFontProperties.spaceAbove)
	ret


;-------------------------------------------------------------------------------
fontlib_GetSpaceBelow:
; Returns current padding space below
; Arguments:
;  None
; Returns:
;  Padding space below
	ld	a,(_CurrentFontProperties.spaceBelow)
	ret


;-------------------------------------------------------------------------------
fontlib_SetItalicSpacingAdjustment:
; Sets current spacing adjustment for italic text.  This causes the cursor to be
; moved back a certain number of pixels after every glyph is drawn.  This is
; only useful if transparency mode is set.
; Arguments:
;  arg0: Pixels to move cursor backward after each glyph
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	(_CurrentFontProperties.italicSpaceAdjust),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetItalicSpacingAdjustment:
; Returns current spacing adjustment for italic text
; Arguments:
;  None
; Returns:
;  Spacing adjustment value
	ld	a,(_CurrentFontProperties.italicSpaceAdjust)
	ret


;-------------------------------------------------------------------------------
fontlib_GetCurrentFontHeight:
; Returns the height of the current font
; Arguments:
;  None
; Returns:
;  Height
	ld	a,(_CurrentFontProperties.height)
	ld	hl,_CurrentFontProperties.spaceAbove
	add	a,(hl)
	inc	hl
	add	a,(hl)
	ret


;-------------------------------------------------------------------------------
fontlib_ValidateCodePoint:
; Returns true if the given code point is present in the current font.
; Arguments:
;  arg0: Glyph index
; Returns:
;  true (1) if present, false (0) if not
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	hl,_CurrentFontProperties.firstGlyph
	sub	a,(hl)
	ccf
	jr	nc,.exit
	ld	hl,_CurrentFontProperties.totalGlyphs
; Check if totalGlyphs is zero
	ld	b,(hl)
	inc	b
	dec	b
	jr	z,.exit
	sub	a,(hl)
.exit:	sbc	a,a
	and	a,1
	ret


;-------------------------------------------------------------------------------
fontlib_GetTotalGlyphs:
; Returns the total number of printable glyphs in the font.
; This can return 256.
; Arguments:
;  None
; Returns:
;  Total number of printable glyphs
	or	a,a
	sbc	hl,hl
	ld	a,(_CurrentFontProperties.totalGlyphs)
	ld	l,a
	or	a,a
	ret	nz
	inc	h
	ret


;-------------------------------------------------------------------------------
fontlib_GetFirstGlyph:
; Returns the code point of the first printable glyph.
; Arguments:
;  None
; Returns:
;  Total number of printable glyphs
	ld	a,(_CurrentFontProperties.firstGlyph)
	ret


;-------------------------------------------------------------------------------
fontlib_SetNewlineCode:
; Set the code point that is recognized as being a newline code.
; Arguments:
;  arg0: New code point to use
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	(_TextNewLineCode),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetNewlineCode:
; Returns the code point that is currently recognized as being a newline.
; Arguments:
;  None
; Returns:
;  Code point that is currently recognized as being a newline
	ld	a,(_TextNewLineCode)
	ret


;-------------------------------------------------------------------------------
fontlib_SetAlternateStopCode:
; Set the code point that is recognized as being an alternate stop code.
; Arguments:
;  arg0: New code point to use
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	(_TextAlternateStopCode),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetAlternateStopCode:
; Returns the code point that is currently recognized as being an alternate stop
; code.
; Arguments:
;  None
; Returns:
;  Code point that is currently recognized as being an alternate stop code
	ld	a,(_TextAlternateStopCode)
	ret


;-------------------------------------------------------------------------------
fontlib_SetFirstPrintableCodePoint:
; Set the code point that is recognized as being an alternate stop code.
; Arguments:
;  arg0: New code point to use
; Returns:
;  Nothing
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	(_TextFirstPrintableCodePoint),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetFirstPrintableCodePoint:
; Returns the first code point that is currently recognized as being printable.
; code.
; Arguments:
;  None
; Returns:
;  Code point that is currently recognized as being the first printable code
;    point.
	ld	a,(_TextFirstPrintableCodePoint)
	ret


;-------------------------------------------------------------------------------
fontlib_SetDrawIntCodePoints:
; Changes the code points printed using DrawInt/DrawUInt
; Arguments:
;  arg0: Negative symbol code point
;  arg1: Zero glyph code point
; Returns:
;  Nothing
	ld	iy,0
	add	iy,sp
	ld	a,(iy + arg0)
	ld	(_DrawIntMinus),a
	ld	a,(iy + arg1)
	ld	(_DrawIntZero),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetDrawIntMinus:
; Returns the minus code point used by DrawInt/DrawUInt
; Arguments:
;  None
; Returns:
;  Minus
	ld	a, (_DrawIntMinus)
	ret


;-------------------------------------------------------------------------------
fontlib_GetDrawIntZero:
; Returns the '0' code point used by DrawInt/DrawUInt
; Arguments:
;  None
; Returns:
;  '0'
	ld	a, (_DrawIntZero)
	ret


;-------------------------------------------------------------------------------
fontlib_GetGlyphWidth:
; Returns the width of a given glyph.
; Arguments:
;  arg0: Codepoint
; Returns:
;  Width of glyph
;    Zero if invalid index
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
;	jp	util.GetGlyphWidth
assert $ = util.GetGlyphWidth


;-------------------------------------------------------------------------------
util.GetGlyphWidth:
; Internal-use version
; Input:
;  A: Codepoint
; Output:
;  A: Width
;  C if invalid codepoint,NC if valid
; Destroys:
;  DE
;  HL
; Subtract out firstGlyph
	ld	hl,_CurrentFontProperties.firstGlyph
	sub	a,(hl)
; Validate that the glyph index is actually valid
	jr	nc,.checkMaxIndex
.invalidIndex:
	xor	a,a
	scf
	ret
.checkMaxIndex:
	ld	hl,_CurrentFontProperties.totalGlyphs
	cp	a,(hl)
	jr	c,.invalidIndex
; Look up width
	or	a,a
	sbc	hl,hl
	ld	l,a
	ld	de,(_CurrentFontProperties.widthsTablePtr)
	add	hl,de
	ld	a,(hl)
	ret


;;-------------------------------------------------------------------------------
fontlib_GetStringWidth:
; Returns the width of a string.
; Stops when it encounters any control code or a codepoint not in the current
; font.
; Arguments:
;  arg0: Pointer to string
; Returns:
;  Width of string
	pop	bc
	ld	(.retter + 1),bc
	pop	de
	scf
	sbc	hl,hl
	push	hl
	push	de
	call	fontlib_GetStringWidthL
	pop	de
.retter:
	jp	0


;-------------------------------------------------------------------------------
fontlib_GetStringWidthL:
; Returns the width of a string.
; Stops when it encounters any control code or a codepoint not in the current
; font, or when it reaches the maximum number of characters to process.
; Arguments:
;  arg0: Pointer to string
;  arg1: Maximum number of characters to process
; Returns:
;  Width of string
	ld	hl,arg0
	add	hl,sp
	push	ix
	ld	ix,DataBaseAddr
	ld	bc,(hl)
	inc	hl
	inc	hl
	inc	hl
	ld	hl,(hl)
	ld	(ix + charactersLeft),hl
	ld	iy,0
	ld	de,(ix + strucFont.widthsTablePtr)
	ld	a,(bc)
	or	a,a
	jr	z,.exitFast
.loop:
; Check that we haven't exceeded our glyph printing limit
	ld	hl,(ix + charactersLeft)
	add	hl,bc
	or	a,a
	sbc	hl,bc
	jr	z,.exit
	dec	hl
	ld	(ix + charactersLeft),hl
; Fetch next item
	ld	a,(bc)
	cp	a,(ix + firstPrintableCodePoint)
	jr	c,.exit
	or	a,a
	jr	z,.exit
	cp	a,(ix + alternateStopCode)
	jr	z,.exit
	sub	a,(ix + strucFont.firstGlyph)
	jr	c,.exit
	cp	a,(ix + strucFont.totalGlyphs)
	jr	c,.validCodepoint
	ld	(ix + readCharacter),a
	ld	a,(ix + strucFont.totalGlyphs)
	or	a,a
	jr	nz,.exit
	ld	a,(ix + readCharacter)
.validCodepoint:
	inc	bc
	or	a,a
	sbc	hl,hl
	ld	l,a
	add	hl,de
	ld	a,(hl)
	sub	a,(ix + strucFont.italicSpaceAdjust) ; So if this results in a negative number
	sbc	hl,hl			; then this too will become negative,
	ld	l,a			; which gives the intended result, I guess
	ex	de,hl
	add	iy,de
	ex	de,hl
	jr	.loop
.exit:
	ld	a,(ix + strucFont.italicSpaceAdjust)
	neg
	jr	z,.exitFast
	ld	de,-1
	ld	e,a
	add	iy,de
.exitFast:
	ld	(ix + strReadPtr),bc
	lea	hl,iy + 0
	pop	ix
	ret


;-------------------------------------------------------------------------------
fontlib_GetLastCharacterRead:
; Returns the address of the last character printed by DrawString or processed
; by GetStrWidth.
; Arguments:
;  None
; Returns:
;  Pointer to last character read
	ld	hl,(_TextLastCharacterRead)
	ret


;-------------------------------------------------------------------------------
fontlib_GetCharactersRemaining:
; Allows you to figure out whether DrawStringL or GetStringWidthL returned due
; to having finished processed max_characters.
; Arguments:
;  None
; Returns:
;  Last internal value of tempCharactersLeft, taken from max_characters param
;  to GetStringWidth and DrawString.
	ld	hl,(tempCharactersLeft)
	ret


;-------------------------------------------------------------------------------
fontlib_ClearWindow:
; Erases the entire text window.
; Arguments:
;  None
; Returns:
;  Nothing
	ld	hl,(_TextX)
	push	hl
	ld	a,(_TextY)
	push	af
	ld	hl,(_TextXMax)
	ld	de,(_TextXMin)
	ld	(_TextX),de
	or	a,a
	sbc	hl,de
	ex	de,hl
	ld	a,(_TextYMin)
	ld	(_TextY),a
	ld	b,a
	ld	a,(_TextYMax)
	sub	a,b
	ld	b,a
	call	util.ClearRect
	pop	af
	ld	(_TextY),a
	pop	hl
	ld	(_TextX),hl
	ret


;-------------------------------------------------------------------------------
fontlib_SetNewlineOptions:
; Sets options for controlling newline behavior
; Arguments:
;  arg0: Flags for newline behavior
; Returns:
;  None
	ld	hl,arg0
	add	hl,sp
	ld	a,(hl)
	ld	(_TextNewlineControl),a
	ret


;-------------------------------------------------------------------------------
fontlib_GetNewlineOptions:
; Returns current newline flags
; Arguments:
;  None
; Returns:
;  Current newline flags
	ld	a,(_TextNewlineControl)
	ret


;-------------------------------------------------------------------------------
fontlib_Newline:
; Prints a newline, may trigger pre/post clear and scrolling
; Arguments:
;  None
; Returns:
;  A = 0 on success
;  A > 0 if the text window is full
	ld	iy,DataBaseAddr
	bit	bAutoClearToEOL,(iy + newlineControl)
; I hate how nearly every time I think CALL cc or RET cc would be useful
; it turns out I need to do other stuff that prevents me from using it.
	call	nz,fontlib_ClearEOL
	ld	iy,DataBaseAddr
	ld	hl,(iy + textXMin)
	ld	(iy + textX),hl
	ld	a,(iy + strucFont.height)
	add	a,(iy + strucFont.spaceAbove)
	add	a,(iy + strucFont.spaceBelow)
	ld	b,a
	add	a,a
	jr	c,.noScroll			; Carry = definitely went past YMax
	add	a,(iy + textY)			; And scrolling is not valid if height > 127
	jr	c,.outOfSpace
	cp	a,(iy + textYMax)
	jr	z,.writeCursorY
	jr	c,.writeCursorY
.outOfSpace:
	bit	bAutoScroll,(iy + newlineControl)
	jr	z,.noScroll
	call	fontlib_ScrollWindowDown
	ld	iy,DataBaseAddr			; Don't need to write textY---cursor
	jr	.checkPreClear			; didn't actually move!
.noScroll:
	ld	a,1
	bit	bEnableAutoWrap,(iy + newlineControl)
	ret	z
	ld	a,(iy + textYMin)
	ld	(iy + textY),a
	ld	a,1
	ret
.writeCursorY:
	sub	a,b
	ld	(iy + textY),a
.checkPreClear:
	xor	a
	bit	bPreclearNewline,(iy + newlineControl)
	ret	z
; Fall through to ClearEOL
assert $ = fontlib_ClearEOL


;-------------------------------------------------------------------------------
fontlib_ClearEOL:
; Erases everything from the cursor to the right side of the text window.
; Arguments:
;  None
; Returns:
;  A = 0
; Compute the rectangle size to clear
	ld	de,(_TextX)
	ld	hl,(_TextXMax)
	xor	a,a
	sbc	hl,de
	ret	c
	ret	z
	ex	de,hl
	ld	a,(_CurrentFontProperties.height)
	ld	hl,_CurrentFontProperties.spaceAbove
	add	a,(hl)
	inc	hl
	add	a,(hl)
	ld	b,a
; Fall through to ClearRect
assert $ = util.ClearRect


;-------------------------------------------------------------------------------
util.ClearRect:
; Internal routine that erases a rectangle at the current cursor location.
; Arguments:
;  B: Height
;  DE: Width
; Returns:
;  A = 0
; Destroys:
;  AF, BC, DE, HL, IY

; Check for trivial case
	ld	a,b
	or	a,a
	ret	z
	ld	a,e
	or	a,d
	ret	z
	dec	de
; Save width into IX for quick reloading during loop2
	push	ix
	ld	ix,0
	add	ix,de
	ld	c,b
; Compute write pointer
	ld	hl,(_TextY)
	ld	h,ti.lcdWidth / 2
	mlt	hl
	add	hl,hl
	ld	de,(_TextX)
	add	hl,de
	ld	iy,(CurrentBuffer)
	ex	de,hl
	add	iy,de
	lea	hl,iy + 0
; Do an initial first column
; This avoid some awkwardness with loop control and running out of registers
	ld	a,(_TextStraightBackgroundColor)
	ld	de,ti.lcdWidth
	call	gfx_Wait
.loop1:
	ld	(hl),a
	add	hl,de
	djnz	.loop1
; Check if doing just one column was enough
	ld	a,ixl
	or	a,ixh
	jr	z,.exit
; Main loop
	ld	a,c
.loop2:
	lea	bc,ix + 0
	lea	de,iy + 1
	lea	hl,iy + 0
	ldir
	ld	de,ti.lcdWidth
	add	iy,de
	dec	a
	jr	nz,.loop2
.exit:
	pop	ix
	ret


;-------------------------------------------------------------------------------
fontlib_ScrollWindowDown:
; Scrolls the contents of the text window down one line, i.e. everything in the
; window is copied UP one line, thus yielding the effect of scrolling down.
; The current text cursor is ignored.  The bottom line is not erased; you must
; erase or overwrite it yourself.
; Arguments:
;  None
; Returns:
;  A = 0
	ld	de,ti.lcdWidth
	call	.part1
; Compute write pointer
	ld	hl,(_TextYMin)
	call	.part2
; Compute read pointer as HL += ti.lcdWidth * CurrentFontHeight
	add	hl,bc
	add	hl,bc
.part3:
; Compute number of lines to copy as _TextYMax - _TextYMin - CurrentFontHeight
	ld	c,a
	ld	a,(_TextYMin)
	ld	b,a
	ld	a,(_TextYMax)
	sub	a,b
	ret	c
;	ret	z			; Implied by checking carry & zero flags below
	sub	a,c
	ret	c
	ret	z
	cp	c			; If window can't fit two full lines of text,
	ret	c			; then there's no point in scrolling
; Now copy some pixels
	call	gfx_Wait
.copy:	lea	bc,iy + 0
	ldir
	ld	bc,0			; SMC
.delta := $ - 3
	add	hl,bc			; Update read and write pointers
	ex	de,hl
	add	hl,bc
	ex	de,hl
	dec	a
	jr	nz,.copy
	ret

.part1:
; Get width loop control first
	call	fontlib_GetWindowWidth
	pop	bc
	ret	c
	ret	z
	push	bc
	push	hl
	pop	iy			; Stash it in IY for quick access
	ex	de,hl
	sbc	hl,de			; carry reset from above
	ld	(.delta),hl
; Now is a good time to call this internal routine
	jp	fontlib_GetCurrentFontHeight	; A has height

.part2:
	ld	h,ti.lcdWidth / 2
	mlt	hl
	add	hl,hl
	ld	de,(_TextXMin)
	add	hl,de
	ld	de,(CurrentBuffer)
	add	hl,de
; Copy HL to DE
	ex	de,hl
	sbc	hl,hl			; carry should be reset or else we're vomiting all over RAM
	add	hl,de
; Start computing read pointer
	ld	c,a
	ld	b,ti.lcdWidth / 2
	mlt	bc
	ret


;-------------------------------------------------------------------------------
fontlib_ScrollWindowUp:
; Scrolls the contents of the text window up one line, i.e. everything in the
; window is copied DOWN one line, thus yielding the effect of scrolling up.
; The current text cursor is ignored.  The top line is not erased; you must
; erase or overwrite it yourself.
; Arguments:
;  None
; Returns:
;  Nothing
	ld	de,-ti.lcdWidth
	call	fontlib_ScrollWindowDown.part1
; Compute write pointer
	ld	hl,(_TextYMax)
	dec	l
	call	fontlib_ScrollWindowDown.part2
; Compute read pointer as HL -= ti.lcdWidth * CurrentFontHeight
	sbc	hl,bc
	sbc	hl,bc
	jr	fontlib_ScrollWindowDown.part3


;-------------------------------------------------------------------------------
; Font Pack Support
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
util.GetFontPackData:
; Attempts to get a pointer to a font pack's data based on its appvar's name.
; Arguments:
;  HL: Pointer to name string
; Returns:
;  HL: Pointer to byte after "FONTPACK", or NULL on failure
;  DE: Pointer to start of "FONTPACK", or garbage on failure
;  Carry set if appvar not found, or not a font pack; NC on success
	dec	hl
	ld	iy,ti.flags
	call	ti.Mov9ToOP1
	ld	a,ti.AppVarObj
	ld	(ti.OP1),a
	call	ti.ChkFindSym
	jr	c,.error
	ex	de,hl
	ld	a,b
	cp	a,$D0
	jr	nc,.headerCheck
; Sadly, TI doesn't kindly provide us with a direct pointer; we have to account
; for the archive header ourselves.
	ld	de,9
	add	hl,de
	ld	e,(hl)
	inc	hl
	add	hl,de
.headerCheck:
; Check header
	inc	hl
	inc	hl
	push	hl
	call	util.VerifyHeader
	pop	de
	jr	nz,.error
	ret
.error:
	or	a,a
	sbc	hl,hl
	scf
	ret


;-------------------------------------------------------------------------------
util.VerifyHeader:
; Verify that HL points to something that looks somewhat like a font pack.
; Arguments:
;  HL: Pointer to supposed font pack
; Returns:
;  Z if the check passes, NZ if not
;  HL points to byte after 'K'
; Destroys:
;  A, B, DE
	ld	de,_FontPackHeaderString
	ld	b,8
.loop:	ld	a,(de)
	inc	de
	cp	(hl)
	inc	hl
	ret	nz
	djnz	.loop
	ret


;-------------------------------------------------------------------------------
fontlib_GetFontPackName:
; Returns a pointer to the font pack's name string.  Useful in a loop using
; ti_Detect().
; Arguments:
;  arg0: Pointer to font pack appvar name
; Returns:
;  Pointer, or NULL if no name
	ld	hl,arg0
	add	hl,sp
	ld	hl,(hl)
	call	util.GetFontPackData
	ret	c
; Check metadata offset field
	ld	bc,0
	ld	hl,(hl)
	sbc	hl,bc
	ret	z
; Check name field
	add	hl,de
	inc	hl
	inc	hl
	inc	hl
	ld	hl,(hl)
	sbc	hl,bc
	ret	z
	add	hl,de
	ret


;-------------------------------------------------------------------------------
fontlib_GetFontByIndex:
; Returns a pointer to a font in a font pack, based on an index.
; Arguments:
;  arg0: Pointer to font pack's name
;  arg1: Index
; Returns:
;  Pointer, or NULL if error
	ld	iy,0
	add	iy,sp
	ld	hl,(iy + arg0)
	push	iy
	call	util.GetFontPackData
	pop	iy
	ret	c
	ld	(iy + arg0),de
; Fall through to GetFontByIndexRaw
assert $ = fontlib_GetFontByIndexRaw


;-------------------------------------------------------------------------------
fontlib_GetFontByIndexRaw:
; Returns a pointer to a font in a font pack, based on an index.
; Arguments:
;  arg0: Pointer to first data byte of font pack
;  arg1: Index
; Returns:
;  Pointer, or NULL if error
	ld	iy,0
	add	iy,sp
	ld	hl,(iy + arg0)
; Get font count
	ld	de,strucFontPackHeader.fontCount
	add	hl,de
	ld	a,(hl)
	inc	hl
; Validate index
	ld	c, (iy + arg1)
	cp	c
	jr	c,.error
	jr	z,.error
; Get offset to font
	ld	b,3
	mlt	bc
	add	hl,bc
	ld	hl,(hl)
	ld	de,(iy + arg0)
	add	hl,de
	ret
.error:
	or	a
	sbc	hl,hl
	ret


;-------------------------------------------------------------------------------
fontlib_GetFontByStyle:
; Searches for a font in a font pack given a set of properties.
; Arguments:
;  arg0: Pointer to font pack's name
;  arg1: Minimum acceptable size
;  arg2: Maximum acceptable size
;  arg3: Minimum acceptable weight
;  arg4: Maximum acceptable weight
;  arg5: Style bits that must be set
;  arg6: Style bits that must be reset
; Returns:
;  Pointer, or NULL if error
	ld	iy,0
	add	iy,sp
	ld	hl,(iy + arg0)
	push	iy
	call	util.GetFontPackData
	pop	iy
	ret	c
	ld	(iy + arg0),de
; Fall through to fontlib_GetFontRaw
assert $ = fontlib_GetFontByStyleRaw


;-------------------------------------------------------------------------------
fontlib_GetFontByStyleRaw:
; Searches for a font in a font pack given a set of properties.
; Arguments:
;  arg0: Pointer to first data byte of font pack
;  arg1: Minimum acceptable size
;  arg2: Maximum acceptable size
;  arg3: Minimum acceptable weight
;  arg4: Maximum acceptable weight
;  arg5: Style bits that must be set
;  arg6: Style bits that must be reset
; Returns:
;  Pointer, or NULL if error
	ld	iy,0
	add	iy,sp
	push	ix
; Cache pointer to font pack start
	ld	de,(iy + arg0)
	or	a,a
	sbc	hl,hl
	add	hl,de
; Get pointer to fonts table
	ld	bc,strucFontPackHeader.fontCount
	add	hl,bc
	ld	b,(hl)
	inc	hl
.checkLoop:
	ld	ix,(hl)
	add	ix,de
	call	.checkStyle
	jr	c,.goodFont
	inc	hl
	inc	hl
	inc	hl
	djnz	.checkLoop
	sbc	hl,hl		; Carry must be reset from above
	jr	.badFont
.goodFont:
	lea	hl,ix + 0
.badFont:
	pop	ix
	ret
.checkStyle:
	ld	a,(ix + strucFont.height)
	cp	(iy + arg1)
	ccf
	ret	nc
	cp	(iy + arg2)
	jr	z,.sizeOK
	ret	nc
.sizeOK:
	ld	a,(ix + strucFont.weight)
	cp	(iy + arg3)
	ccf
	ret	nc
	cp	(iy + arg4)
	jr	z,.weightOK
	ret	nc
.weightOK:
; TODO: I think the CP here might sometimes SET carry when it shouldn't be?
	ld	a,(ix + strucFont.style)
	ld	c,(iy + arg5)
	and	a,c
	cp	a,c
	ret	nz
	ld	a,(ix + strucFont.style)
	ld	c,(iy + arg6)
	and	a,c
	xor	a,c
	cp	a,c
	ret	nz
	scf
	ret


;-------------------------------------------------------------------------------
; Data
_FontPackHeaderString:
	db	"FONTPACK"
_TextDefaultWindow:
textDefaultWindow := _TextDefaultWindow - DataBaseAddr
	dl	0
	db	0
	dl	ti.lcdWidth
	db	ti.lcdHeight
_TextXMin:
textXMin := _TextXMin - DataBaseAddr
	dl	0
_TextYMin:
textYMin := _TextYMin - DataBaseAddr
	db	0
_TextXMax:
textXMax := _TextXMax - DataBaseAddr
	dl	ti.lcdWidth
_TextYMax:
textYMax := _TextYMax - DataBaseAddr
	db	ti.lcdHeight
_TextX:
textX := _TextX - DataBaseAddr
	dl	0
_TextY:
textY := _TextY - DataBaseAddr
	db	0
_TextTransparentMode:
textTransparentMode := _TextTransparentMode - DataBaseAddr
	db	0
_TextNewlineControl:
newlineControl := _TextNewlineControl - DataBaseAddr
	db	mEnableAutoWrap or mAutoClearToEOL
_TextLastCharacterRead:
strReadPtr := _TextLastCharacterRead - DataBaseAddr
	dl	0
tempCharactersLeft:
charactersLeft := tempCharactersLeft - DataBaseAddr
	dl	0
_TextAlternateStopCode:
alternateStopCode := _TextAlternateStopCode - DataBaseAddr
	db	0
_TextFirstPrintableCodePoint:
firstPrintableCodePoint := _TextFirstPrintableCodePoint - DataBaseAddr
	db	chFirstPrintingCode
_TextNewLineCode:
newLineCode := _TextNewLineCode - DataBaseAddr
	db	chNewline
tempRandom:
readCharacter := tempRandom - DataBaseAddr
	db	0
_CurrentFontRoot:
currentFontRoot := _CurrentFontRoot - DataBaseAddr
	dl	0
DataBaseAddr:
; Embed the current font's properties as library variables
_CurrentFontProperties strucFont

