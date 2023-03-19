\ ******************************************************************
\ *	Pitfall - Vine code
\ ******************************************************************
;
; Thanks to ChrisB for help on the vine code

VINE_FRAMERATE  = %00000011
VINE_STARTX     = $20
VINE_STARTY     = $00
VINE_OFFSET_X   = $30
VINE_OFFSET_Y   = $20
VINE_MIN_X      = $16 
VINE_MAX_X      = $36          

LEFTPIXELMASK   = %00101010 ; $2A (flashing bits not required)
RIGHTPIXELMASK  = %00010101 ; $15 (flashing bits not required)
VOFFSET         = 13        ; Row below which start of rope is plotted

.PixelMaskData 
EQUB LEFTPIXELMASK		 
EQUB RIGHTPIXELMASK		

; Scene type 010, 011, 100 or 110 have a vine
.VineTable
EQUB $00, $00, $01, $01, $01, $00, $01, $00

; Object type 010, 011, 110 or 111 have a vine with crocs
.VineTableCroc
EQUB $00, $00, $01, $01, $00, $00, $01, $01

.VineTableLow
EQUB $40,$C0
.VineTableHigh
EQUB $5B,$5D

.VineTableX
EQUB $00, $02, $04, $06, $08, $0A, $0C, $0E
EQUB $10, $12, $14, $16, $18, $1A, $1C, $1E
EQUB $20, $22, $24, $26, $28, $2A, $2C, $2E
EQUB $30, $32, $34, $36, $38, $3A, $3C, $3F
EQUB $3F, $3C, $3A, $38, $36, $34, $32, $30
EQUB $2E, $2C, $2A, $28, $26, $24, $22, $20
EQUB $1E, $1C, $1A, $18, $16, $14, $12, $10
EQUB $0E, $0C, $0A, $08, $06, $04, $02, $00

.VineTableY
EQUB $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
EQUB $70, $71, $72, $73, $73, $74, $74, $74
EQUB $74, $74, $74, $73, $73, $72, $71, $70
EQUB $6F, $6E, $6D, $6C, $6B, $6A, $69, $68
EQUB $68, $69, $6A, $6B, $6C, $6D, $6E, $6F
EQUB $70, $71, $72, $73, $73, $74, $74, $74
EQUB $74, $74, $74, $73, $73, $72, $71, $70
EQUB $6F, $6E, $6D, $6C, $6B, $6A, $69, $68

;-------------------------------------------------------------------------
; InitVine
;-------------------------------------------------------------------------
; On entry  : vineFrame contains index into VineTable
; On exit   : A is underfined, X = vineFrame, Y is preserved
;------------------------------------------------------------------------- 
.InitVine
{
    LDA vineFlag            ; Don't show vine 
    BEQ exit                ; == 0

    LDX vineFrame
    LDA VineTableX,X : STA vx
    LDA VineTableY,X : STA vy

    JMP PlotVineNoFrame
    ; return
.exit
    RTS
}

;-------------------------------------------------------------------------
; UpdateVine
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
; Runs every vine framerate even if not on showing on screen
;------------------------------------------------------------------------- 
.UpdateVine
{
    LDA frameCnt
    AND #VINE_FRAMERATE
    BNE exit
    
    LDA #$00 : STA vineDirection

    INC vineFrame
    LDA vineFrame
    AND #%00111111      ; $3F (64 frames there and back)

    STA vineFrame
  
    TAX
    CMP #32             ; end of swing ?
    BCS going_right     ; yes so change direction
    
    INC vineDirection   ; 5 cycles
    BPL continue        ; 2 INC's take 10 cycles whereas this takes 5 + 2 = 7 cycles

.going_right
    DEC vineDirection

.continue
    LDA VineTableX,X : STA vx
    LDA VineTableY,X : STA vy    

.exit
    RTS
}

;-------------------------------------------------------------------------
; PlotVine
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.PlotVine
{
    LDA vineFlag            ; Don't show vine 
    BEQ exit                ; == 0

    LDA frameCnt
    AND #VINE_FRAMERATE
    BNE exit

.^PlotVineNoFrame
    LDX #VINE_STARTX 
    LDY #VINE_STARTY

    JMP DrawLine
    ; return

.exit
    RTS
}

;-------------------------------------------------------------------------
; DrawLine
;-------------------------------------------------------------------------
; Plot a single line in Mode 2
;-------------------------------------------------------------------------
; On entry  : X and Y are start position, vx and vy are end position
; On exit   : 
;-------------------------------------------------------------------------
; X pixels = 0-159, Y pixels = 0-255
;-------------------------------------------------------------------------
.DrawLine 
{   
    ; Calculate delta_y
    STY height
    LDA vy : CLC : SBC height : STA delta_y

    LSR A                       ; A = A / 2
    STA width                   ; Store A in width : [delta_y] / 2

    ; Calculate x direction and delta_x
    TXA                         ; Get X1 in A

    LDX #OP_INX : STX x_direction ; X_dir defaults to INX
    
    SEC 
    SBC vx

    BCS skip_x                  ; If vx >= x1 then A is already positive
    EOR #%11111111              ; two's compliment to make
    ADC #1                      ; it negative

    LDX #OP_DEX : STX x_direction ; Change x_dir to DEX
    
.skip_x     
    STA delta_x                 ; Store A in delta_x [X2 - X1]

    LDA vy

    AND #%00000111              ; AND with 7
    STA write_addr              ; Store in write_addr (Screen low byte)
    LDA vy                      ; Transfer Y to A
    LSR A : LSR A : LSR A       ; Calculate Y=(Y/8)
    TAY                         ; Y contains either 12 (0C) or 13 (0D) 

    CLC                         ; May have been bits set from shifts
    LDA write_addr              ; Add to the write_addr low byte
    ADC VineTableLow-VOFFSET,Y  ; Add the low byte of the lookup table
    STA write_addr              ; Store back in the write_addr low byte
    
    LDA #0                      ; Get write_addr (high byte)
    ADC VineTableHigh-VOFFSET,Y ; Add the high byte of the lookup table
    STA write_addr + 1          ; Store in the write_addr high byte

    LDX vx
    LDY vy
.loop   
    STX saveX                   ; Save X for later
    STY saveY                   ; Save Y for later

    TXA                         ; Transfer X to A
    AND #%11111110              ; Remove bottom bit
    ASL A : ASL A               ; Multiply by 4 
    TAY                         ; Store in Y - This is the offset along the line
    TXA                         ; Get x coordinate
    AND #%00000001              ; AND with 1
    TAX                         ; X contains index into PixelMaskData
    LDA PixelMaskData,X         ; get left or right pixel
    EOR (write_addr),Y          ; EOR with the screen
    STA (write_addr),Y          ; Write pixel to screen   

    LDX saveX                   ; Restore X
    LDA width : SEC : SBC delta_x : STA width
    BCS skip_x_move
    ADC delta_y : STA width

.x_direction
    INX                         ; self mod code, toggles between INX and DEX

.skip_x_move           
    LDY saveY                   ; Restore Y
    DEC write_addr              ; Decrement screen row
    TYA
    AND #%00000111              ; Check bottom 3 bits of display
    BNE nomoveuprow             ; If we are on the top of a character row move up a row

.moveuprow
    LDA write_addr              ; Decrement screen character row.
    SEC
    SBC #LO(640-8)              ; One screen row minus the 8 we've already taken off
    STA write_addr
    LDA write_addr+1
    SBC #HI(640-8)
    STA write_addr+1

.nomoveuprow
    DEY                         ; y_dir is always -1
    CPY #$3A                    ; Don't draw above the tree line
    BCS loop
    RTS
}

;-------------------------------------------------------------------------
; CheckVineHit
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.CheckVineHit
{
    ; Exit if no vine on screen
    LDA vineFlag
    BEQ exit

    ; Exit if already swinging
    LDA player_movement
    AND #PLAYER_SWINGING
    BNE exit

    ; Exit if not jumping
    LDA player_movement
    AND #PLAYER_JUMPING
    BEQ exit

    ; exit if underground
    LDA player_y
    CMP #JUNGLE_GROUND
    BCS exit

    ; exit if jump coming down as you can only catch the rope going up
    LDA player_jump_index
    CMP #16                     ; >= 16
    BCS exit

    ; exit if out of vine bounds
    LDA #VINE_MIN_X            
    CMP player_x        ; Harry left of min vine
    BCS exit            ; 
    LDA #VINE_MAX_X
    CMP player_x        ; Harry is right of max vine
    BCC exit            ;
    
    LDA delta_x : LSR A     ; Half delta_x
    
    LDX vineDirection
    BMI vine_left

    ; Uses vx - half of delta_x
    CLC : ADC #(VINE_STARTX+VINE_OFFSET_X) : STA width  ; temp value 1
    LDA vx : CLC : ADC #VINE_OFFSET_X : STA height      ; temp value 2
    JMP check_vine

.vine_left  
    ; Uses vx + half of delta_x
    CLC : ADC vx : ADC #VINE_OFFSET_X : STA height      ; temp value 2
    LDA vx : CLC : ADC #VINE_OFFSET_X : STA width       ; temp value 1

.check_vine
    LDA player_x : ASL A                    
    CMP height                              ; temp value 1                     
    BCS exit                                
    CLC : ADC #8                            ; player width                         
    CMP width                               ; temp value 2      
    BCC exit                                
 
.found
    LDA #PLAYER_SWINGING : STA player_movement
    LDX #sfxVine : JSR InitSound
    SEC
    RTS

.exit
    CLC
    RTS    
}
;------------------------------------------------------------------------- 


