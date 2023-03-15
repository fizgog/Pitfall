\ ******************************************************************
\ *	Pitfall - Scorpion code
\ ******************************************************************

; 00 - Moving right frame 1     %00000000
; 01 - Moving right frame 2     %00000001
; 10 - Moving left frame 1      %00000010
; 11 - Moving left frame 2      %00000011
; 80 - Waiting (no animation)   %10000000

SCORPION_FRAMERATE  = %00000111     ; Scorpion framerate - every 7th frame
SCORPION_SPRITE_W   = 8             ; Scorpion sprite width
SCORPION_SPRITE_H   = 16            ; Scorpion sprite height
SCORPION_ERASE_NO   = 4             ; Scorpion erase sprite number

;-------------------------------------------------------------------------
; InitScorpion
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.InitScorpion
{
    LDA #SCORPION_L_0      : STA scorpionSprite
    LDA #$01               : STA scorpionControl    ; left frame 1
    LDA #HALF_SCREEN_WIDTH : STA scorpion_x         ; scorpion xpos
    JMP DrawScorpionNoFrame
    ; return
}

;-------------------------------------------------------------------------
; EraseScorpion
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.EraseScorpion
{
    LDA ladderFlag   
    BMI exit                ; Scorpion cannot exist with ladder 

    LDA frameCnt
    AND #SCORPION_FRAMERATE
    BNE exit

.^EraseScorpionNoFrame
    LDA #SCORPION_ERASE_NO : STA eraseCharacter
    LDA scorpion_x         : STA currentXPosition
    LDA #UNDER_GROUND      : STA currentYPosition 
    LDA #SCORPION_SPRITE_H : STA height
    LDA #SCORPION_SPRITE_W : STA width
    
    JMP EraseSpriteMask
    ; return
.exit
    RTS
}

;-------------------------------------------------------------------------
; UpdateScorpion
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.UpdateScorpion
{
    LDA ladderFlag   
    BMI exit                ; Scorpion cannot exist with ladder    
  
    LDA frameCnt
    AND #SCORPION_FRAMERATE
    BNE exit
   
.AnimateScorpion
    LDA scorpionControl
    EOR #$01
    STA scorpionControl
    AND #$80
    BNE ScorpionWaiting

.scorpionMoving
    LDA scorpionControl
    AND #$02
    BNE scorpionMovingLeft

    INC scorpion_x
    BPL scorpionContinue

.scorpionMovingLeft    
    DEC scorpion_x

.scorpionContinue
    LDA scorpionControl
    AND #$03
    CLC
    ADC #SCORPION_R_0
    STA scorpionSprite

.ScorpionWaiting 
    LDA scorpion_x
    CMP player_x
    BNE UpdateControl

    LDA #$80                
    STA scorpionControl 
    RTS

.UpdateControl
    BCC UpdateControlRight
    LDA scorpionControl
    ORA #$02
    AND #$03
    STA scorpionControl
    RTS

.UpdateControlRight
    LDA scorpionControl
    AND #$01
    STA scorpionControl

.exit
    RTS
}

;-------------------------------------------------------------------------
; DrawScorpion
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.DrawScorpion
{
    LDA ladderFlag   
    BMI exit                ; Scorpion cannot exist with ladder 

    LDA frameCnt
    AND #SCORPION_FRAMERATE
    BNE exit

.^DrawScorpionNoFrame

    LDA #SCORPION_ERASE_NO : STA eraseCharacter 
    LDA scorpionSprite     : STA currentCharacter
    LDA scorpion_x         : STA currentXPosition
    LDA #UNDER_GROUND      : STA currentYPosition 
    LDA #SCORPION_SPRITE_H : STA height
    LDA #SCORPION_SPRITE_W : STA width
    
    JMP PlotSpriteMask
    ; return
.exit
    RTS
}
;------------------------------------------------------------------------- 
