#importonce

.const COLOR_BLACK         = $00
.const COLOR_WHITE         = $01
.const COLOR_RED           = $02
.const COLOR_CYAN          = $03
.const COLOR_PURPLE        = $04
.const COLOR_GREEN         = $05
.const COLOR_BLUE          = $06
.const COLOR_YELLOW        = $07
.const COLOR_ORANGE        = $08
.const COLOR_BROWN         = $09
.const COLOR_PINK          = $0A
.const COLOR_DARK_GREY     = $0B
.const COLOR_GREY          = $0C
.const COLOR_LIGHT_GREEN   = $0D
.const COLOR_LIGHT_BLUE    = $0E
.const COLOR_LIGHT_GREY    = $0F

// Address $D018 coding scheme
// During text mode (see $D011 bit 5):
// Bit 1-3: Pointer to character memory (adresses are offsets relative to VIC bank start):
// .const character_bank_0 = %000 // Character bank 0 address: $0000-$07FF
// .const character_bank_1 = %001 // Character bank 1 address: $0800-$0FFF
// .const character_bank_2 = %010 // Character bank 2 address: $1000-$17FF
// .const character_bank_3 = %011 // Character bank 3 address: $1800-$1FFF
// .const character_bank_4 = %100 // Character bank 4 address: $2000-$27FF
// .const character_bank_5 = %101 // Character bank 5 address: $2800-$2FFF
// .const character_bank_6 = %110 // Character bank 6 address: $3000-$37FF
// .const character_bank_7 = %111 // Character bank 7 address: $3800-$3FFF
// Character bank values #2 (%010) and #3 (%011) while in VIC bank #0 or #2 select Character ROM instead.

// Address $DD00 coding scheme:
// Bit 0-1: Select VIC bank (each bank block is $4000 bytes)
// Value %xxxx xx11 gives Bank 0
// Value %xxxx xx10 gives Bank 1
// Value %xxxx xx01 gives Bank 2
// Value %xxxx xx00 gives Bank 3
// Start address of bank is given by: <bank number> * $4000   (thus bank 2 start at address 2 * $4000 = $8000)
// .const bank0 = %11 // Address: $0000 - $3FFF
// .const bank1 = %10 // Address: $4000 - $7FFF
// .const bank2 = %01 // Address: $8000 - $BFFF
// .const bank3 = %00 // Address: $C000 - $FFFF
// Default(?): $97, %1001 0111

// Address $D016 coding scheme:
// Bit 0-2: "Horizontal raster scroll (value 0-7, default 0)"
// Bit 3:   "40-col mode"
// Bit 4:   "Multicolor mode"
// Bit 5-7: ?
// Default: $C8, %1100 1000

// Address $D011 coding scheme:
// Bit 0-2: "Vertical raster scroll (value 0-7)"
// Bit 3:   "24/25-row mode"
// Bit 4:   "screen off/on"
// Bit 5:   "Text/Bitmap mode"
// Bit 6:   "Extended background mode off/on"
// Bit 7:   Read: Current raster line (bit #8). Write: Raster line to generate interrupt at (bit #8)
// Default: $1B, %0001 1011.

// Address $DD02 coding scheme:
// Each bit disable or enable write access to VIC port "A". I.e. the address $DD00.
// lda $dd02      // Load value of VIC port "A" data direction register
// ora #%00000011 // Enable both read and write on bit 0-1 on VIC port "A" ($DD00), the "VIC bank selection bits"
// Default: $3F, %0111 1111

.macro SetBorderColor(color) {
    lda #color
    sta $d020
}

.macro SetBackgroundColor(color) {
    lda #color
    sta $d021
}

.macro EnableVicBankWrite() {
    // Default value is: write enabled
    lda $dd02
    ora #%00000011 // Enable both read and write on bit 0-1 on VIC port "A" ($DD00), the "VIC bank selection bits"
    sta $dd02
}

.macro SetVicBank0_0000_3FFF() {
    // Default VIC bank
    EnableVicBankWrite()

    lda $dd00
    and #%11111100 // Reset bit 0-1 (to 0)
    ora #%00000011 // VIC bank 0
    sta $dd00
}

.macro SetVicBank1_4000_7FFF() {
    // Not default VIC bank (bank 0 is default)
    EnableVicBankWrite()

    lda $dd00
    and #%11111100 // Reset bit 0-1 (to 0)
    ora #%00000010 // VIC bank 1
    sta $dd00
}

.macro SetVicBank2_8000_BFFF() {
    // Not default VIC bank (bank 0 is default)
    EnableVicBankWrite()

    lda $dd00
    and #%11111100 // Reset bit 0-1 (to 0)
    ora #%00000001 // VIC bank 2
    sta $dd00
}

.macro SetVicBank3_C000_FFFF() {
    // Not default VIC bank (bank 0 is default)
    EnableVicBankWrite()

    lda $dd00
    and #%11111100 // Reset bit 0-1 (to 0)
    ora #%00000000 // VIC bank 3
    sta $dd00
}

.macro SetSingleColorMode() {
    // Default color mode
    lda $d016
    and #%11101111 // Set bit 4 low
    sta $d016
}

.macro SetMultiColorMode() {
    // Not default color mode (single color mode is default)
    lda $d016
    ora #%00010000 // Set bit 4 high
    sta $d016
}

.macro SetTextMode() {
    // Default presentation mode
    lda $d011
    and #%11011111 // Set bit 5 low
    sta $d011
}

.macro TextMode_Set40ColumnMode() {
    // Default column mode during text mode
    lda $d016
    ora #%00001000 // Set bit 3 high
    sta $d016
}

.macro TextMode_Set38ColumnMode() {
    // Not default column mode during text mode (40 column mode is default)
    lda $d016
    and #%11110111 // Set bit 3 low
    sta $d016
}

.macro TextMode_Set25RowMode() {
    // Default row mode during text mode
    lda $d011
    ora #%00001000 // Set bit 3 high
    sta $d011
}

.macro TextMode_Set24RowMode() {
    // Not default row mode during text mode (25 row mode is default)
    lda $d011
    and #%11110111 // Set bit 3 low
    sta $d011
}

.macro TextMode_SetFontBank0_VicRelative_0000_07FF() {
    lda $d018
    and #%11110001
    ora #%00000000 // Set bit 1-3 to 0 = %000
    sta $d018
}

.macro TextMode_SetFontBank1_VicRelative_0800_0FFF() {
    lda $d018
    and #%11110001
    ora #%00000010 // Set bit 1-3 to 1 = %001
    sta $d018
}

.macro TextMode_SetFontBank2_VicRelative_1000_17FF() {
    // Character bank values #2 (%010) and #3 (%011) while in VIC bank #0 or #2 select Character ROM instead.
    lda $d018
    and #%11110001
    ora #%00000100 // Set bit 1-3 to 2 = %010
    sta $d018
}

.macro TextMode_SetFontBank3_VicRelative_1800_1FFF() {
    // Character bank values #2 (%010) and #3 (%011) while in VIC bank #0 or #2 select Character ROM instead.
    lda $d018
    and #%11110001
    ora #%00000110 // Set bit 1-3 to 3 = %011
    sta $d018
}

.macro TextMode_SetFontBank4_VicRelative_2000_27FF() {
    lda $d018
    and #%11110001
    ora #%00001000 // Set bit 1-3 to 4 = %100
    sta $d018
}

.macro TextMode_SetFontBank5_VicRelative_2800_2FFF() {
    lda $d018
    and #%11110001
    ora #%00001010 // Set bit 1-3 to 5 = %101
    sta $d018
}

.macro TextMode_SetFontBank6_VicRelative_3000_37FF() {
    lda $d018
    and #%11110001
    ora #%00001100 // Set bit 1-3 to 6 = %110
    sta $d018
}

.macro TextMode_SetFontBank7_VicRelative_3800_3FFF() {
    lda $d018
    and #%11110001
    ora #%00001110 // Set bit 1-3 to 7 = %111
    sta $d018
}

.macro SetBitmapMode() {
    // Not default presentation mode (text mode is default)
    lda $d011
    ora #%00100000 // Set bit 5 high
    sta $d011
}

.macro BitmapMode_SetBitmapMemoryVicRelative_0000_1FFF() {
    lda $d018
    and #%11110111 // Set bit 3 low
    sta $d018
}

.macro BitmapMode_SetBitmapMemoryVicRelative_2000_3FFF() {
    lda $d018
    ora #%00001000 // Set bit 3 high
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_0000_03FF() {
    lda $d018
    and #%00001111
    ora #%00000000 // Set bit 4-7 to 0=%000
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_0400_07FF() {
    lda $d018
    and #%00001111
    ora #%00010000 // Set bit 4-7 to 1 = %0001
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_0800_0BFF() {
    lda $d018
    and #%00001111
    ora #%00100000 // Set bit 4-7 to 2 = %0010
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_0C00_0FFF() {
    lda $d018
    and #%00001111
    ora #%00110000 // Set bit 4-7 to 3 = %0011
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_1000_13FF() {
    lda $d018
    and #%00001111
    ora #%01000000 // Set bit 4-7 to 4 = %0100
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_1400_17FF() {
    lda $d018
    and #%00001111
    ora #%01010000 // Set bit 4-7 to 5 = %0101
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_1800_1BFF() {
    lda $d018
    and #%00001111
    ora #%01100000 // Set bit 4-7 to 6 = %0110
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_1C00_1FFF() {
    lda $d018
    and #%00001111
    ora #%01110000 // Set bit 4-7 to 7 = %0111
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_2000_23FF() {
    lda $d018
    and #%00001111
    ora #%10000000 // Set bit 4-7 to 8 = %1000
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_2400_27FF() {
    lda $d018
    and #%00001111
    ora #%10010000 // Set bit 4-7 to 9 = %1001
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_2800_2BFF() {
    lda $d018
    and #%00001111
    ora #%10100000 // Set bit 4-7 to 10 = %1010
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_2C00_2FFF() {
    lda $d018
    and #%00001111
    ora #%10110000 // Set bit 4-7 to 11 = %1011
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_3000_33FF() {
    lda $d018
    and #%00001111
    ora #%11000000 // Set bit 4-7 to 12 = %1100
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_3400_37FF() {
    lda $d018
    and #%00001111
    ora #%11010000 // Set bit 4-7 to 13 = %1101
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_3800_3BFF() {
    lda $d018
    and #%00001111
    ora #%11100000 // Set bit 4-7 to 14 = %1110
    sta $d018
}

.macro BitmapMode_SetScreenMemoryVicRelative_3C00_3FFF() {
    lda $d018
    and #%00001111
    ora #%11110000 // Set bit 4-7 to 15 = %1111
    sta $d018
}

/**
 * Pauses for an amount of cycles.
 * The pause is implemented by linear consecutive NOP operations (and a BIT operation if amount cycles is odd).
 * @param The amount of cycles to pause. Amount cycles must be >= 2.
 */
.pseudocommand pause cycles {
	:ensureImmediateArgument(cycles)
	.var x = floor(cycles.getValue())
	.if (x<2) .error "Cant make a pause on " + x + " cycles"

	// Take care of odd cyclecount
	.if ([x&1]==1) {
		bit $00
		.eval x=x-3
	}

	// Take care of the rest
	.if (x>0)
		:nop #x/2
}

/**
 * Pauses for an amount of cycles.
 * The pause is implemented by operations of a loop + some extra for rest values.
 * Uses Y register.
 * @param The amount of cycles to pause. Amount cycles must be >= 2.
 */
.pseudocommand pause2 cycles {
	:ensureImmediateArgument(cycles)
	.var x = floor(cycles.getValue())
	.if (x<2) .error "Cant make a pause on " + x + " cycles"

	// Make a delay loop
	.if (x>=11) {
		.const cfirst = 6	// cycles for first loop
		.const cextra = 5	// cycles for extra loops
		.var noOfLoops = 1+floor([x-cfirst]/cextra)
		.eval x = x - cfirst - [noOfLoops-1]*cextra
		.if (x==1){
			.eval x=x+cextra
			.eval noOfLoops--
		}
		ldy #noOfLoops
		dey
		bne *-1
	}

	// Take care of odd cycle count
	.if ([x&1]==1) {
		bit $00
		.eval x=x-3
	}

	// Take care of the rest
	.if (x>0)
		:nop #x/2
}

//---------------------------------
// repetition commands
//---------------------------------
.macro ensureImmediateArgument(arg) {
	.if (arg.getType()!=AT_IMMEDIATE)	.error "The argument must be immediate!"
}
.pseudocommand asl x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) asl
}
.pseudocommand lsr x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) lsr
}
.pseudocommand rol x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) rol
}
.pseudocommand ror x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) ror
}

.pseudocommand pla x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) pla
}

.pseudocommand nop x {
	:ensureImmediateArgument(x)
	.for (var i=0; i<x.getValue(); i++) nop
}