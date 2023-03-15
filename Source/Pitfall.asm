;-------------------------------------------------------------------------
; Pitfall
;-------------------------------------------------------------------------
; BBC Conversion Shaun Lindsley
; (c) 2022/2023
; Thanks to the following: -
; ChrisB, Kieranhj, Lovebug, oss003, Rich Talbot-Watkins
; TobyLobster, Tricky 
; and the rest of the Stardot community https://stardot.org.uk
;
; beebasm -v -i Pitfall.asm -do Pitfall.ssd -opt 3

; Use following for vsync debugging
; LDA #&00: STA &FE21 ;white
; LDA #&01: STA &FE21 ;cyan
; LDA #&02: STA &FE21 ;magenta
; LDA #&03: STA &FE21 ;blue
; LDA #&04: STA &FE21 ;yellow
; LDA #&05: STA &FE21 ;green
; LDA #&06: STA &FE21 ;red
; LDA #&07: STA &FE21 ;black

NATIVE_ADDR = &0100 ; address at which code will relocate to
RELOAD_ADDR = &1100 ; address at which code will load

OFFSET      = RELOAD_ADDR - NATIVE_ADDR

INCLUDE "Constants.asm"

; Define some zp locations
ORG 0
GUARD irq_A_save
.fx0                    SKIP 1 ; Machine
.vsyncCnt               SKIP 1
.frameCnt               SKIP 1

.saveA                  SKIP 1 ; Faster than PHA : PLA
.saveX                  SKIP 1 ; Faster than TXA : PHA : PLA : TAX
.saveY                  SKIP 1 ; Faster than TYA : PHA : PLA : TAY

; player input flags, bit 0=up 1=down 2=left 3=right 4=start
.playerInput            SKIP 1
.player_x               SKIP 1
.player_y               SKIP 1
.player_x2              SKIP 1  ; Used for collision box testing
.player_y2              SKIP 1  ; Used for collision box testing
.player_dx              SKIP 1
.player_dy              SKIP 1
.player_direction       SKIP 1
.player_animation_frame SKIP 1
.player_jump_index      SKIP 1
.playerCurrentSprite    SKIP 1
.player_movement        SKIP 1

.eraseCharacter         SKIP 1  ; Mask Erase Sprite character
.currentCharacter       SKIP 1
.currentXPosition       SKIP 1
.currentYPosition       SKIP 1

.sceneType              SKIP 1
.treePat                SKIP 1
.objectType             SKIP 1
.ladderFlag             SKIP 1

.xPosObject             SKIP 1
.objectFrameRate        SKIP 1
.objectSprite           SKIP 1
.objectControl          SKIP 1
.object_x               SKIP 1
.object_y               SKIP 1
.object_distance        SKIP 1
.object_counter         SKIP 1

.object_logs_x          SKIP 4  ; Max 3 logs?

.xPosScorpion           SKIP 1
.scorpionControl        SKIP 1
.scorpion_x             SKIP 1
.scorpionSprite         SKIP 1

.xPosQuickSand          SKIP 1
.swampFlag              SKIP 1
.quickSandFlag          SKIP 1
.swampFrame             SKIP 1
.quickSandAnimateFlag   SKIP 1
.quickSandFrame         SKIP 1

.crocodileFlag          SKIP 1
.crocodileControl       SKIP 1
.crocodile_x            SKIP 1
.crocodileFrameRate     SKIP 1
.crocodileSprite        SKIP 1

.chrFontColour          SKIP 1
.chrFontAddr            SKIP 2 ; (&FFFF)

.random                 SKIP 1
.random2                SKIP 1

.XOrd                   SKIP 1
.YOrd                   SKIP 1
.YOrd2                  SKIP 1

.write_addr             SKIP 2
.temp_addr              SKIP 2
.text_addr              SKIP 1

.width                  SKIP 1 ; Sprite width
.height                 SKIP 1 ; Sprite height
.StartOffset            SKIP 1 ; Character offset for sprite

.vineFlag               SKIP 1
.vineFrame              SKIP 1
.vineDirection          SKIP 1
.vx                     SKIP 1
.vy                     SKIP 1
.delta_x                SKIP 1
.delta_y                SKIP 1
.x_dir                  SKIP 1

.clock_timer            SKIP 1
.clock_seconds          SKIP 1
.clock_minutes          SKIP 1

.lives                  SKIP 1

.score1                 SKIP 1
.score2                 SKIP 1
.score3                 SKIP 1

.treasureBits           SKIP 4
.treasureCnt            SKIP 1

.soundAddrPtr           SKIP 2
.soundPlaying           SKIP 1 ; 0 - sound off, 1 - sound on
.playSoundAddr          SKIP 2 ; storage for sound table address

.specialInput           SKIP 1
.pauseFlag              SKIP 1 ; $00 on, $80 off
.soundFlag              SKIP 1 ; $00 off, $80 on 
.joystickFlag           SKIP 1 ; $00 on, $80 off
.delayCounter           SKIP 1

; TODO
.joy_ch0                SKIP 1
.fire_up                SKIP 1
.keys_dn                SKIP 1
.joystickAnalogueSave   SKIP 1
.joystickADCHigh SKIP 1
.joy2 SKIP 1
.joy3 SKIP 1
.joy4 SKIP 1 
.joy5 SKIP 1 

.joystickChan   SKIP 2 ; Channel 0 = 0, Channel 1 = 1 

.end_of_ZP
;-------------------------------------------------------------------------

ORG NATIVE_ADDR
;-------------------------------------------------------------------------
; main entry &0100
;-------------------------------------------------------------------------
; Stored ar &0100 as it's preserved on break
;-------------------------------------------------------------------------
.CleanReset
{
    SEI
    LDA #&03    : STA &0258     ; *FX200,3
    LDA #OP_RTI : STA &0D00     ; NMI
    LDA #&7F    : STA &FE4E     ; Disable sysvia interrupts
    LDA #&40    : STA nuLACtrl  ; RESET NuLA (logical palette mode)
    JMP (RESET_BEEB)            ; JMP (&FFFC)
}
;-------------------------------------------------------------------------
; &0200
;-------------------------------------------------------------------------
ORG &0200

.ColourMask
EQUB $00, $55, $AA, $FF ; Mode 2 Colour mask (4 bytes spare before IRQ at &0204)

ORG &0204
EQUW irq_handler

;-------------------------------------------------------------------------
; WaitForVsync
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.WaitForVsync
{
    LDA vsyncCnt
    BEQ WaitForVsync
    LDA #0 : STA vsyncCnt
    RTS
}

;-------------------------------------------------------------------------
;    IRQ handler
;-------------------------------------------------------------------------
.irq_handler
{
    LDA sysVIAInterruptFlagReg
    AND #%00000010
    BNE irq_vsync

.irq_timer1
    LDA #%1000000           ; Clear timer1 interrupt
    STA sysVIAInterruptFlagReg

    INC vsyncCnt

    LDA irq_A_save
    RTI

.irq_vsync
    STA sysVIAInterruptFlagReg
    JSR process_sound

.exit
    LDA irq_A_save
    RTI
}

;-------------------------------------------------------------------------
; ClearScreen
;-------------------------------------------------------------------------
; On entry  :
; On exit   : A = $00, X and Y are underfined
;-------------------------------------------------------------------------
.ClearScreen
{
    LDX #$80
    LDA #0
    TAY
.clearloop
    STA SCREEN_ADDRESS,Y    ; Start Address $3000
    INY
    BNE clearloop
    INC clearloop+2
    DEX
    BNE clearloop
    RTS
}

;-------------------------------------------------------------------------
; IncrementScore
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.IncrementScore
{
    LDA objectType
    AND #$03
    ASL A : ASL A : ASL A : ASL A
    ADC #$20                ; add at least 2000 points
    SED
    ADC score2
    STA score2
    LDA #$00
    ADC score3
    STA score3
    CLD
    JMP PrintScore
    ; return
}

;-------------------------------------------------------------------------
; ReduceScore100
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.ReduceScore100
{
    LDA #$00
    JMP ReduceScore100s
    ; return
}

;-------------------------------------------------------------------------
; ReduceScore
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.ReduceScore
{
    LDA #$99        ; decrease score1 by 1
.^ReduceScore100s   ; decrease score2 by 1
    SED
    CLC
    ADC score1
    STA score1
    LDA score2
    SBC #$00
    STA score2
    LDA score3
    SBC #$00
    BCS notZero

    LDA #$00        ; limit score at zero
    STA score2
    STA score1

.notZero
    STA score3
    CLD
    RTS
}

.StartGame
{
    JSR ClearScreen
    JMP InitialiseGame
}

;ORG &0258
;*FX247,3
;EQUB $03

ORG &0287
.break_vector
   JMP CleanReset

;-------------------------------------------------------------------------
; GameOver 
;-------------------------------------------------------------------------
.GameOver
{
    LDA #LO(GameOverText) : STA text_addr
    LDA #HI(GameOverText) : STA text_addr+1
    JSR MessageBox

    LDX #sfxGameOver : JSR InitSound
.sfx_loop    
    LDA soundPlaying : BNE sfx_loop

.keypress_loop
    JSR ProcessInput
    LDA specialInput
    CMP #SPECIAL_ESCAPE
    BEQ escape_pressed

    LDA playerInput
    BEQ keypress_loop

.escape_pressed
    ; fall through
}

;-------------------------------------------------------------------------
;  IniitialiseGame
;-------------------------------------------------------------------------
.InitialiseGame
{
    ; wipe zero page
    LDA #0
    LDX #$FF
.zp_loop
    STA 0,X
    DEX
    BNE zp_loop

    LDA #$01 : STA clock_timer   : STA player_direction : STA vineDirection
    LDA #$03 : STA lives

    LDA #$1F : STA treasureCnt  ; from 31 -> 0
    LDA #$20 : STA clock_minutes : STA score2
    
    LDA #$0A                  : STA player_x
    LDA #PLAYER_JUNGLE_GROUND : STA player_y
    LDA #SPECIAL_KEYS_COUNTER : STA delayCounter

    LDA #$80                ; %10000000 - set bit 7 to 1
    STA pauseFlag           ; NB
    STA soundFlag           ; Use BMI if bit 7 is 1
    STA joystickFlag        ; Use BPL if bit 7 is 0
    STA fire_up
    
    LDA #RAND_SEED : STA random

    JSR ContRandom

    LDX #$00
    LDY #$00
    JSR DrawScreen
    JSR PrintClock
    JSR PrintLives
    JSR PrintScore
    JSR PrintSpecial

.start_loop
  
    JSR ProcessInput
    LDA specialInput
    CMP #SPECIAL_ESCAPE
    BNE notEscape
    JMP CleanReset

.notEscape
    LDA playerInput
    BEQ start_loop
    ; loop back around for keypress
}

;-------------------------------------------------------------------------
; MainLoop - Game
;-------------------------------------------------------------------------
.MainLoop

    JSR WaitForVsync
    INC frameCnt

    JSR UpdateClock
    JSR UpdateSprites
    JSR CheckCollision
    JSR CheckSpecialKeys
    
    JSR ProcessInput
    LDA specialInput
    AND #SPECIAL_ESCAPE
    BNE reset_game
    
    ; Loop until all treasure is found
    LDA treasureCnt
    BNE MainLoop

.game_finished
    LDA #LO(WellDoneText) : STA text_addr
    LDA #HI(WellDoneText) : STA text_addr+1
    JSR MessageBox

.welldone_keypress_loop
    JSR ProcessInput
    LDA playerInput
    BEQ welldone_keypress_loop

.reset_game
    JMP InitialiseGame
    ; return

;-------------------------------------------------------------------------
; CheckSpecialKeys
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.CheckSpecialKeys
{
    LDA delayCounter
    DEC delayCounter
    BNE not_pause

    LDA #SPECIAL_KEYS_COUNTER : STA delayCounter

    JSR KeyboardScan
    LDA specialInput
    AND #SPECIAL_S
    BEQ not_sound
    LDA soundFlag : EOR #$80 : STA soundFlag    ; Sound On / Off
    
.not_sound
    ; TODO
    LDA specialInput
    AND #SPECIAL_J
    BEQ not_joystick
    LDA joystickFlag : EOR #$80 : STA joystickFlag    ; Joystick On / Off

.not_joystick
    LDA specialInput
    AND #SPECIAL_P
    BEQ not_pause
    LDA pauseFlag : EOR #$80 : STA pauseFlag    ; Pause On / Off

.not_pause

    JSR PrintSpecial

    BIT pauseFlag
    BMI exit
    JSR WaitForVsync
    BIT pauseFlag
    BPL CheckSpecialKeys
    ; if pause then loop back until unpaused
    
.exit
    RTS
}

.PrintSpecial
{
    ; J Q P
    ; K S 
    LDA #WHITE : STA chrFontColour
    LDA #LO(SPECIAL_ADDRESS) : STA write_addr
    LDA #HI(SPECIAL_ADDRESS) : STA write_addr+1

    LDA joystickFlag : ASL A : ADC #10 : TAX
    JSR PrintChar

    LDA soundFlag : ASL A : ADC #12 : TAX
    JSR PrintChar

    LDA pauseFlag : ASL A : ADC #14 : TAX
    JMP PrintChar
    
    ;RTS
}

;-------------------------------------------------------------------------
; MessageBox
;-------------------------------------------------------------------------
.MessageBox
{
    ; This is the message
    LDA #LO(ENDING_ADDRESS2) : STA write_addr
    LDA #HI(ENDING_ADDRESS2) : STA write_addr+1
    JSR PrintString

    LDA #LO(ENDING_ADDRESS1) : STA write_addr
    LDA #HI(ENDING_ADDRESS1) : STA write_addr+1
    LDA #LO(BoxTopText) : STA text_addr
    LDA #HI(BoxTopText) : STA text_addr+1
    JSR PrintString 

    LDA #LO(ENDING_ADDRESS3) : STA write_addr
    LDA #HI(ENDING_ADDRESS3) : STA write_addr+1
    LDA #LO(BoxBottomText) : STA text_addr
    LDA #HI(BoxBottomText) : STA text_addr+1
    JMP PrintString
}

.TreasureMask
EQUB %10000000
EQUB %01000000
EQUB %00100000
EQUB %00010000
EQUB %00001000
EQUB %00000100
EQUB %00000010
EQUB %00000001

.tree_position
EQUB $07,$17,$35,$45    ; 00
EQUB $0B,$1B,$31,$41    ; 01
EQUB $0F,$1F,$2D,$3D    ; 10
EQUB $11,$21,$2B,$3B    ; 11

; Address set within PlotSpriteMask
.MaskAddrPtrLo
EQUB $FF  ; Player
EQUB $FF  ; Log 1
EQUB $FF  ; Log 2
EQUB $FF  ; Log 3
EQUB $FF  ; Scorpion
EQUB $FF  ; Spare

; Address set within PlotSpriteMask
.MaskAddrPtrHi
EQUB $FF  ; Player
EQUB $FF  ; Log 1
EQUB $FF  ; Log 2
EQUB $FF  ; Log 3
EQUB $FF  ; Scorpion
EQUB $FF  ; Spare

;-------------------------------------------------------------------------
.mask_table_start
;-------------------------------------------------------------------------
; Mask Table must be on a page boundary
;-------------------------------------------------------------------------
ALIGN &100
.mask_table_addr
EQUB $FF, $AA, $55, $00, $AA, $AA, $00, $00, $55, $00, $55, $00, $00, $00, $00, $00
EQUB $AA, $AA, $00, $00, $AA, $AA, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $55, $00, $55, $00, $00, $00, $00, $00, $55, $00, $55, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $AA, $AA, $00, $00, $AA, $AA, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $AA, $AA, $00, $00, $AA, $AA, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $55, $00, $55, $00, $00, $00, $00, $00, $55, $00, $55, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $55, $00, $55, $00, $00, $00, $00, $00, $55, $00, $55, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
EQUB $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

;-------------------------------------------------------------------------
; Erase Table must be on a page boundary
;-------------------------------------------------------------------------
.erase_table_addr SKIP 512
; 2 pages of $00



INCLUDE "Player.asm"
INCLUDE "Scorpion.asm"
INCLUDE "Crocodile.asm"
INCLUDE "Objects.asm"
INCLUDE "Vine.asm"
INCLUDE "Swamp.asm"

;-------------------------------------------------------------------------
; UpdateSprites
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.UpdateSprites
{
    ; Erase Sprites from top to bottom (z ordering)
    JSR ErasePlayer
    JSR EraseScorpion
    JSR EraseObjectSprites
    JSR EraseCrocodiles
    ; Don't need to erase quicksand as DrawSwamp takes care of it
    JSR PlotVine;EraseVine
    ; Update sprites from top to bottom (z ordering)
    JSR UpdatePlayer
    BCS newScreenCreated    ; Don't update and draw sprites
                            ; as we built a new scene

    JSR UpdateScorpion
    JSR UpdateObjectSprites
    JSR UpdateCrocodiles
    JSR UpdateQuickSand
    JSR UpdateVine

    ; Draw sprites from bottom to top (z ordering)
    JSR PlotVine;DrawVine
    JSR DrawQuickSand
    JSR DrawCrocodiles
    JSR DrawObjectSprites
    JSR DrawScorpion
    JSR DrawPlayer

.newScreenCreated
    ; Updates and Drawing can be ignored as a new screen has been generated
    RTS
}

;-------------------------------------------------------------------------
; DrawScreen
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.DrawScreen
{
    JSR WaitForVsync

    JSR DrawBase
    JSR DrawTrees
    JSR DrawLeaves

    LDA ladderFlag      ; ladder in scene
    BEQ noLadder

    ; Draw ladder and wall
    JSR DrawLadder
    JSR DrawWall

    LDA sceneType
    CMP #HOLE3_SCENE
    BNE noScorpion

    ; Draw 2 holes
    LDX #24 : JSR DrawHole
    LDX #50 : JSR DrawHole

    JMP noScorpion
    ; return

.noLadder
    ; Must contain a scorpion then
    JSR WaitForVsync

    JSR InitScorpion
    JSR InitSwamp
    JSR InitVine
    JSR InitCrocodile

.noScorpion
    JSR InitObjects
    JMP InitPlayer
    ; return
}

;-------------------------------------------------------------------------
; UpdateClock
;-------------------------------------------------------------------------
; On entry  :
; On exit   : X and Y are preserved
;-------------------------------------------------------------------------
.UpdateClock
{
    DEC clock_timer
    BNE exit

    LDA #50 : STA clock_timer

    ; Downdate clock
    SED
    LDA clock_seconds : SEC : SBC #$01
    BCS over
    LDA #$59
.over
    STA clock_seconds
    LDA clock_minutes : SBC #$00 : STA clock_minutes
    CLD
    LDA clock_minutes
    ORA clock_seconds 
    BNE PrintClock  
    JSR PrintClock     
    JMP GameOver

.^PrintClock

    LDA #WHITE
    STA chrFontColour

    LDA #LO(CLOCK_ADDRESS) : STA write_addr
    LDA #HI(CLOCK_ADDRESS) : STA write_addr+1

    LDA clock_minutes
    JSR BCDtoScreen

    LDX #18         ;':'
    JSR PrintChar

    LDA clock_seconds
    JSR BCDtoScreen
    ; return

.exit
    RTS
}

;-------------------------------------------------------------------------
; ReduceLives
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.ReduceLives
{
    DEC lives
    LDA lives
    BNE continue
    JMP GameOver
    ; return

.continue
    ; fall through
}

;-------------------------------------------------------------------------
; PrintLives
;-------------------------------------------------------------------------
; On entry  :
; On exit   : X and Y are preserved
;-------------------------------------------------------------------------
.PrintLives
{
    LDA #WHITE : STA chrFontColour

    LDA #LO(LIVES_ADDRESS) : STA write_addr
    LDA #HI(LIVES_ADDRESS) : STA write_addr+1

    LDA #14 : CLC : ADC lives : TAX
    JMP PrintChar
    ; return
}

;-------------------------------------------------------------------------
; PrintScore
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PrintScore
{
    LDA #WHITE : STA chrFontColour

    LDA #LO(SCORE_ADDRESS) : STA write_addr
    LDA #HI(SCORE_ADDRESS) : STA write_addr+1             

    LDA #OP_BEQ : STA PrintDigit       

    LDY #2                          
.loop
    LDA score1,Y
    LSR A : LSR A : LSR A : LSR A
    JSR PrintDigit

    CPY #$00
    BNE continue
    LDA #OP_BMI : STA PrintDigit       

.continue
    LDA score1,Y
    AND #$0F
    JSR PrintDigit

    DEY
    BPL loop

.exit
    RTS

.PrintDigit
    BEQ PrintSpace                  ; Swaps between BEQ and BMI
    TAX
    JSR PrintChar
    LDA #$30 : STA PrintDigit       ; BMI
    RTS

.PrintSpace
    LDX #15
    JMP PrintChar
    ; return
}

;-------------------------------------------------------------------------
; PrintString
;-------------------------------------------------------------------------
; On entry  : X and Y contain character position
; On exit   : A,X and Y are undefined  
;-------------------------------------------------------------------------
.PrintString
{
    LDY #0
.loop
    LDA (text_addr),Y
    BMI finished
    TAX
    JSR PrintChar
    INY
    BNE loop
.finished    
    RTS   
}


;-------------------------------------------------------------------------
; PrintChar
;-------------------------------------------------------------------------
; On entry  : X contains font character
; On exit   : A and X are undefined
;           : Y is preserved
;-------------------------------------------------------------------------
.PrintChar
{
    TYA : PHA
    
    LDA #0 : STA chrFontAddr+1  ; Store 0 in chrFontAddr+1
    TXA                         ; Transfer X to A
    ASL A : ASL A : ASL A       ; Calc A*8
    ROL chrFontAddr+1
    ADC #LO(font_data)
    STA chrFontAddr

    LDA chrFontAddr+1
    ADC #HI(font_data)
    STA chrFontAddr+1

    LDY #$07
    BNE displaychar             ; Always branch

.nextPatternByte 
    TYA                                                 
    SBC #$21                                            
    BMI finish                                         
    TAY   

.displaychar
    LDA (chrFontAddr),Y         ; Point to font data
    STA currentCharacter    
    SEC

.loop
    LDA #0                                              
    ROL currentCharacter                              
    BEQ nextPatternByte                             
    ROL A                                             
    ASL currentCharacter                               
    ROL A                                              
    TAX                                               
    LDA ColourMask,X            
    AND chrFontColour 
    STA (write_addr),Y          
    CLC                                              
    TYA                                               
    ADC #8                                                                                           
    TAY                                               
    BCC loop 
    
.finish    
    ; Advance to next character position
    CLC
    LDA write_addr
    ADC #32
    STA write_addr
    BCC exit
    ; Advance to next line position
    INC write_addr+1

.exit    
    PLA : TAY 
    RTS
}

;-------------------------------------------------------------------------
; BCDtoScreen
;-------------------------------------------------------------------------
; On entry  : A contains value
; On exit   : A and X are underfined
;           : Y is preserved
;-------------------------------------------------------------------------
.BCDtoScreen
{
    PHA
    LSR A : LSR A : LSR A : LSR A
    JSR onedigit
    PLA
    AND #$0F
.onedigit    
    TAX
    JMP PrintChar
    ; return
}

;-------------------------------------------------------------------------
; DrawBase
;-------------------------------------------------------------------------
; MapBase Layer uses a 5 - 3 format
;-------------------------------------------------------------------------zxzxzx
; On entry  : X is the row offset into map data, Y is y position
; On exit   :
;-------------------------------------------------------------------------
.DrawBase
{
    STY currentYPosition
    LDA #$00 : STA currentXPosition

.loop1
    LDA MapBaseLayer,X
    CMP #$FF
    BEQ exit

    PHA
    AND #%11111000          ; Number
    ROR A : ROR A : ROR A
    TAY
    PLA
    AND #%00000111          ; Sprite No.
    STA currentCharacter

.loop2
    JSR PlotCharSprite

    INC currentXPosition
    LDA currentXPosition
    CMP #20
    BNE over
    INC currentYPosition

    LDA #$00 : STA currentXPosition
.over
    DEY
    BNE loop2
    INX
    BPL loop1

.exit
    RTS
}

;-------------------------------------------------------------------------
; DrawTrees
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.DrawTrees
{
    LDA treePat
    ASL A : ASL A
    ADC #3
    TAX
    LDY #3
.loop
    LDA tree_position,X
    STA XOrd

    LDA #88 : STA YOrd  ; Branch y pos

    LDA #TREE_BRANCH : STA currentCharacter
    JSR PlotSpriteCharTile

    LDA #96  : STA YOrd     ; Trunk top
    LDA #160 : STA YOrd2    ; Trunk bottom
    LDA #TREE_TRUNK
    JSR DrawVertical

    DEX
    DEY
    BPL loop
    RTS
}

;-------------------------------------------------------------------------
; DrawLeaves
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.DrawLeaves
{
    LDA #88 : STA YOrd

    LDX treePat
    LDA leaves_list,X : TAX

    LDY #1      ; screen column 1
.loop
    LDA LeavesTable,X : STA currentCharacter
    TYA
    ASL A : ASL A
    STA XOrd

    JSR PlotSpriteCharTileNoBlack

    INX
    INY
    CPY #20     ; screen column 20
    BNE loop
    RTS
}

;-------------------------------------------------------------------------
; DrawLadder
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.DrawLadder
{
    LDA #HOLE_BLOCK : STA currentCharacter
    LDA #38  : STA XOrd
    LDA #164 : STA YOrd
    JSR PlotSpriteTile

    LDA #176 : STA YOrd
    LDA #LADDER_TOP : STA currentCharacter
    JSR PlotSpriteCharTile

    LDA #184 : STA YOrd
    LDA #224 : STA YOrd2
    LDA #LADDER
    JMP DrawVertical
    ; return
}

;-------------------------------------------------------------------------
; DrawWall
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.DrawWall
{
    LDA xPosScorpion : STA XOrd
    LDA #192 : STA YOrd
    LDA #224 : STA YOrd2
    LDA #WALL
    JMP DrawVertical
    ; return
}

;-------------------------------------------------------------------------
; DrawHole
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.DrawHole
{
    STX XOrd

    LDA #HOLE_BLOCK : STA currentCharacter
    LDA #164 : STA YOrd
    JSR PlotSpriteTile

    LDA #BLACK_BLOCK : STA currentCharacter
    LDA #176 : STA YOrd
    JSR PlotSpriteCharTile

    LDA #BLACK_BLOCK : STA currentCharacter
    LDA #184 : STA YOrd
    JSR PlotSpriteCharTile

    LDA XOrd : CLC : ADC #2 : STA XOrd

    LDA #HOLE_BLOCK : STA currentCharacter
    LDA #164 : STA YOrd
    JSR PlotSpriteTile

    LDA #BLACK_BLOCK : STA currentCharacter
    LDA #176 : STA YOrd
    JSR PlotSpriteCharTile

    LDA #BLACK_BLOCK : STA currentCharacter
    LDA #184 : STA YOrd
    JMP PlotSpriteCharTile
    ; return
}

;-------------------------------------------------------------------------
; DrawVertical
;-------------------------------------------------------------------------
; On entry  : A is current sprite character
; On exit   :
;-------------------------------------------------------------------------
; Vertical structures such as tree trunks, wall and ladder
;-------------------------------------------------------------------------
.DrawVertical
{
    STA currentCharacter

    LDA YOrd
.loop
    JSR PlotSpriteCharTile

    LDA YOrd : CLC : ADC #8 : STA YOrd
    CMP YOrd2
    BCC loop
    RTS
}

;-------------------------------------------------------------------------
; GetXYScreenAddress
;-------------------------------------------------------------------------
; On entry  : currentXPosition = 0-79, currentYPosition = 0-255
; On exit   : A, X and Y are underfined
;           : Fals through into GetScreenAddress
;-------------------------------------------------------------------------
.GetXYScreenAddress
{
    ; start this can be moved out
    LDA currentXPosition : STA XOrd
    LDA currentYPosition

.^GetXYScreenAddressYOrd    
    CLC
    ADC height          ; but only to nearest character row start
    STA YOrd
    AND #7              ; put low order bits in X  for index addressing
    STA StartOffset     ; preserve this for use later

    LDA YOrd            ; then store the other bits 3-7 in YOrd to get screen address of nearest character start row
    AND #248
    STA YOrd
    ; Fall through

}

;-------------------------------------------------------------------------
; GetScreenAddress
;-------------------------------------------------------------------------
; On entry  : XOrd = 0-159, YOrd = 0-255
; On exit   : A is underfined, X and Y are preserved
;-------------------------------------------------------------------------
.GetScreenAddress     
    LDY YOrd                    ; Y contains YOrd
    LDA #0 : STA write_addr+1   ; Store 0 in write_addr+1; used as overflow when calculating X*8
    TYA                         ; Transfer Y to A
    AND #%00000111              ; AND with 7
    STA write_addr              ; Store    in write_addr (Screen low byte)
    TYA                         ; Transfer Y to A
    LSR A : LSR A : LSR A       ; Calculate Y=(Y/8)
    TAY                         ; Y contains index into lookup table

    LDA XOrd : ASL A            ; Calculate X*4, using write_addr+1 as overflow
    AND #%11111110              ; Ignore the first bit of X (the pixel position)

    ASL A
    ROL write_addr+1
    ASL A
    ROL write_addr+1            ; Calculate X=(X*4), with overflow into write_addr+1

    ADC write_addr              ; Add to the screen low byte
    ADC LookUp640Low, Y         ; Add the low byte of the screen multiplication table
    STA write_addr              ; Store back in the screen low byte

    LDA write_addr+1            ; Get the overflow of X*4 (high byte)
    ADC LookUp640High, Y        ; Add the high byte of the screen multiplication table
    STA write_addr+1            ; Store in the screen high byte

.exit
    RTS

;-------------------------------------------------------------------------
; PlotCharSprite
;-------------------------------------------------------------------------
; This plots an 8x8 sprite at character position X,Y
;-------------------------------------------------------------------------
; On entry  : currentXPosition = 0-19, currentYPosition = 0-31
; On exit   : A is underfined
;           : X AND Y are preserved
;-------------------------------------------------------------------------
.PlotCharSprite
{
    LDA currentXPosition
    ASL A : ASL A
    STA XOrd

    LDA currentYPosition
    ASL A : ASL A : ASL A
    STA YOrd
    ; Fall through to PlotSpriteCharTile
}

;-------------------------------------------------------------------------
; PlotSpriteCharTile
;-------------------------------------------------------------------------
; This plots an 8x8 sprite at screen coords XOrd,YOrd (character boundary)
;-------------------------------------------------------------------------
; On entry  : XOrd AND YOrd contain the screen coords
; On exit   : A is underfined
;           : X AND Y are preserved
;-------------------------------------------------------------------------
.PlotSpriteCharTile
{
    STX saveX : STY saveY

    JSR GetScreenAddress                   ; Screen address is stored in write_addr

    LDA write_addr+0 : STA sprite_write+1
    LDA write_addr+1 : STA sprite_write+2

    LDX currentCharacter
    LDA spriteAddrTableLo,X : STA sprite_read+1
    LDA spriteAddrTableHi,X : STA sprite_read+2

    LDX #31                                 ; game sprites are always 8x8 (Mode 2 are 4 bits * 8 bits => 0-31)
.sprite_read
    LDA $FFFF,X

.sprite_write
    STA $FFFF,X

    DEX
    BPL sprite_read

    LDX saveX : LDY saveY
    RTS
}

;-------------------------------------------------------------------------
; PlotSpriteCharTile
;-------------------------------------------------------------------------
; This plots an 8x8 sprite at screen coords XOrd,YOrd
; but exludes plotting black - used by leaves
;-------------------------------------------------------------------------
; On entry  : XOrd AND YOrd contain the screen coords
; On exit   : A is underfined
;           : X AND Y are preserved
;-------------------------------------------------------------------------
.PlotSpriteCharTileNoBlack
{
    STX saveX : STY saveY

    JSR GetScreenAddress                   ; Screen address is stored in write_addr

    LDA write_addr+0 : STA sprite_write+1
    LDA write_addr+1 : STA sprite_write+2

    LDX currentCharacter
    LDA spriteAddrTableLo,X : STA sprite_read+1
    LDA spriteAddrTableHi,X : STA sprite_read+2

    LDX #31                                 ; game sprites are always 8x8 (Mode 2 are 4 bits * 8 bits => 0-31)
.sprite_read
    LDA $FFFF,X
    BEQ ignore_black

.sprite_write
    STA $FFFF,X
.ignore_black
    DEX
    BPL sprite_read

    LDX saveX : LDY saveY
    RTS
}

;-------------------------------------------------------------------------
; PlotSpriteTile
;-------------------------------------------------------------------------
; This plots an 8x8 sprite at screen coords XOrd,YOrd
;-------------------------------------------------------------------------
; On entry  : XOrd AND YOrd contain the screen coords
; On exit   : A is underfined
;           : X AND Y are preserved
;-------------------------------------------------------------------------
.PlotSpriteTile
{
    LDA #8 : LSR A : STA width
    LDA #8 : SEC : SBC #1 : STA height

    LDX currentCharacter
    LDA spriteAddrTableLo,X : STA sprite_read+1
    LDA spriteAddrTableHi,X : STA sprite_read+2

    LDA YOrd
    JSR GetXYScreenAddressYOrd

    LDA write_addr   : STA sprite_write+1
    LDA write_addr+1 : STA sprite_write+2

    LDX StartOffset

.PlotXLoop
    LDY height

.PlotLoop

.sprite_read
    LDA $FFFF,Y             ; dummy address, will be filled in by code

.sprite_write
    STA $FFFF,X             ; dummy address, will be filled in by code

    DEX
    BPL NotAtRowBoundary

    SEC
    LDA sprite_write+1
    SBC #LO(charRow)
    STA sprite_write+1

    LDA sprite_write+2
    SBC #HI(charRow)
    STA sprite_write+2

    LDX #7

.NotAtRowBoundary

    DEY
    BPL PlotLoop

    DEC width
    BEQ EndPlotSprite

    SEC
    LDA sprite_read+1
    ADC height
    STA sprite_read+1

    BCC NoIncToSprite
    INC sprite_read+2
    CLC

.NoIncToSprite

    LDA write_addr
    ADC #8
    STA write_addr
    STA sprite_write+1

    BCC NoIncToSpriteHighByte
    INC write_addr+1

.NoIncToSpriteHighByte

    LDA write_addr+1
    STA sprite_write+2

    LDX StartOffset
    BPL PlotXLoop

.EndPlotSprite

    RTS
}

;-------------------------------------------------------------------------
; PlotSprite
;-------------------------------------------------------------------------
; This plot an sprite at position X,Y
; Used by the swamp only
;-------------------------------------------------------------------------
; On entry  :
; On exit   : A is underfined
;           : X and Y are preserved
;-------------------------------------------------------------------------
.PlotSprite
{
    STX saveX : STY saveY

    LDA width : LSR A : STA width
    LDA height : SEC : SBC #1 : STA height

    LDX currentCharacter
    LDA spriteAddrTableLo,X : STA sprite_read+1
    LDA spriteAddrTableHi,X : STA sprite_read+2

    ; Calc write_addr
    JSR GetXYScreenAddress
    
    LDA write_addr   : STA sprite_write+1 
    LDA write_addr+1 : STA sprite_write+2

    LDX StartOffset

.PlotXLoop
    LDY height

.PlotLoop

.sprite_read
    LDA $FFFF,Y             ; dummy address, will be filled in by code

.sprite_write
    STA $FFFF,X             ; dummy address, will be filled in by code

    DEX
    BPL NotAtRowBoundary

    SEC
    LDA sprite_write+1
    SBC #LO(charRow)
    STA sprite_write+1

    LDA sprite_write+2
    SBC #HI(charRow)
    STA sprite_write+2

    LDX #7

.NotAtRowBoundary

    DEY
    BPL PlotLoop

    DEC width
    BEQ EndPlotSprite

    SEC
    LDA sprite_read+1
    ADC height
    STA sprite_read+1

    BCC NoIncToSprite
    INC sprite_read+2
    CLC

.NoIncToSprite

    LDA write_addr
    ADC #8
    STA write_addr : STA sprite_write+1

    BCC NoIncToSpriteHighByte
    INC write_addr+1

.NoIncToSpriteHighByte

    LDA write_addr+1 : STA sprite_write+2

    LDX StartOffset
    BPL PlotXLoop

.EndPlotSprite

    LDY saveY : LDX saveX
    RTS
}

;-------------------------------------------------------------------------
; EraseSpriteMask
;-------------------------------------------------------------------------
; This plots the saved background position X,Y
;-------------------------------------------------------------------------
; On entry  : X = erase index
; On exit   : A and X are underfined
;           : Y is preserved
;-------------------------------------------------------------------------
.EraseSpriteMask
{
    STY saveY

    LDX eraseCharacter
    LDA MaskStoreDataAddressLo,X : STA sprite_read+1
    LDA MaskStoreDataAddressHi,X : STA sprite_read+2

    LDA MaskAddrPtrLo,X : STA write_addr   : STA sprite_write+1
    LDA MaskAddrPtrHi,X : STA write_addr+1 : STA sprite_write+2

    LDA width : LSR A : STA width
    LDA height : SEC : SBC #1 : STA height

    LDA currentYPosition
    CLC
    ADC height      ; but only to nearest character row start
    AND #7          ; put low order bits in X  for index addressing
    STA StartOffset ; preserve this for use later
    TAX

.PlotXLoop
    LDY height

.PlotLoop

.sprite_read
    LDA $FFFF,Y     ;dummy address, will be filled in by code

.sprite_write
    STA $FFFF,X     ; dummy address, will be filled in by code

    DEX
    BPL NotAtRowBoundary

    SEC
    LDA sprite_write+1
    SBC #LO(charRow)
    STA sprite_write+1

    LDA sprite_write+2
    SBC #HI(charRow)
    STA sprite_write+2

    LDX #7

.NotAtRowBoundary

    DEY
    BPL PlotLoop

    DEC width
    BEQ EndPlotSprite

    SEC
    LDA sprite_read+1
    ADC height          
    STA sprite_read+1

    BCC NoIncToSprite
    INC sprite_read+2
    CLC

.NoIncToSprite

    LDA write_addr
    ADC #8
    STA write_addr : STA sprite_write+1

    BCC NoIncToSpriteHighByte
    INC temp_addr+1
    INC write_addr+1

.NoIncToSpriteHighByte
    LDA write_addr+1 : STA sprite_write+2

    LDX StartOffset
    BPL PlotXLoop

.EndPlotSprite

    LDY saveY
    RTS
}

;-------------------------------------------------------------------------
; PlotSpriteMask
;-------------------------------------------------------------------------
; This plot an sprite at position X,Y
;-------------------------------------------------------------------------
; On entry  :
; On exit   : A is underfined
;           : X and Y are preserved
;-------------------------------------------------------------------------
.PlotSpriteMask
{
    STY saveY
    LDA width : LSR A : STA width
    LDA height : SEC : SBC #1 : STA height

    ; Calc write_addr
    JSR GetXYScreenAddress
   
    LDX eraseCharacter
    LDA MaskStoreDataAddressLo,X : STA temp_addr
    LDA MaskStoreDataAddressHi,X : STA temp_addr+1

    LDA write_addr   : STA MaskAddrPtrLo,X
    LDA write_addr+1 : STA MaskAddrPtrHi,X

    LDX currentCharacter
    LDA spriteAddrTableLo,X : STA sprite_read+1
    LDA spriteAddrTableHi,X : STA sprite_read+2

    LDA write_addr   : STA sprite_write+1 : STA screen_read+1
    LDA write_addr+1 : STA sprite_write+2 : STA screen_read+2

    LDA temp_addr   : STA screen_save+1
    LDA temp_addr+1 : STA screen_save+2

    LDX StartOffset   

.PlotXLoop
    LDY height

.PlotLoop

.sprite_read
    LDA $FFFF,Y             ; dummy address, will be filled in by code
    STA mask_read+1

.screen_read
    LDA $FFFF,X

.screen_save
    STA $FFFF,Y             ; Save data into 0A00 - 0BFF
    BMI sprite_write        ; Skip if colour 8-15 Flashing

.mask_read
    AND mask_table_addr     ; 0900 - 09FF LO byte will be filled in by code STA mask_read+1
    ORA mask_read+1

.sprite_write
    STA $FFFF,X             ; dummy address, will be filled in by code

    DEX
    BPL NotAtRowBoundary

    SEC
    LDA sprite_write+1
    SBC #LO(charRow)
    STA sprite_write+1
    STA screen_read+1

    LDA sprite_write+2
    SBC #HI(charRow)
    STA sprite_write+2
    STA screen_read+2

    LDX #7

.NotAtRowBoundary

    DEY
    BPL PlotLoop

    DEC width
    BEQ EndPlotSprite

    SEC
    LDA screen_save+1
    ADC height
    STA screen_save+1

    SEC
    LDA sprite_read+1
    ADC height
    STA sprite_read+1

    BCC NoIncToSprite
    INC sprite_read+2
    INC screen_save+2
    CLC

.NoIncToSprite

    LDA write_addr
    ADC #8
    STA write_addr
    STA sprite_write+1
    STA screen_read+1

    BCC NoIncToSpriteHighByte
    INC write_addr+1

.NoIncToSpriteHighByte

    LDA temp_addr+1
    STA screen_save+2

    LDA write_addr+1
    STA sprite_write+2
    STA screen_read+2

    LDX StartOffset
    BPL PlotXLoop

.EndPlotSprite

    LDY saveY
    RTS
}

;-------------------------------------------------------------------------
; PlotSpriteLogMask
;-------------------------------------------------------------------------
; This plot an sprite at position X,Y
;-------------------------------------------------------------------------
; On entry  :
; On exit   : A is underfined
;           : X and Y are preserved
;-------------------------------------------------------------------------
.PlotSpriteLogMask
{
    STY saveY
    LDA width : LSR A : STA width
    LDA height : SEC : SBC #1 : STA height

    ; Calc write_addr
    JSR GetXYScreenAddress

    LDX eraseCharacter
    LDA MaskStoreDataAddressLo,X : STA temp_addr
    LDA MaskStoreDataAddressHi,X : STA temp_addr+1

    LDA write_addr   : STA MaskAddrPtrLo,X
    LDA write_addr+1 : STA MaskAddrPtrHi,X

    LDX currentCharacter
    LDA spriteAddrTableLo,X : STA sprite_read+1
    LDA spriteAddrTableHi,X : STA sprite_read+2

    LDA write_addr   : STA sprite_write+1 : STA screen_read+1
    LDA write_addr+1 : STA sprite_write+2 : STA screen_read+2

    LDA temp_addr   : STA screen_save+1
    LDA temp_addr+1 : STA screen_save+2

    LDX StartOffset

.PlotXLoop
    LDY height

.PlotLoop

.sprite_read
    LDA $FFFF,Y             ; dummy address, will be filled in by code
    STA mask_read+1

.screen_read
    LDA $FFFF,X             ; dummy address, will be filled in by code

.screen_save
    STA $FFFF,Y             ; Save data into 0A00 - 0BFF

.mask_read
    AND mask_table_addr     ; 0900 - 09FF LO byte will be filled in by code STA mask_read+1
    ORA mask_read+1

.sprite_write
    STA $FFFF,X             ; dummy address, will be filled in by code

    DEX
    BPL NotAtRowBoundary

    SEC
    LDA sprite_write+1
    SBC #LO(charRow)
    STA sprite_write+1
    STA screen_read+1

    LDA sprite_write+2
    SBC #HI(charRow)
    STA sprite_write+2
    STA screen_read+2

    LDX #7

.NotAtRowBoundary

    DEY
    BPL PlotLoop

    DEC width
    BEQ EndPlotSprite

    SEC
    LDA screen_save+1
    ADC height
    STA screen_save+1

    SEC
    LDA sprite_read+1
    ADC height
    STA sprite_read+1

    BCC NoIncToSprite
    INC sprite_read+2
    INC screen_save+2
    CLC

.NoIncToSprite

    LDA write_addr
    ADC #8
    STA write_addr
    STA sprite_write+1
    STA screen_read+1

    BCC NoIncToSpriteHighByte
    INC write_addr+1

.NoIncToSpriteHighByte

    LDA temp_addr+1
    STA screen_save+2

    LDA write_addr+1
    STA sprite_write+2
    STA screen_read+2

    LDX StartOffset
    BPL PlotXLoop

.EndPlotSprite

    LDY saveY
    RTS
}

;-------------------------------------------------------------------------
; ProcessInput
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.ProcessInput
{
    LDA #0 : STA playerInput : STA specialInput

    BIT joystickFlag
    BMI using_keyboard

    JSR JoystickScan

.using_keyboard

    ; Read Keyboard for player movements and special keys
    JSR KeyboardScan
    RTS
}

;-------------------------------------------------------------------------
; Joystick keymap Data
;-------------------------------------------------------------------------
.JoystickKeys
    EQUB JOYSTICK_DOWN,  0, 0, JOYSTICK_UP    ; Channel 1
    EQUB JOYSTICK_RIGHT, 0, 0, JOYSTICK_LEFT  ; Channel 0

;-------------------------------------------------------------------------
; JoystickScan
;-------------------------------------------------------------------------
; Channel 0 - X direction
; Channel 1 - Y direction
;-------------------------------------------------------------------------
.JoystickScan
{
    LDA sysVIAPortB
    AND #%00010000          ; bit 4 clear = fire pressed
    BNE button_not_pressed     
    LDA playerInput : ORA #JOYSTICK_FIRE : STA playerInput

.button_not_pressed

; ADCHigh address is altered for Master
.^ADCHighRead
    LDA ADCHigh : STA joystickADCHigh

; ADCControl address is altered for Master
.^ADCControlRead
    LDA ADCControl
    AND #%00000001
    EOR #%00000001

; ADCControl address is altered for Master
.^ADCControlWrite
    STA ADCControl
    TAX                     ; X = Channel No
    LSR A                   ; Move channel into carry flag

    ROL joystickADCHigh     ; C <- [76543210] <- C
    ROL joystickADCHigh     ; C <- [76543210] <- C
    ROL joystickADCHigh     ; C <- [76543210] <- C

    LDA joystickADCHigh     ; now contains 00000CXY (Channel No., X and Y)
    AND #%00000111          ; Mask of bits 0, 1 and 2 (00000MMM)
    TAY                     ; Transfer A to Y
 
    LDA JoystickKeys,Y      ; Get joystick bit
    STA joystickChan,X      ; Store into correct zp channel position
    
    LDA playerInput         ; Get value including fire button from above
    ORA joystickChan        ; Channel 0
    ORA joystickChan+1      ; Channel 1
    STA playerInput         ; Store new player input
    RTS
}

;-------------------------------------------------------------------------
; KeyboardScan
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.KeyboardScan
{
    LDA #%01111111
    STA sysVIADataDirectionRegA

    LDA #%00000011
    STA sysVIAPortB

    BIT joystickFlag
    BPL joystickOnly

    LDA #keySpace
    JSR KeyboardScanCheck

    LDA #keyX
    JSR KeyboardScanCheck

    LDA #keyColon
    JSR KeyboardScanCheck

    LDA #keySlash
    JSR KeyboardScanCheck

    LDA #keyZ
    JSR KeyboardScanCheck

    LDA #keyReturn
    JSR KeyboardScanCheck

.joystickOnly

    LDA #keyEscape
    JSR SpecialKeyboardScanCheck

    LDA #keyP
    JSR SpecialKeyboardScanCheck

    LDA #keyS
    JSR SpecialKeyboardScanCheck

    LDA #keyJ
    JSR SpecialKeyboardScanCheck

    LDA #%00001011
    STA sysVIAPortB

    LDA #%11111111
    STA sysVIADataDirectionRegA

    RTS
}

;-------------------------------------------------------------------------
; KeyboardScanCheck
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.KeyboardScanCheck
{
    STA sysVIAPortA     ; select key
    LDA sysVIAPortA     ; read key status
    ASL A               ; shift key status into player input bits
    ROL playerInput
    RTS                 ; done.
}

;-------------------------------------------------------------------------
; SpecialKeyboardScanCheck
;-------------------------------------------------------------------------
; On entry  :
; On exit   :
;-------------------------------------------------------------------------
.SpecialKeyboardScanCheck
{
    STA sysVIAPortA     ; select key
    LDA sysVIAPortA     ; read key status
    ASL A               ; shift key status into special input bits
    ROL specialInput
    RTS                 ; done.
}

;-------------------------------------------------------------------------
; RightRandom
;-------------------------------------------------------------------------
; generate new random scene on the right:
; random' = random << 1 | (bit3^bit4^bit5^bit7)
; Taken from Atari 2600
;-------------------------------------------------------------------------
; On entry  : A contains duration
; On exit   : A contains 19
;           : X AND Y are underfined
;-------------------------------------------------------------------------
.RightRandom
{
.loopRandom:
    LDA random
    ASL A
    eor random
    ASL A
    eor random
    ASL A
    ASL A
    eor random
    ASL A
    ROLrandom
    DEX
    BPL loopRandom
    JMP ContRandom
    ; return
}

;-------------------------------------------------------------------------
; LeftRandom
;-------------------------------------------------------------------------
; generate new random scene on the left:
; random' = random >> 1 | (bit4^bit5^bit6^bit0) * $80
; Taken from Atari 2600 Pitfall source code
;-------------------------------------------------------------------------
; On entry  : A contains duration
; On exit   : A contains 19
;           : X AND Y are underfined
;-------------------------------------------------------------------------
.LeftRandom
{
.loopRandom
    LDA random
    ASL A
    EOR random
    ASL A
    EOR random
    ASL A
    ASL A
    ROL A
    EOR random
    LSR A
    ROR random
    DEX
    BPL loopRandom

.^ContRandom
    LDA #OBJECT_XPOS        ; x-position of logs, fire, cobra or treasure
    STA xPosObject
    LDA random
    LSR A
    LSR A
    LSR A
    PHA
    AND #%111
    STA sceneType           ; bits 3..5
    PLA
    LSR A
    LSR A
    LSR A
    STA treePat             ; bits 6 & 7
    LDA random
    AND #%111
    STA objectType          ; bits 0..2
    LDX #HALF_SCREEN_WIDTH  ; center x-position of scorpion
    LDY #NOLADDER
    LDA sceneType
    CMP #HOLE3_SCENE+1      ; scene with hole(s)?
    BCS setFlag             ; no, skip
    LDY #WITHLADDER         ; yes, enable ladder
    LDX #WALL_LEFT          ; left wall x-position
    LDA random
    ASL A                   ; position of the wall? (bit 7)
    BCC setFlag             ; left, skip
    LDX #WALL_RIGHT         ; right wall x-position
.setFlag
    STY ladderFlag
    STX xPosScorpion        ; also used for wall position

    LDX sceneType
    LDA VineTable,X         ; Extra code for vine
    STA vineFlag

    LDA SwampTypeTable,X    ; Extra code for swamp
    STA swampFlag
    AND #QUICKSAND
    STA quickSandFlag

    LDA CrocoTab,x
    STA crocodileFlag       ; Mark flag
    BEQ noCrocos
    LDA #CROC_XPOS          ; x-position crocos
    STA xPosObject

    LDX objectType          ; Extra check for vine on crocs
    LDA VineTableCroc,X
    STA vineFlag

.noCrocos
    RTS
}

;------------------------------------------------------------------------------
; InitSound
;------------------------------------------------------------------------------
; On Entry : X = sfx index number
; On Exit  : A and Y are underfined, X is preserved
;------------------------------------------------------------------------------
.InitSound
{
    BIT soundFlag
    BPL exit

    LDA sfxAddrTableLow,  X : STA soundAddrPtr
    LDA sfxAddrTableHigh, X : STA soundAddrPtr+1

    JSR sn_chip_reset       ; Reset all sound channels

    LDA #1 : STA soundPlaying  ; play sound
.exit
    RTS
}

;------------------------------------------------------------------------------
; process_sound
;------------------------------------------------------------------------------
; On Entry : 
; On Exit  : 
;------------------------------------------------------------------------------
.process_sound
{
    TXA : PHA : TYA : PHA
    LDA soundPlaying
    BEQ exit                        ; sound not initialised

    ; packet length = 0 - 13 or FF (end of file marker)
    LDY #0
    LDA (soundAddrPtr),Y : TAX      ; read packet length
    BMI enD_of_tune

.get_next_byte

    INC soundAddrPtr                ; inc addr pointer low byte
    BNE skip_high_byte
    INC soundAddrPtr+1              ; inc addr pointer high byte

.skip_high_byte

    DEX
    BMI exit                        ; end of packet data

    LDA #%11111111 : STA sysVIADataDirectionRegA    

    LDA (soundAddrPtr),Y            ; Get byte from table

    JSR sn_chip_write
    BNE get_next_byte               ; Always branches

.enD_of_tune
    JSR sn_chip_reset

.exit
    PLA : TAY : PLA : TAX
    RTS
}

;------------------------------------------------------------------------------
; sn_chip_reset
;------------------------------------------------------------------------------
; On Entry :
; On Exit  :
;------------------------------------------------------------------------------
.sn_chip_reset
{
    LDA #0 : STA soundPlaying              ; Turn off sound
    LDA #%11111111 : STA sysVIADataDirectionRegA   

    ; Silence channels 0, 1, 2, 3
    LDA #%10011111 : JSR sn_chip_write  ; Channel 0
    LDA #%10111111 : JSR sn_chip_write  ; Channel 1
    LDA #%11011111 : JSR sn_chip_write  ; Channel 2
    LDA #%11111111 : JMP sn_chip_write  ; Channel 3 (Noise)
    ; return
}

;------------------------------------------------------------------------------
; sn_chip_write
;------------------------------------------------------------------------------
; On Entry :
; On Exit  : A = 8, X is underfined, Y is preserved
;------------------------------------------------------------------------------
.sn_chip_write
{
    STA sysVIAPortA                     ; place psg data on port a slow bus
    LDA #%00000000  : STA sysVIAPortB   ;
    PHA : PLA : NOP : NOP               ; 3+4+2+2 + 2(LDA #) = 16 clocks = 8us
    LDA #%00001000  : STA sysVIAPortB   ;
    RTS
}

;-------------------------------------------------------------------------

; Standard Mode 2 (20x32) character lookup table
.LookUp640Low
EQUB $00,$80,$00,$80,$00,$80,$00,$80
EQUB $00,$80,$00,$80,$00,$80,$00,$80
EQUB $00,$80,$00,$80,$00,$80,$00,$80
EQUB $00,$80,$00,$80,$00,$80,$00,$80

.LookUp640High
EQUB $30,$32,$35,$37,$3A,$3C,$3F,$41
EQUB $44,$46,$49,$4B,$4E,$50,$53,$55
EQUB $58,$5A,$5D,$5F,$62,$64,$67,$69
EQUB $6C,$6E,$71,$73,$76,$78,$7B,$7D

; AcornPad Build 1.0.9
; Mapset data... Compressed 5x3 (length x sprite no.)
.MapBaseLayer
EQUB $A1, $08, $9A, $08, $9A, $08, $9A, $08
EQUB $9A, $08, $9A, $08, $9A, $08, $9A, $08
EQUB $9A, $08, $9A, $08, $9A, $08, $9B, $08
EQUB $9B, $08, $9B, $08, $9B, $08, $9B, $08
EQUB $9B, $08, $9B, $08, $9B, $08, $9B, $08
EQUB $9C, $08, $0C, $8F, $0C, $08, $9D, $08
EQUB $9D, $08, $99, $08, $99, $08, $99, $08
EQUB $99, $08, $9E, $FF

.CrocoTab
EQUB $00,$00,$00,$00,$01,$00,$00,$00    ; 5 is $01 (Treasure scene)

.BoxTopText
EQUS "$---------%", $FF

.BoxBottomText
EQUS "^---------&", $FF

.WellDoneText
EQUS "|WELL DONE|", $FF

.GameOverText
EQUS "|GAME OVER|", $FF

.font_data
INCLUDE "Fonts.asm"
.font_data_end

.tile_data
INCBIN "../Sprites/Tiles.bin"
.tile_data_end

.leaves_data
INCBIN "../Sprites/Leaves.bin"

.sprite_data
INCBIN "../Sprites/Sprites.bin"
.sprite_data_end

.object_data
INCBIN "../Sprites/Objects.bin"
.object_data_end

.swamp_data
INCBIN "../Sprites/Swamp.bin"
.swamp_data_end

; Tile List
.spriteAddrTableLo
EQUB LO(tile_data + $00)
EQUB LO(tile_data + $20)
EQUB LO(tile_data + $40)   
EQUB LO(tile_data + $60)   
EQUB LO(tile_data + $80)   
EQUB LO(tile_data + $A0)   
EQUB LO(tile_data + $C0)   
EQUB LO(tile_data + $E0)   
EQUB LO(tile_data + $100)  
EQUB LO(tile_data + $120)  
EQUB LO(tile_data + $140)  
EQUB LO(tile_data + $160)  
EQUB LO(tile_data + $180)  
EQUB LO(tile_data + $1A0)                     
EQUB LO(leaves_data + $00) 
EQUB LO(leaves_data + $20) 
EQUB LO(leaves_data + $40) 
EQUB LO(leaves_data + $60) 
EQUB LO(leaves_data + $80) 
EQUB LO(leaves_data + $A0) 
EQUB LO(leaves_data + $C0) 
EQUB LO(leaves_data + $E0) 
EQUB LO(leaves_data + $100)
EQUB LO(leaves_data + $120)
EQUB LO(sprite_data)       
EQUB LO(sprite_data  + $58)
EQUB LO(sprite_data  + $B0)
EQUB LO(sprite_data  + $108)
EQUB LO(sprite_data  + $160)
EQUB LO(sprite_data  + $1B8)
EQUB LO(sprite_data  + $210)
EQUB LO(sprite_data  + $268)
EQUB LO(sprite_data  + $2C0)
EQUB LO(sprite_data  + $318)
EQUB LO(sprite_data  + $370)
EQUB LO(sprite_data  + $3C8)
EQUB LO(sprite_data  + $420)
EQUB LO(sprite_data  + $478)
EQUB LO(sprite_data  + $4D0)
EQUB LO(sprite_data  + $528)
EQUB LO(object_data + $00)  
EQUB LO(object_data + $40)  
EQUB LO(object_data + $80)  
EQUB LO(object_data + $C0)  
EQUB LO(object_data + $100) 
EQUB LO(object_data + $140) 
EQUB LO(object_data + $180) 
EQUB LO(object_data + $1C0) 
EQUB LO(object_data + $200) 
EQUB LO(object_data + $240) 
EQUB LO(object_data + $280) 
EQUB LO(object_data + $2C0) 
EQUB LO(object_data + $300) 
EQUB LO(object_data + $340) 
EQUB LO(object_data + $380) 
EQUB LO(object_data + $3C0) 
EQUB LO(swamp_data)              
EQUB LO(swamp_data + $28)        
EQUB LO(swamp_data + $50)        
EQUB LO(swamp_data + $78)        
EQUB LO(swamp_data + $A0)        
EQUB LO(swamp_data + $C8)        
EQUB LO(swamp_data + $F0)        
EQUB LO(swamp_data + $118)       
EQUB LO(swamp_data + $140)       
EQUB LO(swamp_data + $168)       
EQUB LO(swamp_data + $190)       
EQUB LO(swamp_data + $1B8)       
EQUB LO(swamp_data + $1E0)       
EQUB LO(swamp_data + $208)       
EQUB LO(swamp_data + $230)       

.spriteAddrTableHi
EQUB HI(tile_data + $00)
EQUB HI(tile_data + $20)
EQUB HI(tile_data + $40)
EQUB HI(tile_data + $60)
EQUB HI(tile_data + $80)
EQUB HI(tile_data + $A0)
EQUB HI(tile_data + $C0)
EQUB HI(tile_data + $E0)
EQUB HI(tile_data + $100)
EQUB HI(tile_data + $120)
EQUB HI(tile_data + $140)
EQUB HI(tile_data + $160)
EQUB HI(tile_data + $180)
EQUB HI(tile_data + $1A0)                        
EQUB HI(leaves_data + $00)
EQUB HI(leaves_data + $20)
EQUB HI(leaves_data + $40)
EQUB HI(leaves_data + $60)
EQUB HI(leaves_data + $80)
EQUB HI(leaves_data + $A0)
EQUB HI(leaves_data + $C0)
EQUB HI(leaves_data + $E0)
EQUB HI(leaves_data + $100)
EQUB HI(leaves_data + $120)
EQUB HI(sprite_data)       
EQUB HI(sprite_data  + $58)
EQUB HI(sprite_data  + $B0)
EQUB HI(sprite_data  + $108)
EQUB HI(sprite_data  + $160)
EQUB HI(sprite_data  + $1B8)
EQUB HI(sprite_data  + $210)
EQUB HI(sprite_data  + $268)
EQUB HI(sprite_data  + $2C0)
EQUB HI(sprite_data  + $318)
EQUB HI(sprite_data  + $370)
EQUB HI(sprite_data  + $3C8)
EQUB HI(sprite_data  + $420)
EQUB HI(sprite_data  + $478)
EQUB HI(sprite_data  + $4D0)
EQUB HI(sprite_data  + $528)
EQUB HI(object_data + $00)
EQUB HI(object_data + $40)
EQUB HI(object_data + $80)
EQUB HI(object_data + $C0)
EQUB HI(object_data + $100)
EQUB HI(object_data + $140)
EQUB HI(object_data + $180)
EQUB HI(object_data + $1C0)
EQUB HI(object_data + $200)
EQUB HI(object_data + $240)
EQUB HI(object_data + $280)
EQUB HI(object_data + $2C0)
EQUB HI(object_data + $300)
EQUB HI(object_data + $340)
EQUB HI(object_data + $380)
EQUB HI(object_data + $3C0)
EQUB HI(swamp_data)        
EQUB HI(swamp_data + $28)  
EQUB HI(swamp_data + $50)
EQUB HI(swamp_data + $78)
EQUB HI(swamp_data + $A0)
EQUB HI(swamp_data + $C8)
EQUB HI(swamp_data + $F0)
EQUB HI(swamp_data + $118)
EQUB HI(swamp_data + $140)
EQUB HI(swamp_data + $168)
EQUB HI(swamp_data + $190)
EQUB HI(swamp_data + $1B8)
EQUB HI(swamp_data + $1E0)
EQUB HI(swamp_data + $208)
EQUB HI(swamp_data + $230)

; the bounds of the holes and pits where Harry falls down:
.HoleBoundsTab
EQUB $24,$27,$00,$00,$00,$00,$00,$00   ; 0 - 1 hole
EQUB $16,$1C,$24,$27,$30,$36,$00,$00   ; 1 - 3 holes
EQUB $16,$36,$00,$00,$00,$00,$00,$00   ; 2 - 1 swamp / pit
EQUB $16,$1A,$20,$22,$28,$2A,$30,$36   ; 3 - closed crocs jaws
EQUB $16,$1E,$20,$26,$28,$2E,$30,$36   ; 4 - open crocs jaws

.MaskStoreDataAddressLo
EQUB LO(erase_table_addr + $000)  ; Player    XX00 - XX60 (60)
EQUB LO(erase_table_addr + $060)  ; Log 1     XX60 - XXB0 (50)
EQUB LO(erase_table_addr + $0B0)  ; Log 2     XXB0 - YY00 (50)
EQUB LO(erase_table_addr + $100)  ; Log 3     YY00 - YY50 (50)
EQUB LO(erase_table_addr + $150)  ; Scorpion  YY50 - YYA0 (50)
EQUB LO(erase_table_addr + $1A0)  ; Spare     YYA0 - YYF0 (50)

.MaskStoreDataAddressHi
EQUB HI(erase_table_addr + $000)  ; Player    XX00 - XX60 (60)
EQUB HI(erase_table_addr + $060)  ; Log 1     XX60 - XXB0 (50)
EQUB HI(erase_table_addr + $0B0)  ; Log 2     XXB0 - YY00 (50)
EQUB HI(erase_table_addr + $100)  ; Log 3     YY00 - YY50 (50)
EQUB HI(erase_table_addr + $150)  ; Scorpion  YY50 - YYA0 (50)
EQUB HI(erase_table_addr + $1A0)  ; Spare     YYA0 - YYF0 (50)

.sfxAddrTableLow
EQUB LO(sfxJumpAddr)
EQUB LO(sfxFallAddr)
EQUB LO(sfxVineAddr)
EQUB LO(sfxDeathAddr)
EQUB LO(sfxTreasureAddr)
EQUB LO(sfxCollisionAddr)
EQUB LO(sfxGameOverAddr)

.sfxAddrTableHigh
EQUB HI(sfxJumpAddr)
EQUB HI(sfxFallAddr)
EQUB HI(sfxVineAddr)
EQUB HI(sfxDeathAddr)
EQUB HI(sfxTreasureAddr)
EQUB HI(sfxCollisionAddr)
EQUB HI(sfxGameOverAddr)

; Leaves data code
.leaves_list
EQUB $00,$13,$26,$39

.LeavesTable
; 0
EQUB LEAVES04, LEAVES03, LEAVES10, LEAVES07
EQUB LEAVES02, LEAVES01, LEAVES07, LEAVES10, LEAVES04
EQUB LEAVES03, LEAVES10, LEAVES07, LEAVES02, LEAVES01
EQUB LEAVES07, LEAVES10, LEAVES04, LEAVES03, LEAVES10
;1
EQUB LEAVES08, LEAVES09, LEAVES04, LEAVES03
EQUB LEAVES06, LEAVES05, LEAVES04, LEAVES03, LEAVES08
EQUB LEAVES09, LEAVES04, LEAVES03, LEAVES06, LEAVES05
EQUB LEAVES04, LEAVES03, LEAVES08, LEAVES09, LEAVES04
;2
EQUB LEAVES04, LEAVES03, LEAVES02, LEAVES01
EQUB LEAVES05, LEAVES06, LEAVES02, LEAVES01, LEAVES04
EQUB LEAVES03, LEAVES02, LEAVES01, LEAVES05, LEAVES06
EQUB LEAVES02, LEAVES01, LEAVES04, LEAVES03, LEAVES02
;3
EQUB LEAVES03, LEAVES04, LEAVES00, LEAVES03
EQUB LEAVES08, LEAVES09, LEAVES04, LEAVES01, LEAVES03
EQUB LEAVES04, LEAVES02, LEAVES03, LEAVES08, LEAVES09
EQUB LEAVES04, LEAVES00, LEAVES03, LEAVES04, LEAVES00

.sfx_data
.sfxJumpAddr
INCBIN "..\sounds\jump.bin"

.sfxFallAddr
INCBIN "..\sounds\fall.bin"

.sfxVineAddr
INCBIN "..\sounds\vine.bin"

.sfxDeathAddr
INCBIN "..\sounds\death.bin"

.sfxTreasureAddr
INCBIN "..\sounds\treasure.bin"

.sfxCollisionAddr
INCBIN "..\sounds\collision.bin"

.sfxGameOverAddr
INCBIN "..\sounds\gameover.bin"

.sfx_data_end

.END

;-------------------------------------------------------------------------
; Relocation code must be on a page boundary
;-------------------------------------------------------------------------
ALIGN &100
.RELOC_START
{
    LDA #$8C
    LDX #$00
    LDY #$00
    JSR OSBYTE      ; Select cassette file system AND set speed

    LDX #$00
    LDA #$0B
    JSR OSBYTE      ; Turn off Auto Repeat vsync_delay

    LDA #0          ; get bbc model
	LDX #1
	JSR OSBYTE
	STX fx0         ; save machine type


    SEI             ; Disable interupts

    LDX #$FF        ; Initialise the stack
    TXS

    ; Relocate the code
    LDX #HI(RELOC_START - NATIVE_ADDR)
    LDY #0

.relocloop
    LDA RELOAD_ADDR,Y
    STA NATIVE_ADDR,Y
    INY
    BNE relocloop
    INC relocloop+OFFSET+2        ; PATCHED ADDRESS
    INC relocloop+OFFSET+5        ; PATCHED ADDRESS
    DEX
    BNE relocloop

    ; Set up CRTC for MODE 2
    LDY #13
.crtcloop
    STY crtcAddr
    LDA crtcregs + OFFSET,Y
    STA crtcData
    DEY
    BPL crtcloop

    LDA #$40 : STA nuLACtrl

    ; Set up video ULA for MODE 2
    LDA #$F4 : STA ulaMode

    ; Set up nuLA palette for MODE 2
    LDY #0
.nuLAloop
    LDA Video_nuLa_paldata + OFFSET,Y     : STA nuLAPalette
    LDA Video_nuLa_paldata + OFFSET + 1,Y : STA nuLAPalette
    INY
    INY
    CPY #32
    BNE nuLAloop

    ; Set up video ULA for MODE 2
    LDA #$F4 : STA ulaMode

    ; Set up palette for MODE 2
    LDY #15
.palloop
    LDA paldata + OFFSET,Y : STA ulaPalette
    DEY
    BPL palloop

    LDA #%01111111 : STA sysVIAInterruptEnableReg   ; R14=Interrupt Enable (disable all interrupts)
                   : STA sysVIADataDirectionRegA    ; R3=Data Direction Register "A" (set keyboard data direction)
    LDA #%11000000 : STA sysVIAInterruptEnableReg   ; R14=Interrupt Enable (enable timer interrupt)
    LDA #%11000000 : STA sysVIAAuxControlReg

    ; Set up Timer1 to start at the first scanline
    LDA #LO(Timer1Value) : STA sysVIATimer1CounterLow
    LDX #HI(Timer1Value) ; Hold Timer1CounterHigh

    LDA #%00000010 : STA sysVIAInterruptFlagReg
.vloop
    BIT sysVIAInterruptFlagReg
    BEQ vloop

    STX sysVIATimer1CounterHigh ; Set Timer1CounterHigh
    STA sysVIAInterruptFlagReg

    ; Latch T1 to interupt exactly every 50Hz frame
    LDA #LO(FramePeriod) : STA sysVIATimer1LatchLow
    LDA #HI(FramePeriod) : STA sysVIATimer1LatchHigh

    ; Alter ADCControl for Master System
    LDA fx0
    CMP #3          ; Master = 3
    BNE skipMasterADC
    
    ; BBC ADCControl = FEC0, Master ADCControl = FE18
    ; BBC ADCHigh    = FEC1, Master ADCHigh    = FE19
    ; BBC ADCLow     = FEC2, Master ADCLow     = FE1A (not used in this game)
    
    ; Alter low byte from C0 to 18 and C1 to 19
    LDA #LO(MasterADCControl) : STA ADCControlRead + 1 : STA ADCControlWrite + 1
    LDA #LO(MasterADCHigh)    : STA ADCHighRead + 1

.skipMasterADC

    CLI                 ; enable interupts

    JMP StartGame  ; Jump to the game entry point
}


;-------------------------------------------------------------------------
; Values of CRTC regs for MODE 2
; R12/R13 offset by 4 pixels to centre 19 column Pitfall display
; (8 pixels = 1 column)
;-------------------------------------------------------------------------
.crtcregs
EQUB 127            ; R0  horizontal total
EQUB 80             ; R1  horizontal displayed - shrunk a little
EQUB 99             ; R2  horizontal position
EQUB 40             ; R3  sync width
EQUB 38             ; R4  vertical total
EQUB 0              ; R5  vertical total adjust
EQUB 32             ; R6  vertical displayed
EQUB 34             ; R7  vertical position
EQUB 0              ; R8  interlace off
EQUB 7              ; R9  scanlines per row
EQUB 32             ; R10 cursor start ; 103
EQUB 8              ; R11 cursor end
EQUB HI(&3010/8)    ; R12 screen start address, high
EQUB LO(&3010/8)    ; R13 screen start address, low

;-----------------------------------------------------------------------------------------------------------------------------------------------------
; ula palette color values
;-----------------------------------------------------------------------------------------------------------------------------------------------------
.paldata
EQUB $00 + palBlack     ; Background
EQUB $10 + palRed       ; Trees
EQUB $20 + palGreen     ; Player Body
EQUB $30 + palYellow    ; Forest floor
EQUB $40 + palBlue      ; Payer legs
EQUB $50 + palMagenta   ; Player face
EQUB $60 + palCyan      ; Forest backdrop
EQUB $70 + palWhite     ; Vine, Scorpion score etc
EQUB $80 + palBlack     ; Black Tree Leaves
EQUB $90 + palRed       ; Wall
EQUB $A0 + palGreen     ; Green Tree Leaves
EQUB $B0 + palYellow    ; Yellow hatched earth
EQUB $C0 + palBlue      ; Blue swamp
EQUB $D0 + palGreen     ; Hide Vine in trees
EQUB $E0 + palGreen     ; Crocs
EQUB $F0 + palBlack     ; Hide Vine in trees

;-----------------------------------------------------------------------------------------------------------------------------------------------------
; Video nuLA palette color values
;-----------------------------------------------------------------------------------------------------------------------------------------------------
.Video_nuLa_paldata
EQUB $00, $00 ; Background
EQUB $16, $40 ; Trees
EQUB $24, $82 ; Player Body
EQUB $3C, $C3 ; Forest floor
EQUB $42, $6C ; Payer legs
EQUB $5F, $77 ; Player face
EQUB $6A, $F5 ; Forest backdrop
EQUB $7F, $FF ; Vine, Scorpion score etc   
EQUB $80, $00 ; Black Tree Leaves   
EQUB $9F, $00 ; Wall  
EQUB $A4, $82 ; Green Tree Leaves 
EQUB $BC, $C3 ; Yellow hatched earth
EQUB $C2, $6C ; Blue swamp  
EQUB $D4, $82 ; Hide Vine in trees
EQUB $EE, $30 ; Crocs 
EQUB $F0, $00 ; Hide Vine in trees   

;-------------------------------------------------------------------------
; End address to be saved
;-------------------------------------------------------------------------
.RELOC_END

;-------------------------------------------------------------------------
;    Save the code
;-------------------------------------------------------------------------
PRINT
PRINT "-----------------------------------------------------------------"
PRINT "Pitfall Memory Map"
PRINT "-----------------------------------------------------------------"
PRINT "End of ZP   : ", ~end_of_ZP
PRINT "Font Size   : ", ~(font_data_end-font_data)
PRINT "Tile Size   : ", ~(tile_data_end-tile_data)
PRINT "Sprite Size : ", ~(sprite_data_end-sprite_data)
PRINT "Object Size : ", ~(object_data_end-object_data)
PRINT "Pond Size   : ", ~(swamp_data_end-swamp_data)
PRINT "SFX Size    : ", ~(sfx_data_end-sfx_data)
PRINT "-----------------------------------------------------------------"
PRINT "Bytes Used  : ", ~(RELOC_END-NATIVE_ADDR)
PRINT "Bytes Free  : ", ~(SCREEN_ADDRESS - END)

PRINT "-----------------------------------------------------------------"
PRINT "NB Bytes Free before paged aligned sprite mask storage : ", ~(mask_table_addr - mask_table_start)
PRINT "-----------------------------------------------------------------"
PRINT
SAVE "PITFALL", NATIVE_ADDR, RELOC_END, RELOC_START+OFFSET, RELOAD_ADDR

puttext "BOOT", "!BOOT",&FFFF
putbasic "Loader.bas", "LOADER"
putfile "screen.bin","PITSCR",&3000

\\ run command line with this
\\ beebasm -v -i Pitfall.asm -do Pitfall.ssd -opt 3 -title PitfallV1


