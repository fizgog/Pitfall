\ ******************************************************************
\ *    Pitfall - Swamp code
\ ******************************************************************

SWAMP_XSTART    = 24
SWAMP_YSTART    = 164
SWAMP_SPRITE_W  = 8
SWAMP_SPRITE_H  = 10

QUICKSAND_FRAME = %00000100

NONE            = $00000000 
BLACKSWAMP      = %00000010
BLUESWAMP       = %00000100 
CROCODILES      = %00100000
TREASURE        = %01000000 
QUICKSAND       = %10000000 

.SwampTypeTable
EQUB NONE                                   ; one hole
EQUB NONE                                   ; three holes
EQUB BLACKSWAMP                             ; tar pit
EQUB BLUESWAMP                              ; swamp
EQUB BLUESWAMP OR CROCODILES                ; swamp with crocodiles
EQUB QUICKSAND OR BLACKSWAMP  OR TREASURE   ; black quickSand with treasure
EQUB QUICKSAND OR BLACKSWAMP                ; black quickSand
EQUB QUICKSAND OR BLUESWAMP                 ; blue quickSand

; Atari 2600 code
.quickSandTab
EQUB %00000000 ; |        | 0
EQUB %00001111 ; |    XXXX| 1
EQUB %00001111 ; |    XXXX| 2
EQUB %00000000 ; |        | 3
EQUB %00001111 ; |    XXXX| 4
EQUB %10000000 ; |X       | 5

.SwampTable
EQUB POND00, POND00, POND00, POND00, POND00, POND00, POND00, POND00 ; Animation 1
EQUB POND00, POND00, POND00, POND14, POND15, POND00, POND00, POND00 ; Animation 2
EQUB POND00, POND00, POND01, POND06, POND07, POND01, POND00, POND00 ; Animation 3
EQUB POND00, POND01, POND02, POND08, POND09, POND02, POND01, POND00 ; Animation 4
EQUB POND14, POND02, POND03, POND12, POND13, POND03, POND02, POND15 ; Animation 5
EQUB POND06, POND03, POND04, POND10, POND11, POND04, POND03, POND07 ; Animation 6

.quickSandAnimationTable
EQUB $05, $04, $03, $02, $01, $00

.quickSandSizeTable
EQUB $00, $02, $08, $0C, $0E, $10

;-------------------------------------------------------------------------
; InitSwamp
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.InitSwamp
{
    LDA swampFlag
    BEQ exit

    LDX #$C0 + palBlue

    LDA swampFlag
    AND #BLUESWAMP
    CMP #BLUESWAMP
    BEQ not_tarpit

    LDX #$C0 + palBlack

.not_tarpit
    STX ulaPalette

    LDA quickSandFlag
    BNE over

    LDA #$05 : STA quickSandFrame
    LDA #$00 : STA xPosQuickSand
    JMP DrawQuickSandNoFrame

.over    
    LDA #$00 : STA quickSandFrame
    LDA #$10 : STA xPosQuickSand

    JSR CalcQuickSandSize
    JMP DrawQuickSandNoFrame
    ; return
.exit    
    RTS
}

;-------------------------------------------------------------------------
; UpdateQuickSand
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.UpdateQuickSand
{
    LDA #0 : STA quickSandAnimateFlag
    
    LDA quickSandFlag
    BEQ exit

    LDA player_movement
    CMP #PLAYER_FALLING     ; Don't update quickSand if player is falling
    BEQ exit                ; unless PLAYER_KILLED is also set

    ; frameCnt BC - FF it's always animation frame 5
    LDA frameCnt : CMP #$BD : BCS exit

    ; frameCnt 18 - A7 is always FF need to use 19 - A7 frame 0
    CMP #$18 : BCC over
    CMP #$A7 : BCC exit
    
.over    
    AND #QUICKSAND_FRAME
    CMP #QUICKSAND_FRAME
    BNE exit

 .^CalcQuickSandSize  

    LDA frameCnt                    ;
    LSR A : LSR A                   ; 
    TAY                             ; y = framecount / 4
    LSR A : LSR A : LSR A : LSR A   ;
    TAX                             ; x = framecount / 64
    TYA                             ; 
    AND quickSandTab+2,X            ; calculate size of the quickSand pit
    EOR quickSandTab,X              ; using data from Atari 2600
    CMP #$06                        ; 0 to 5 frames only
    BCS exit

    TAY                             ; Transfer A (0-5) to Y 
    LDA quickSandAnimationTable,Y   ; Load animation frame
    STA quickSandFrame              ; Store Animation Frame
    LDA quickSandSizeTable,Y        ; Load quickSand size
    STA xPosQuickSand               ; Store it

    LDA #1 : STA quickSandAnimateFlag

.exit    
    RTS
}

;-------------------------------------------------------------------------
; DrawQuickSand
;-------------------------------------------------------------------------
; On entry  : 
; On exit   : 
;-------------------------------------------------------------------------
.DrawQuickSand
{
    LDA quickSandAnimateFlag
    BEQ exit

.^DrawQuickSandNoFrame
    LDA #SWAMP_XSTART : STA currentXPosition
    LDA #SWAMP_YSTART : STA currentYPosition
    
    LDA quickSandFrame
    ASL A : ASL A : ASL A
    TAX                         ; Index position into SwampTable

    LDY #8                      ; 8 sprites to show swamp
    
.loop
    LDA SwampTable,X    
    STA currentCharacter
    
    LDA #SWAMP_SPRITE_H : STA height
    LDA #SWAMP_SPRITE_W : STA width
    
    JSR PlotSprite
    INX
    
    ; Move to next x location
    LDA currentXPosition : CLC : ADC #4 : STA currentXPosition

    DEY
    BNE loop
.exit
    RTS
}
;-------------------------------------------------------------------------


