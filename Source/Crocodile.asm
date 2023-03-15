\ ******************************************************************
\ *	Pitfall - Crocodile code
\ ******************************************************************

; 00 - Animation frame 1     %00000000
; 01 - Animation frame 2     %00000001

CROCODILE_FRAMERATE     = %01111111 ; Croc framerate between snaps
MAX_CROCODILES          = 3         ; Number of crocs in the scene
CROC_XPOS               = 30        ; Start x position crocos
CROC_SPRITE_W           = 8         ; Width of croc sprite
CROC_SPRITE_H           = 16        ; Height of croc sprite
CROC_DISTANCE           = 8         ; Distance between crocs

;-------------------------------------------------------------------------
; InitCrocodiles
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.InitCrocodile
{
    LDA crocodileFlag
    BEQ exit                ; No objects on croco scene 

    LDA #CROC_0    : STA crocodileSprite
    LDA #$00       : STA crocodileControl
    LDA #CROC_XPOS : STA crocodile_x
    JMP DrawCrocodilesNoFrame
    ; return

.exit
    RTS
}

;-------------------------------------------------------------------------
; EraseCrocodiles
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.EraseCrocodiles
{
    LDA crocodileFlag
    BEQ exit                ; No objects on croco scene 

    LDA frameCnt
    AND #CROCODILE_FRAMERATE
    BNE exit

    LDA crocodileSprite : STA currentCharacter
    LDA crocodile_x     : STA currentXPosition
    LDA #JUNGLE_GROUND  : STA currentYPosition 
    LDA #CROC_DISTANCE  : STA object_distance

    LDY #MAX_CROCODILES
.loop
    STY eraseCharacter  
    LDA #CROC_SPRITE_H : STA height
    LDA #CROC_SPRITE_W : STA width
    JSR EraseSpriteMask 

    LDA currentXPosition : CLC : ADC object_distance : STA currentXPosition
    DEY
    BNE loop
.exit
    RTS
}

;-------------------------------------------------------------------------
; UpdateCrocodiles
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.UpdateCrocodiles
{
    LDA crocodileFlag  
    BEQ exit                ; No objects on croco scene     
   
    LDA frameCnt
    AND #CROCODILE_FRAMERATE
    BNE exit
 
.AnimateCrocodile
    LDA crocodileControl
    EOR #$01
    STA crocodileControl
    
    LDA #CROC_0 : CLC : ADC crocodileControl : STA crocodileSprite

.exit
    RTS
}

;-------------------------------------------------------------------------
; DrawCrocodiles
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.DrawCrocodiles
{
    LDA crocodileFlag
    BEQ exit                ; No objects on croco scene 

    LDA frameCnt
    AND #CROCODILE_FRAMERATE
    BNE exit

.^DrawCrocodilesNoFrame    
    
    LDA crocodileSprite : STA currentCharacter
    LDA crocodile_x     : STA currentXPosition
    LDA #JUNGLE_GROUND  : STA currentYPosition 
    LDA #CROC_DISTANCE  : STA object_distance

    LDY #MAX_CROCODILES
.loop
    STY eraseCharacter  
    LDA #CROC_SPRITE_H : STA height
    LDA #CROC_SPRITE_W : STA width

    JSR PlotSpriteLogMask

    LDA currentXPosition : CLC : ADC object_distance : STA currentXPosition
    DEY
    BNE loop
.exit
    RTS
}

;-------------------------------------------------------------------------
