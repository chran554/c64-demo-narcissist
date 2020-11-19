//#define INCLUDE_MUSIC
#undef INCLUDE_MUSIC
#define SCROLL
//#undef SCROLL
#define RASTER_BORDER
#define RASTER_SCREEN

#if SCROLL
.print "Including scroll"
#else
.print "Excluding scroll"
#endif

#if INCLUDE_MUSIC
.print "Including music"
#else
.print "Excluding music"
#endif

#if RASTER_BORDER || RASTER_SCREEN
.print "DEBUG Using raster markers:"
#if RASTER_BORDER
.print "    * border"
#endif
#if RASTER_SCREEN
.print "    * screen"
#endif
#endif

#import "macros.asm"

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

.const address_border_color = $D020
.const address_screen_color = $D021

.const constant_font_bank = 3
.const address_font = $0000 + ($800 * constant_font_bank) // = $1000

//.const address_font_pointer = $D018
//.const address_font_character_lo_byte = $0A
//.const address_font_character_hi_byte = $0B

//.const address_sid_music_init = $1000
//.const address_sid_music_play = address_sid_music_init + 3

.const constant_columns_per_line = 40
.const constant_static_text_line_index = 24
.const screen_memory_address = $0C00 // Screen memory start (in text mode)

.const raster_position_irq1 = $10
.const raster_position_irq2 = $EA


 *=$0801 "basic start program"

 BasicUpstart($0810)

 *=$0810 "program"

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

        //lda $D01A       // enable VIC-II Raster Beam IRQ
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
        // Used to setup display of ego-image
        jsr rasterline_start

        SetVicBank0_0000_3FFF()                             // Using VIC bank 0
        SetMultiColorMode()                                 // Set multicolor mode
        SetBitmapMode()                                     // Set bitmap mode
        BitmapMode_SetBitmapMemoryVicRelative_2000_3FFF()   // Bitmap memory at $2000-$3FFF
        BitmapMode_SetScreenMemoryVicRelative_0C00_0FFF()   // Screen memory at $0C00

        SetBorderColor(COLOR_WHITE)
        SetBackgroundColor(picture.getBackgroundColor())

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
        // Used to: play music, set text mode
        // Using VIC bank 0
        // Set text mode
        // Set single color mode
        // Bitmap memory at $2000-$3FFF
        // Screen memory at $0C00

        jsr rasterline_start

        #if SCROLL

        SetVicBank0_0000_3FFF()
        SetTextMode()
        TextMode_Set25RowMode()
        SetSingleColorMode()
        TextMode_SetFontBank3_VicRelative_1800_1FFF()

        jsr printText

        #endif

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
#if RASTER_BORDER || RASTER_SCREEN
rasterline_start:
#if RASTER_BORDER
        SetBorderColor(COLOR_BLUE)
#endif
#if RASTER_SCREEN
        SetBackgroundColor(COLOR_BLUE)
#endif
        rts

rasterline_end:
#if RASTER_BORDER
        SetBorderColor(COLOR_WHITE)
#endif
#if RASTER_SCREEN
        SetBackgroundColor(COLOR_WHITE)
#endif
        rts
#endif

#if SCROLL
printText:
        ldx #$00
!:
        lda static_message_text, x
        cmp #$00  // Have we encountered text message null termination
        beq !+

        ora #%10000000 // Invert text message character
        sta screen_memory_address + constant_columns_per_line * constant_static_text_line_index , x // print static message text data to screen character location

        lda #COLOR_RED
        sta $d800 + constant_columns_per_line * constant_static_text_line_index , x // print static message text data to screen character location

        inx
        cpx #$00 // Copy max 255 characters to screen (if register x is wrapped back to 0)
        bne !-
!:
        rts
#endif

#if SCROLL
.memblock "static message text"
static_message_text:
    .encoding "screencode_mixed"
    .text @"this is a test text"
    //.text @" but rather a mimics the looks and operation of a 8*40 LED matrix panel that you can see"
    //.text @" in the window of your favourite pizza place."
    .byte $00 // Scroll message text is null terminated
#endif

*=$0c00 "screen ram"; screenRam: .fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$4000 "color ram"; colorRam: .fill picture.getColorRamSize(), picture.getColorRam(i) // (1024b) Later copied to static ram location for color $D800 - $DBFF
*=$2000 "picture bitmap"; pictureBitmap: .fill picture.getBitmapSize(), picture.getBitmap(i)

#if INCLUDE_MUSIC
*=music.location "music"; .fill music.size, music.getData(i)
#endif

#if SCROLL
// ---------------------------------------------
// Text font
// ---------------------------------------------
// More fonts at http://kofler.dot.at/c64/
// Load font to last 2k block of bank 3
* = address_font "font"
    .import binary "fonts/Giana sisters demo font 03-charset.bin"
//    !bin "fonts/giana_sisters.font.64c",,2
//    !bin "fonts/devils_collection_25_y.64c",,2
//    !bin "fonts/double_char_font.bin"
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
.print "location        = $" + toHexString(music.location)
.print "init            = $" + toHexString(music.init)
.print "play            = $" + toHexString(music.play)
.print "songs           = " + music.songs
.print "startSong       = " + music.startSong
.print "size            = $" + toHexString(music.size)
.print "name            = " + music.name
.print "author          = " + music.author
.print "copyright       = " + music.copyright
.print ""
.print "Additional SID tech data"
.print "------------------------"
.print "header          = " + music.header
.print "header version  = " + music.version
.print "flags           = " + toBinaryString(music.flags)
.print "speed           = " + toBinaryString(music.speed)
.print "startpage       = " + music.startpage
.print "pagelength      = " + music.pagelength
#endif
