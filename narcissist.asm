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

.const   address_border_color = $D020
.const   address_screen_color = $D021

.const   constant_font_bank = 2
.const   address_font = $0000 + ($800 * constant_font_bank) // = $1000

//.const   address_font_pointer = $D018
//.const   address_font_character_lo_byte = $0A
//.const   address_font_character_hi_byte = $0B

//.const   address_sid_music_init = $1000
//.const   address_sid_music_play = address_sid_music_init + 3

.const   raster_position_irq1 = $10
.const   raster_position_irq2 = $E0


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
        // Set bitmap mode
        // Set multicolor mode
        // Using VIC bank 0
        // Bitmap memory at $2000-$3FFF
        // Screen memory at $0C00

        jsr rasterline_start

        #if SCROLL

        SetTextMode()
        SetSingleColorMode()
        TextMode_SetFontBank2_VicRelative_1000_17FF()

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
rasterline_start:
        SetBorderColor(COLOR_BLUE)
        SetBackgroundColor(COLOR_BLUE)
        rts

rasterline_end:
        SetBorderColor(COLOR_WHITE)
        SetBackgroundColor(COLOR_WHITE)
        rts

*=$0c00 "screen ram"; .fill picture.getScreenRamSize(), picture.getScreenRam(i)
*=$4000 "color ram"; colorRam: .fill picture.getColorRamSize(), picture.getColorRam(i) // (1024b) Later copied to static ram location for color $D800 - $DBFF
*=$2000 "picture bitmap"; .fill picture.getBitmapSize(), picture.getBitmap(i)

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
