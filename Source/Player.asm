;-------------------------------------------------------------------------
; Pitfall = Player.asm
;-------------------------------------------------------------------------

PLAYER_FRAMERATE            = %00000011 ; Player framerate (every 3 frames) 
PLAYER_CLIMBING_FRAMERATE   = %00000110 ; Playing climbing framerate (every 6 frames)
PLAYER_ERASE_NO             = 0         ; Player erase sprite number

PLAYER_WIDTH                = 8         ; Player sprite width
PLAYER_HEIGHT               = 22        ; Player sprite height

PLAYER_STANDING             = %00000000
PLAYER_KNEELING             = %00000001
PLAYER_RUNNING              = %00000010
PLAYER_JUMPING              = %00000100
PLAYER_CLIMBING             = %00001000
PLAYER_FALLING              = %00010000
PLAYER_SWINGING             = %00100000
PLAYER_ON_LADDER            = %01000000
PLAYER_KILLED               = %10000000

JUMP_LENGTH                 = 32        ; Total animation frames for player jump

; Following taken from Atari 2600 version for accurate jumping
.JumpTable
EQUB  1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1    ; going up
EQUB -1, 0, 0, 0,-1, 0, 0,-1, 0,-1,-1,-1,-1,-1,-1,-1    ; coming down

.InitPlayer
{
    JSR PlayerStanding
    JMP DrawPlayer
    ; return
}

;-------------------------------------------------------------------------
; UpdatePlayer
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.UpdatePlayer
{
    LDA player_movement
    AND #PLAYER_KNEELING
    BNE continue            ; Player is kneeling

    LDA player_movement
    AND #PLAYER_FALLING
    BNE continue            ; Player is falling

    LDA player_y
    CMP #PLAYER_JUNGLE_KNEELING
    BNE continue

    LDA #PLAYER_JUNGLE_GROUND : STA player_y

.continue

    ; NB Falling and jumping run every frame
    LDA player_movement
    AND #PLAYER_FALLING
    BEQ not_falling
    JMP PlayerFalling
    
.not_falling
    LDA player_movement
    AND #PLAYER_JUMPING
    BEQ not_jumping
    JMP PlayerJumping
    
.not_jumping
    LDA player_movement
    AND #PLAYER_SWINGING
    BEQ not_swinging
    JMP PlayerSwinging

.not_swinging

    LDA frameCnt          ; vsync runs 50 frames a second 
    AND #PLAYER_FRAMERATE ; every 3 frames update the player
    CMP #PLAYER_FRAMERATE
    BEQ over
    CLC
    RTS

.over    
    ; Remove all movements apart from player on ladder or player kneeling
    LDA player_movement : AND #(PLAYER_ON_LADDER OR PLAYER_KNEELING) : STA player_movement    
    LDA #$00 : STA player_dx : STA player_dy    ; Reset dx and dy

.player_up
    LDA player_movement
    AND #PLAYER_KNEELING
    BNE player_left        ; Cannot climb and kneel at the same time

    LDA playerInput
    AND #KEYPRESS_UP
    BEQ player_down
  
    LDA player_movement : ORA #PLAYER_CLIMBING : STA player_movement    ; Remove all momentments apart from on ladder 
    LDA #$FC : STA player_dy    ; Move up 4 pixels
    
    JMP PlayerClimbing
      
.player_down
    LDA player_movement
    AND #PLAYER_KNEELING
    BNE player_left        ; Cannot climb and kneel at the same time

    LDA playerInput
    AND #KEYPRESS_DOWN
    BEQ player_left

    LDA player_movement : ORA #PLAYER_CLIMBING : STA player_movement    ; Remove all momentments apart from on ladder
    LDA #$04 : STA player_dy    ; Move down 4 pixels
    
    JMP PlayerClimbing
    
.player_left   
    LDA playerInput
    AND #KEYPRESS_LEFT
    BEQ player_right
    
    LDA player_movement : ORA #PLAYER_RUNNING : STA player_movement
    DEC player_dx
    
    ; Don't call PlayerRunning as we might want to jump left

.player_right
    LDA playerInput
    AND #KEYPRESS_RIGHT
    BEQ player_jump
    
    LDA player_movement : ORA #PLAYER_RUNNING : STA player_movement
    INC player_dx

    ; Don't call PlayerRunning as we might want to jump right

.player_jump
    LDA player_movement
    AND #(PLAYER_ON_LADDER OR PLAYER_KNEELING)
    BNE player_move         ; Cannot (climb or kneel) and jump at the same time
    
    LDA playerInput
    AND #KEYPRESS_JUMP
    BEQ player_move         ; Not jumping
    
    LDA player_movement : ORA #PLAYER_JUMPING : STA player_movement
    LDX #sfxJump : JSR InitSound
    LDA #1 : STA player_jump_index
    JMP PlayerJumping
    
.player_move

    LDA player_movement
    AND #PLAYER_KNEELING
    CMP #PLAYER_KNEELING
    BNE running
    JMP PlayerKneeling

.running
    LDA player_movement
    AND #PLAYER_RUNNING
    CMP #PLAYER_RUNNING
    BNE climbing
    JMP PlayerRunning
    
.climbing    
    LDA player_movement
    AND #PLAYER_ON_LADDER
    CMP #PLAYER_ON_LADDER
    BEQ exit

.standing
    JMP PlayerStanding
    ; return

.exit
    CLC
    RTS
}

;-------------------------------------------------------------------------
; PlayerStanding
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PlayerStanding
{
    ; Update left / right standing animation
    LDA #HARRY_R_5
    LDX player_direction
    BPL facing_correct_direction

    LDA #HARRY_L_5

.facing_correct_direction
    STA playerCurrentSprite
.exit
    RTS
}

;-------------------------------------------------------------------------
; PlayerKneeling
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PlayerKneeling
{
    LDA player_x : CLC : ADC player_dx : STA player_x
    LDA #PLAYER_JUNGLE_KNEELING : STA player_y

    ; Update left / right kneeling animation
    LDA #HARRY_R_4
    LDX player_direction
    BPL facing_correct_direction

    LDA #HARRY_L_4

.facing_correct_direction
    STA playerCurrentSprite
.exit
    CLC
    RTS
}

;-------------------------------------------------------------------------
; PlayerRunning
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PlayerRunning
{
    LDA player_movement
    AND #PLAYER_ON_LADDER
    CMP #PLAYER_ON_LADDER
    BNE not_climbing
    
    JMP JumpUpFromLadder
    ; return
    
.not_climbing   

    ; Check for running into a new scene
    JSR CheckForNewScene
    BCS exit
    
    JSR CheckWallCollision
    BCS hit_wall

    LDA player_x : CLC : ADC player_dx : STA player_x

.hit_wall    
    LDA player_dx : STA player_direction
    INC player_animation_frame
    LDA player_animation_frame
    CMP #5
    BCC animation_not_reset
    LDA #0
    STA player_animation_frame
    
.animation_not_reset
    LDA #HARRY_R_0
    LDX player_direction
    BPL facing_correct_direction
    LDA #HARRY_L_0
    
.facing_correct_direction
    CLC : ADC player_animation_frame : STA playerCurrentSprite

.exit
    RTS
}

;-------------------------------------------------------------------------
; PlayerClimbing
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PlayerClimbing
{
    LDA ladderFlag
    BPL exit

    LDA player_movement
    AND #PLAYER_ON_LADDER
    CMP #PLAYER_ON_LADDER
    BEQ on_ladder

    JSR LocateLadder
    BCC exit
    
    ; Set on player on ladder flag
    LDA player_movement : ORA #PLAYER_ON_LADDER : STA player_movement
    ; Reset animation frame
    LDA #0 : STA player_animation_frame : STA player_dy
    ; Set player_x to centre of ladder
    LDA #38 : STA player_x
    BNE continue_climbing

.on_ladder
    LDA player_dy
    BPL climbing_down
    
.climbing_up
    LDA player_y
    CMP #LADDER_YPOS1
    BCS continue_climbing
    ; Reached top of ladder so do nothing
    RTS
    
.climbing_down
    LDA player_y
    CMP #LADDER_YPOS2 - 25
    BCC continue_climbing
    
    ; reached bottom of the ladder so get off
    LDA player_movement : EOR #PLAYER_ON_LADDER : STA player_movement
    JMP PlayerStanding
    ; return
    
.continue_climbing

    LDA player_y : CLC : ADC player_dy : STA player_y
    
    ; Toggle climbing left / right animation 0 or 1
    LDA player_animation_frame : EOR #$01 : STA player_animation_frame
    
    CLC : ADC #HARRY_R_7 : STA playerCurrentSprite
.exit    
    CLC
    RTS
}

;-------------------------------------------------------------------------
; PlayerJumping
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PlayerJumping
{
    LDX player_jump_index
    BEQ end_jump

    ; Check for jumping into a new scene
    JSR CheckForNewScene
    BCS exit
    
    LDA frameCnt          ; vsync runs 50 frames a second 
    AND #PLAYER_FRAMERATE ; every 3 frames update the player xpos
    CMP #PLAYER_FRAMERATE
    BNE over

    LDA player_x : CLC : ADC player_dx : STA player_x
.over
    LDX player_jump_index
    LDA player_y : SEC : SBC JumpTable-1,X : STA player_y
    INC player_jump_index
    LDA player_jump_index
    CMP #JUMP_LENGTH+1
    BCC indexOk
    
    LDA #JUMP_LENGTH : STA player_jump_index
    
.indexOk    

    JSR CheckWallCollision
    BCC wall_not_hit
    
    ; Reverse player direction
    LDA player_dx : EOR #$FF : ORA #$01 : STA player_dx : STA player_direction
    
.wall_not_hit
    LDA player_dx : STA player_direction
    
    LDA #HARRY_R_4
    LDX player_direction
    BPL facing_correct_direction    ; Branch if direction is positive
    LDA #HARRY_L_4

.facing_correct_direction
    STA playerCurrentSprite

    LDA player_y
    CMP #PLAYER_JUNGLE_GROUND       ; Harry at jungle ground?
    BEQ end_jump

    CMP #PLAYER_UNDER_GROUND
    BEQ end_jump
    RTS
    
.end_jump
    LDA #0 : STA player_jump_index
    LDA player_movement : EOR #PLAYER_JUMPING : STA player_movement
    ;JSR PlayerStanding
    ;LDA #0 : STA playerInput
    CLC
.exit
    RTS

}

;-------------------------------------------------------------------------
; PlayerSwinging
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PlayerSwinging
{
    LDA playerInput
    AND #KEYPRESS_DOWN
    BEQ continue

.jump_down
    LDA #PLAYER_JUMPING : STA player_movement
    LDA vineDirection : STA player_dx : STA player_direction
    LDA #16 : STA player_jump_index ; jump index >15 coming down

    LDA #HARRY_R_0
    LDX player_direction
    BPL correct_face
    LDA #HARRY_L_0
    
.correct_face    
    STA playerCurrentSprite
    JMP PlayerJumping

.continue
    ; Calculate player x and y position
    LDA vx : CLC : ADC #VINE_OFFSET_X : LSR A : SBC #1 : STA player_x
    LDA vy : CLC : ADC #VINE_OFFSET_Y : SBC #4 : STA player_y

    ; Update left / right animation
    LDA #HARRY_R_6
    LDX player_direction
    BPL facing_correct_direction

    LDA #HARRY_L_6

.facing_correct_direction
    STA playerCurrentSprite
.exit
    CLC
    RTS
}

;-------------------------------------------------------------------------
; PlayerFalling
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.PlayerFalling
{
    ;JSR DebugCode

    LDA player_y
    CMP #PLAYER_JUNGLE_GROUND - 1
    BCC keep_falling
    BEQ finish
    
    CMP #PLAYER_UNDER_GROUND - 1
    BCC keep_falling

.finish
    LDA player_movement : EOR #PLAYER_FALLING : STA player_movement
    LDA player_y : CLC : ADC #1 : STA player_y
    BNE over

.keep_falling
    LDA player_y : CLC : ADC #1 : STA player_y
    CMP #$40
    BEQ kick

    CMP #$B0
    BNE over

 .kick
    ; Do a little kick when falling so far down
    LDA #HARRY_R_4
    LDX player_direction
    BPL facing_correct_direction    ; Branch if direction is positive
    LDA #HARRY_L_4

.facing_correct_direction
    STA playerCurrentSprite

.over    
    CLC
    RTS
}

;-------------------------------------------------------------------------
; LocateLadder
;-------------------------------------------------------------------------
; On entry  :
; On exit   : Carry set if ladder found 
;-------------------------------------------------------------------------
.LocateLadder
{
    LDA player_dy
    BPL exit
        
    LDA player_x
    CMP #LADDER_XPOS1
    BCC exit
    CMP #LADDER_XPOS2
    BCS exit
        
    SEC
    RTS
        
.exit
    CLC
    RTS
}

;-------------------------------------------------------------------------
; JumpUpFromLadder
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.JumpUpFromLadder
{
    LDA player_y
    CMP #LADDER_YPOS1
    BCS exit                ; Not at the top of the ladder
    
    LDA #PLAYER_JUNGLE_GROUND : STA player_y
    LDA player_movement : ORA #PLAYER_JUMPING : EOR #PLAYER_ON_LADDER : STA player_movement ; Add jumping to left / right movement
    LDA player_dx : STA player_direction
    LDA #1 : STA player_jump_index
    
    LDA #HARRY_R_0
    LDX player_direction
    BPL correct_face
    LDA #HARRY_L_0
    
.correct_face    
    STA playerCurrentSprite
    JMP PlayerJumping
    
.exit    
    CLC
    RTS
}

;-------------------------------------------------------------------------
; CheckWallCollision
;-------------------------------------------------------------------------
; On entry  :
; On exit   : Carry set if collided with wall
;------------------------------------------------------------------------- 
.CheckWallCollision
{
    LDA ladderFlag      ; Ladder is not in the scene so there is no wall
    BEQ exit
    
    LDA player_y
    CMP #JUNGLE_GROUND
    BCC exit            ; Not underground
    
    LDA player_x : CLC : ADC player_dx
    CMP #$06            
    BCC exit            ; far left of the wall
    CMP #$48
    BCS exit            ; far right of the wall
    
    LDA xPosScorpion : CMP #$28 : BCC LeftWall
   
    ; Check Right inner wall
    LDA player_x : CLC : ADC player_dx
    CMP #$42
    BCS found
    BCC exit

.LeftWall
    ; Check Left inner wall
    LDA player_x : CLC : ADC player_dx
    CMP #$0C
    BCS exit

.found
    SEC
    RTS
    
.exit    
    CLC
    RTS
}

;-------------------------------------------------------------------------
; CheckBounds
;-------------------------------------------------------------------------
; On entry  :
; On exit   : Carry set if player has entered bounds area
;------------------------------------------------------------------------- 
.CheckBounds
{
    ; No bounds on lower level
    LDA player_y
    CMP #PLAYER_JUNGLE_GROUND
    BNE exitBounds
    
    LDX sceneType
    CPX #CROCO_SCENE
    BNE no_crocs

    LDA crocodileControl
    BEQ cont_crocs
    DEX
    BNE cont_crocs

.no_crocs
    ; Scenes >= 5 use bounds 2 minus xposquicksand
    CPX #3
    BCC cont_crocs
    LDX #2

.cont_crocs
    TXA
    ASL A : ASL A : ASL A
    TAX

    LDY #3
.loopBounds

    LDA HoleBoundsTab,X  
    BEQ exitBounds          ; no more bounds!
    
    CLC                     
    ADC xPosQuickSand    
    
    CMP player_x            ; Harry left of hole/pit?
    BCS inBounds            ; yes, bound ok
    LDA HoleBoundsTab+1,X
    
    SEC                     
    SBC xPosQuickSand    
    
    CMP player_x            ; Harry right of hole/pit?
    BCS falling             ; no, Harry is falling into

.inBounds
    INX                    
    INX                    
    DEY                     
    BPL loopBounds      
    BMI exitBounds      

.falling

    LDA swampFlag
    BNE drowning
    
    JSR ReduceScore100
    JSR PrintScore
    LDX #sfxFall : JSR InitSound

.drowning    
    LDA #PLAYER_FALLING : STA player_movement
    JSR PlayerStanding

.continue_falling    
    SEC
    RTS

.exitBounds
    CLC
    RTS
}

;-------------------------------------------------------------------------
; CheckForNewScene
;-------------------------------------------------------------------------
; On entry  :
; On exit   : Carry set if player has triggered a new scene
;------------------------------------------------------------------------- 
.CheckForNewScene
{
    LDA player_x : CLC : ADC player_dx
    CMP #XMIN_HARRY
    BCC going_left
    CMP #XMAX_HARRY + 1
    BCS going_right

    ; not a new scene so just exit    
    CLC
    RTS

.going_left
    LDA #XMAX_HARRY : STA player_x
    
    LDX #0            ; Travel 1 scene
    LDA player_y
    CMP #JUNGLE_GROUND
    BCC over_left
    LDX #2            ; Travel 3 scenes

.over_left
    JSR LeftRandom
    BPL update_scene    ; Always positive from LeftRandom

.going_right
    LDA #XMIN_HARRY : STA player_x
    LDX #0
    LDA player_y
    CMP #JUNGLE_GROUND 
    BCC over_right
    LDX #2

.over_right
    JSR RightRandom

.update_scene
    LDX #$15
    LDY #$0B
    JSR DrawScreen
    SEC
    RTS
}

;-------------------------------------------------------------------------
; ErasePlayer
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.ErasePlayer
{
    LDA #PLAYER_ERASE_NO : STA eraseCharacter
    LDA player_x         : STA currentXPosition
    LDA player_y         : STA currentYPosition
    LDA #PLAYER_HEIGHT   : STA height
    LDA #PLAYER_WIDTH    : STA width
    
    JMP EraseSpriteMask
    ; return
}

;-------------------------------------------------------------------------
; DrawPlayer
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.DrawPlayer
{
    LDA #PLAYER_ERASE_NO    : STA eraseCharacter
    LDA playerCurrentSprite : STA currentCharacter
    LDA player_x            : STA currentXPosition
    LDA player_y            : STA currentYPosition
    LDA #PLAYER_HEIGHT      : STA height
    LDA #PLAYER_WIDTH       : STA width
    
    JMP PlotSpriteMask
    ; return
}

;-------------------------------------------------------------------------
; CheckCollision
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.CheckCollision
{
    LDA player_movement
    AND #PLAYER_KILLED
    CMP #PLAYER_KILLED
    ;AND #PLAYER_FALLING
    ;CMP #PLAYER_FALLING
    BEQ exit

    LDA player_movement
    AND #PLAYER_SWINGING
    CMP #PLAYER_SWINGING
    BEQ exit

    ; GOD MODE
    JSR PlayerDrowned
    BCS exit

    JSR CheckVineHit
    BCS exit

    ; GOD MODE
    ; Check for running into a holes or ponds etc and set carry
    JSR CheckBounds
    BCS exit
    
    LDA player_x : CLC : ADC #2 : STA player_x2
    LDA player_y : CLC : ADC #18 : STA player_y2
   
    ; Check if treasure was found before
    JSR CheckTreasures      
    BCS exit

    ;GOD MODE
    ;RTS

    JSR CheckScorpion
    BCC SkipScorpion
    
    ;JSR DebugCode
    JMP PlayerKilled
    ; return

.exit
    RTS

.SkipScorpion

    LDA sceneType
    CMP #CROCO_SCENE
    BEQ exit

    LDA object_y 
    CMP player_y2
    BCS exit            ; object y > player y
    CLC : ADC #8
    CMP player_y
    BCC exit            ; object < player y

    LDY object_counter
.loop
    LDA object_logs_x,Y
    CMP player_x2
    BCS not_found   ; >= object x > player x
    
    CLC : ADC #2
    CMP player_x
    BCC not_found   ; < object x2 < player x

    ; Check fire and cobra
    LDA objectType      
    CMP #ID_FIRE        ; fire or cobra?
    BCC hitLogs         ; no, hit by rolling logs

    JMP PlayerKilled    ; Harry is killed

.hitLogs

    LDA player_movement
    AND #PLAYER_FALLING
    CMP #PLAYER_FALLING
    BEQ exit

    LDA player_movement
    AND #PLAYER_ON_LADDER
    CMP #PLAYER_ON_LADDER
    BNE not_ladder
    LDA player_y : CLC : ADC #8 : STA player_y
    LDX #sfxCollision : JSR InitSound
    JSR ReduceScore
    JMP PrintScore
    ; return

.not_ladder

    LDA #PLAYER_KNEELING : STA player_movement
    LDA soundPlaying : BNE skip_sound
    LDX #sfxCollision : JSR InitSound
.skip_sound
    JSR ReduceScore
    JMP PrintScore
    ; return
    
.not_found
    DEY
    BNE loop

    LDA player_movement
    AND #PLAYER_KNEELING
    CMP #PLAYER_KNEELING
    BNE already_kneeling

    LDA player_movement : EOR #PLAYER_KNEELING : STA player_movement

.already_kneeling
    RTS
}

;-------------------------------------------------------------------------
; TreasureCollected
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.TreasureCollected
{
    LDA random
    ROL A
    ROL A
    ROL A
    AND #$03
    TAX                 ; bits 7 & 8
    LDY objectType      
    LDA TreasureMask,Y  ; y = 5, a = 4
    TAY
    AND treasureBits,X
    PHP
    TYA
    ORA treasureBits,X
    PLP
    RTS
}

;-------------------------------------------------------------------------
; CheckTreasures
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;-------------------------------------------------------------------------
.CheckTreasures
{
    LDA sceneType
    CMP #TREASURE_SCENE         ; treasue in scene?
    BNE exit                    ; no, skip
  
    LDA player_y
    CMP #PLAYER_JUNGLE_GROUND + 1 ;#PLAYER_UNDER_GROUND    ; Player undergroud ?
    BCS exit

    LDA xPosObject
    CMP player_x2
    BCS exit                    ; treasure x > player x2
    
    CLC : ADC #2
    CMP player_x
    BCC exit                    ; treasure x2 < player x

    JSR TreasureCollected
    BNE already_found

    STA treasureBits,X      ; clear treasure bit
    DEC treasureCnt         ; all treasures found
    BPL incScore            ; no, skip
    BMI already_found    

.incScore
    LDX #sfxTreasure : JSR InitSound
    
    JSR EraseTreasureObjectSprite
    JSR IncrementScore

.already_found
    SEC
    RTS

.exit
    CLC
    RTS
}

;-------------------------------------------------------------------------
; CheckScorpion
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.CheckScorpion
{
    LDA ladderFlag      ; ladder in scene
    BNE exit
 
    LDA player_y
    CMP #PLAYER_JUNGLE_GROUND+1
    BCC exit

    LDA #UNDER_GROUND : CLC : ADC #8
    CMP player_y2
    BCS exit            ; scorpion y > player y2
    CLC : ADC #8
    CMP player_y
    BCC exit            ; scorpion y < player y

    LDA scorpion_x
    CMP player_x2
    BCS exit            ; scorpion x > player x2
    
    CLC : ADC #2
    CMP player_x
    BCC exit            ; scorpion x2 < player x

    SEC
    RTS

.exit    
    CLC
    RTS
}

;-------------------------------------------------------------------------
; PlayerDrowned
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.PlayerDrowned
{
    LDA swampFlag
    BEQ exit

    LDA player_movement
    AND #PLAYER_FALLING
    CMP #PLAYER_FALLING
    BNE exit
 
    LDA player_y
    CMP #$AA
    BCC keep_falling
    
    ;Kill Player
    JMP PlayerKilled
    ; return

.keep_falling    
    SEC
    RTS

.exit
    CLC
    RTS    
}

;-------------------------------------------------------------------------
; PlayerKilled
;-------------------------------------------------------------------------
; On entry  :
; On exit   : 
;------------------------------------------------------------------------- 
.PlayerKilled
{
    LDX #sfxDeath : JSR InitSound

.sfx_loop    
    LDA soundPlaying : BNE sfx_loop

    JSR ErasePlayer
    LDA #(PLAYER_KILLED OR PLAYER_FALLING) : STA player_movement
    
    LDA #1 : STA player_direction   ; Always faces right after being killed
    JSR PlayerStanding

    LDA #$0A : STA player_x         ; start 10 pixels from the left

    LDA player_y
    CMP #$AB                        ; Roof of underground cavern                
    BCS killed_by_scorpion
    LDA #$0A : STA player_y         ; Start in the trees
    BNE killed

.killed_by_scorpion
    JSR EraseScorpionNoFrame
    JSR InitScorpion
    LDA #$B2 : STA player_y         ; Start below jungle floor and above roof of cavern

.killed
    JSR ReduceLives
    JMP DrawPlayer
    ; return
}