//#define INCLUDE_MUSIC
#undef INCLUDE_MUSIC

#if INCLUDE_MUSIC
.print "Including music"
#else
.print "Excluding music"
#endif

.const KOALA_TEMPLATE = "C64FILE, Bitmap=$0000, ScreenRam=$1f40, ColorRam=$2328, BackgroundColor = $2710"
//.var picture = LoadBinary("koala/me.kla", KOALA_TEMPLATE)
.var picture = LoadBinary("koala/me7.kla", KOALA_TEMPLATE)

#if INCLUDE_MUSIC
.var music = LoadSid("sid/Delta_relocated_$5000.sid") //.var music = LoadSid("sid/Delta.sid")
#endif

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

.const SYSTEM_IRQ_HANDLER = $ea81

.const   address_border_color = $D020
.const   address_screen_color = $D021

.const   constant_font_bank = $0e
.const   address_font = $3800
.const   address_font_pointer = $D018
.const   address_font_character_lo_byte = $0A
.const   address_font_character_hi_byte = $0B

.const   address_sid_music_init = $1000
.const   address_sid_music_play = address_sid_music_init + 3

.const   raster_position_irq1 = $10
.const   raster_position_irq2 = $FF


 *=$0801 "Basic Program"

 BasicUpstart($0810)

 *=$0810 "Program"

Init:
        #if INCLUDE_MUSIC
        // Init music
        ldx #0
        ldy #0
        lda #music.startSong - 1
        jsr music.init
        #endif

        sei
        lda #%01111111
        sta $DC0D	      // "Switch off" interrupts signals from CIA-1

        //lda $D01A      // enable VIC-II Raster Beam IRQ
        //ora #$01
        //sta $D01A

        lda #%00000001
        sta $D01A	      // Enable raster interrupt signals from VIC

        lda $D011
        and #%01111111
        sta $D011	      // Clear most significant bit in VIC's raster register (for raster interrupt on upper part of screen, above line #256)

        lda #raster_position_irq1    // Interrupt on this raster line
        sta $D012                    // Set the raster line number where interrupt should occur

        // Copy picture color data to color ram location at $D800
        ldx #0
        !loop:
        .for (var i=0; i<4; i++) {
             lda colorRam + i*$100, x
             sta $d800 + i*$100, x
        }
        inx
        bne !loop-

        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315	      // Set the interrupt vector to point to interrupt service routine below

        cli

        //rts              // Initialization done// return to BASIC
no_exit:
        jmp no_exit


irq1:
        jsr rasterline_start

        // Address $DD02 coding scheme:
        // Each bit disable or enable write access to VIC port "A". I.e. the address $DD00.
        lda $dd02 // Load value of VIC port "A" data direction register
        ora #%00000011 // Enable both read and write on bit 0-1 on VIC port "A" ($DD00), the "VIC bank selection bits"
        sta $dd02

        // Address $DD00 coding scheme:
        // Bit 0-1: Select VIC bank (each bank block is $4000 bytes)
        // Value %xxxx xx11 gives Bank 0
        // Value %xxxx xx10 gives Bank 1
        // Value %xxxx xx01 gives Bank 2
        // Value %xxxx xx00 gives Bank 3
        // Start address of bank is given by: <bank number> * $4000   (thus bank 2 start at address 2 * $4000 = $8000)
        // Default(?):
        .const VIC_bank_0 = %11 // Adress: $0000 - $3FFF
        .const VIC_bank_1 = %10 // Adress: $4000 - $7FFF
        .const VIC_bank_2 = %01 // Adress: $8000 - $BFFF
        .const VIC_bank_3 = %00 // Adress: $C000 - $FFFF
        lda $dd00
        and #%11111100 // Reset bit 0-1 (to 0)
        ora #VIC_bank_0
        sta $dd00

        // Address $D018 coding scheme (during bitmap mode, see $D011 bit 5):
        // Bit 0-1: "Unused" during bitmap mode
        // Bit 3: Relative pointer to bitmap memory: $0000-$1FFF / $2000-$3FFF. Relative to VIC bank start (see $DD00).
        // Bit 4-7: Relative pointer to screen memory: <bit value> * $400. Relative to VIC bank start (see $DD00).
        // Default: $C8, %1100 1000
        lda #$38 // %0011 1000 // bitmap memory at VIC bank start + $2000-$3FFF, screen memory at VIC bank start + (3 * $400 = $C00)
        sta $d018

        // Address $D016 coding scheme:
        // Bit 0-2: "Horizontal raster scroll (value 0-7)"
        // Bit 3: "40-col mode"
        // Bit 4: "Multicolor mode"
        // Bit 5-7:
        // Default: $C8, %1100 1000
        lda #$d8 // %1101 1000 // scroll=0, 40 columns, multi color mode
        sta $d016

        // Address $D011 coding scheme:
        // Bit 0-2: "Vertical raster scroll (value 0-7)"
        // Bit 3: "24/25-row mode"
        // Bit 4: "screen off/on"
        // Bit 5: "Text/Bitmap mode"
        // Bit 6: "Extended background mode off/on"
        // Bit 7: Read: Current raster line (bit #8). Write: Raster line to generate interrupt at (bit #8)
        // Default: $1B, %0001 1011.
        lda #$3b // %0011 1011 // scroll=3, 25 rows, screen on, bitmap mode
        sta $d011

        lda #COLOR_WHITE
        sta $d020 // Border color
        lda #picture.getBackgroundColor()
        sta $d021 // Background color

        jsr rasterline_end

        // Set next raster interrupt (raster interrupt irq2)
        lda #<irq2
        sta $0314
        lda #>irq2
        sta $0315

        lda #raster_position_irq2 // Create raster interrupt at line
        sta $d012

        asl $D019	      // "Acknowledge" (asl do both read and write to memory location) the interrupt by clearing the VIC's interrupt flag.
        //jmp $EA31	      // Jump into KERNAL's standard interrupt service routine to handle keyboard scan, cursor display etc.
        jmp SYSTEM_IRQ_HANDLER
        //!loop:
        //jmp !loop-

irq2:
        jsr rasterline_start
        #if INCLUDE_MUSIC
        jsr music.play
        #endif
        jsr rasterline_end

        // Set next raster interrupt (back to raster interrupt irq1)
        lda #<irq1
        sta $0314
        lda #>irq1
        sta $0315

        lda #raster_position_irq1         // Interrupt on this raster line
        sta $D012                         // Set the raster line number where interrupt should occur

        asl $D019	      // "Acknowledge" (asl do both read and write to memory location) the interrupt by clearing the VIC's interrupt flag.
        jmp $EA31	      // Jump into KERNAL's standard interrupt service routine to handle keyboard scan, cursor display etc.
        //jmp SYSTEM_IRQ_HANDLER
        //rti

// ---------------------------------------------
// Paint a raster band
// ---------------------------------------------
rasterline_start:
        // rasterline start paint
        lda #COLOR_BLUE
        sta address_border_color	      // Set screen border color to yellow
        //sta address_screen_color	      // Set screen color to yellow

        rts

rasterline_end:
        // rasterline stop paint
        lda #COLOR_WHITE
        sta address_border_color	      // Set screen border color to black
        //sta address_screen_color	      // Set screen color to black

        rts

*=$0c00 "screen ram"; .fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$4000 "color ram"; colorRam: .fill picture.getColorRamSize(), picture.getColorRam(i) // (1024b) Later copied to static ram location for color $D800 - $DBFF
*=$2000 "picture bitmap"; .fill picture.getBitmapSize(), picture.getBitmap(i)

#if INCLUDE_MUSIC
*=music.location "music"; .fill music.size, music.getData(i)
#endif



//----------------------------------------------------------
// Print the music info while assembling
.print ""
.print "Picture Data"
.print "------------"
.print "Screen Ram Size  = " + picture.getScreenRamSize() + " bytes"
.print "Color  Ram Size  = " + picture.getColorRamSize() + " bytes"
.print "Bitmap Size      = " + picture.getBitmapSize() + " bytes"
.print "Background color = $" + toHexString(picture.getBackgroundColor())

#if INCLUDE_MUSIC
.print ""
.print ""

.print "SID Data"
.print "--------"
.print "location  = $" + toHexString(music.location)
.print "init      = $" + toHexString(music.init)
.print "play      = $" + toHexString(music.play)
.print "songs     = " + music.songs
.print "startSong = " + music.startSong
.print "size      = $" + toHexString(music.size)
.print "name      = " + music.name
.print "author    = " + music.author
.print "copyright = " + music.copyright
.print ""
.print "Additional SID tech data"
.print "------------------------"
.print "header         = " + music.header
.print "header version = " + music.version
.print "flags          = " + toBinaryString(music.flags)
.print "speed          = " + toBinaryString(music.speed)
.print "startpage      = " + music.startpage
.print "pagelength     = " + music.pagelength
#endif
