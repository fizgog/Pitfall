\ ******************************************************************
\ *	Pitfall - Objects code
\ ******************************************************************

; 00 - Animation frame 1     %00000000
; 01 - Animation frame 2     %00000001

OBJECT_SPRITE_W = 8         ; object sprite width
OBJECT_SPRITE_H = 16        ; object sprite height

; Object frame rates
STATIC_FRAMERATE        = %11111111
ROLLING_LOG_FRAMERATE   = %00000010
COBRA_FRAMERATE         = %00000111
FIRE_FRAMERATE          = %00000100 
SILVER_BAR_FRAMERATE    = %00000100 
GOLD_BAR_FRAMERATE      = %00000100 

; 8, 16 and 32 pixel distance
ONE_COPY             = $01  ; 00000001 - 1 copy                                    
TWO_COPIES           = $0A  ; 00001010 - 2 copies close                               
THREE_COPIES         = $0B  ; 00001011 - 3 copies close                      
TWO_COPIES_MEDIUM    = $12  ; 00010010 - 2 copies medium                 
THREE_COPIES_MEDIUM  = $13  ; 00010011 - 3 copies medium                 
TWO_COPIES_WIDE      = $22  ; 00100010 - 2 copies wide       

; used to animate some of the hazards:
.ObjectFrameRateTable
EQUB ROLLING_LOG_FRAMERATE  ; one rolling log          
EQUB ROLLING_LOG_FRAMERATE  ; two rolling logs
EQUB ROLLING_LOG_FRAMERATE  ; two rolling logs
EQUB ROLLING_LOG_FRAMERATE  ; three rolling log
EQUB STATIC_FRAMERATE       ; one stationary logx
EQUB STATIC_FRAMERATE       ; three stationary log
EQUB FIRE_FRAMERATE         ; fire            
EQUB COBRA_FRAMERATE        ; cobra        
EQUB STATIC_FRAMERATE       ; money bag
EQUB SILVER_BAR_FRAMERATE   ; silver bar
EQUB GOLD_BAR_FRAMERATE     ; gold bar         
EQUB STATIC_FRAMERATE       ; ring
EQUB STATIC_FRAMERATE       ; nothing (treasure collected)

.ObjectSpriteTable
EQUB LOG_0
EQUB LOG_0
EQUB LOG_0
EQUB LOG_0
EQUB LOG_0
EQUB LOG_0
EQUB FIRE_0
EQUB COBRA_0
EQUB MONEY_BAG
EQUB BAR_0
EQUB BAR_0
EQUB RING
EQUB 0                      ; Not used 

; Max 12 objects
.Object_NUSIZ_Table
EQUB ONE_COPY
EQUB TWO_COPIES
EQUB TWO_COPIES_WIDE
EQUB THREE_COPIES_MEDIUM
EQUB ONE_COPY
EQUB THREE_COPIES
EQUB ONE_COPY
EQUB ONE_COPY
EQUB ONE_COPY
EQUB ONE_COPY
EQUB ONE_COPY
EQUB ONE_COPY
EQUB ONE_COPY

;-------------------------------------------------------------------------
; InitObjects
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.InitObjects
{
    LDA crocodileFlag    
    BNE exit                ; No objects on croco scene 

    LDX objectType

    LDA sceneType
    CMP #TREASURE_SCENE
    BNE NoTreasure

    JSR TreasureCollected
    BEQ withTreasure

    LDA #STATIC_FRAMERATE : STA objectFrameRate
    RTS  

.withTreasure
    LDA objectType
    AND #%00000011
    ORA #%00001000
    TAX

.NoTreasure    
    
    LDA ObjectFrameRateTable,X : STA objectFrameRate
    LDA ObjectSpriteTable,X    : STA objectSprite

    LDA Object_NUSIZ_Table,X
    PHA
    AND #%00000111 
    STA object_counter      ; bits 1, 2, 3
    PLA
    AND #%11111000
    STA object_distance     ; bits 4, 5, 6, 6, 7, 8

    LDA xPosObject     : STA object_x
    LDA #JUNGLE_GROUND : STA object_y

    ; Initialise object from 1 and up to 3
    JSR InitObjectGroups

    JMP DrawObjectSpritesSkipFrame
    ; return

.exit
    RTS
}

;-------------------------------------------------------------------------
; InitObjectGroups
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.InitObjectGroups
{
    LDY object_counter
.loop

    LDA object_x
    STA object_logs_x,Y
   
    CLC : ADC object_distance : STA object_x
    CMP #SCREENWIDTH
    BCC over
    CLC : SBC #79 : STA object_x

.over    
    DEY
    BNE loop
    RTS
}

;-------------------------------------------------------------------------
; EraseObjectSprites
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.EraseObjectSprites
{
    LDA crocodileFlag
    BNE exit                ; No objects on croco scene  

    LDA objectFrameRate
    BMI exit                ; No animated

.^EraseObjectSpritesSkipFrame

    LDA objectSprite : STA currentCharacter
    LDA object_y     : STA currentYPosition 

    LDY object_counter
.loop
    STY eraseCharacter

    LDA object_logs_x,Y : STA currentXPosition
    
    LDA #OBJECT_SPRITE_H : STA height
    LDA #OBJECT_SPRITE_W : STA width
    JSR EraseSpriteMask    
    DEY
    BNE loop
.exit
    RTS
}

;-------------------------------------------------------------------------
; UpdateObjectSprites
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.UpdateObjectSprites
{
    LDA crocodileFlag
    BNE exit                ; No objects on croco scene  

    LDA objectFrameRate
    BMI exit                ; Not animated
    
    DEC objectFrameRate
    BNE exit
    
    LDX objectType
    LDA sceneType
    CMP #TREASURE_SCENE
    BNE NoTreasure
    JSR CheckTreasures
    BEQ withTreasure

.withTreasure
    LDA objectType
    AND #%00000011
    ORA #%00001000
    TAX

.NoTreasure    
    LDA ObjectFrameRateTable,X : STA objectFrameRate

    CMP #STATIC_FRAMERATE
    BEQ exit

    ; Swap animation frame
    LDA objectControl : EOR #$01 : STA objectControl

    LDA objectControl
    AND #$03
    CLC
    ADC ObjectSpriteTable,X
    STA objectSprite

    LDX objectType
    CPX #ID_STATIONARY
    BCS exit
  
    LDA objectControl
    AND #$01
    BNE exit

    ; Rolling logs object
    JMP MoveLogs
    ; return
.exit
    RTS
}

;-------------------------------------------------------------------------
; MoveLogs
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.MoveLogs
{
    LDA #JUNGLE_GROUND : STA object_y

    LDY object_counter

    LDA object_logs_x,Y
    ASL A : ASL A : ASL A
    AND #$30
    CMP #$30
    AND #$10
    BEQ no_bounce
    INC object_y

.no_bounce

.loop
    LDA object_logs_x,Y : TAX
    BNE skip_reset
    LDX #SCREENWIDTH

.skip_reset
    DEX
    STX object_logs_x,Y

    DEY
    BNE loop
    RTS
}

;-------------------------------------------------------------------------
; DrawObjectSprites
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.DrawObjectSprites
{
    LDA crocodileFlag
    BNE exit            ; No objects on croco scene 

    LDA objectFrameRate
    BMI exit            ; Not animated

.^DrawObjectSpritesSkipFrame
             
    LDA objectSprite : STA currentCharacter
    LDA object_y     : STA currentYPosition 

    LDY object_counter
.loop
    STY eraseCharacter

    LDA object_logs_x,Y : STA currentXPosition
    
    LDA #OBJECT_SPRITE_H : STA height
    LDA #OBJECT_SPRITE_W : STA width
    
    LDA currentXPosition
    CMP #76
    BCS normal
    CMP #4
    BCC normal
    JSR PlotSpriteLogMask
    JMP next_sprite

.normal
    JSR PlotSpriteMask

.next_sprite 
    DEY
    BNE loop
.exit
    RTS
}

;-------------------------------------------------------------------------
; EraseTreasureObjectSprite
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.EraseTreasureObjectSprite
{
    LDA #STATIC_FRAMERATE : STA objectFrameRate
    JSR ErasePlayer
    JSR EraseObjectSpritesSkipFrame
    JMP DrawPlayer
    ; return
}
;-------------------------------------------------------------------------


