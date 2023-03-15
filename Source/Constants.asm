; OS function vectors

USERV = $0200 ; User vector, called by *LINE, *CODE, OSWORD >=&E0
BRKV  = $0202 ; The BRK vector
IRQ1V = $0204 ; Main interrupt vector
IRQ2V = $0206 ; Secondary interrupt vector
CLIV  = $0208 ; Command Line Interpreter vector
BYTEV = $020A ; OSBYTE (*FX) calls
WORDV = $020C ; OSWORD calls
WRCHV = $020E ; Send character to current output stream
RDCHV = $0210 ; Wait for a character from current input stream
FILEV = $0212 ; Operate on a whole file, eg loading/saving/delete/etc
ARGSV = $0214 ; Read/Write arguments on an open file
BGETV = $0216 ; Read a byte from an open file
BPUTV = $0218 ; Write a byte to an open file
GBPBV = $021A ; Read/Write block of data from/to open file or device
FINDV = $021C ; Open or close a file
FSCV  = $021E ; Various filing system control calls
EVNTV = $0220 ; Event handler
UPTV  = $0222 ; User Print vector
NETV  = $0224 ; Network Print vector
VDUV  = $0226 ; Unrecognised VDU commands
KEYV  = $0228 ; Read the keyboard
INSBV = $022A ; Insert characters into a buffer
REMVB = $022C ; Remove characters from a buffer
CNPV  = $022E ; Count or Purge a buffer
IND1V = $0230 ; Spare
IND2V = $0232 ; Spare
IND3V = $0234 ; Spare  ($0234/5 nULA support: old BYTEV)

crtcAddr    = $FE00 ; 6845 address
crtcData    = $FE01 ; 6845 data
ulaMode     = $FE20 ; ula video mode (Control)
ulaPalette  = $FE21 ; ula colour palette
nuLACtrl    = $FE22 ; (Control)
nuLAPalette = $FE23 ; nuLA colour palette

sysVIAPortB                 = $FE40 ; sysVIA port B data
sysVIADataDirectionRegB     = $FE42 ; sysVIA port B io control
sysVIADataDirectionRegA     = $FE43 ; sysVIA Port A io control
sysVIATimer1CounterLow      = $FE44 ; sysVIA timer 1 low counter
sysVIATimer1CounterHigh     = $FE45 ; sysVIA timer 1 high counter
sysVIATimer1LatchLow        = $FE46 ; sysVIA timer 1 low latch
sysVIATimer1LatchHigh       = $FE47 ; sysVIA timer 1 high latch
sysVIATimer2CounterLow      = $FE48 ; sysVIA timer 2 counter low
sysVIATimer2CounterHigh     = $FE49 ; sysVIA timer 2 counter high
sysVIAAuxControlReg         = $FE4B ; sysVIA auxiliary control register  
sysVIAInterruptFlagReg      = $FE4D ; sysVIA interrupt flags  
sysVIAInterruptEnableReg    = $FE4E ; sysVIA interrupt enable    
sysVIAPortA                 = $FE4F ; sysVIA Port A data (no handshake)

ADCControl                  = &FEC0 ; Model B/B+ Control Register
ADCHigh                     = &FEC1 ; Model B/B+ High Byte
ADCLow                      = &FEC2 ; Model B/B+ Low Byte

MasterADCControl            = &FE18 ; Master Control Register
MasterADCHigh               = &FE19 ; Master High Byte
MasterADCLow                = &FE1A ; Master Low Byte

OSRDCH      = $FFE0
OSASCI      = $FFE3
OSWRCH      = $FFEE
OSWORD      = $FFF1
OSBYTE      = $FFF4
OSCLI       = $FFF7
NMI         = &FFFA
RESET_BEEB  = &FFFC
IRQ_BRK     = &FFFE

MAPCHAR '0','9',0
MAPCHAR 'J',10
MAPCHAR 'K',11
MAPCHAR 'Q',12
MAPCHAR 'S',13
MAPCHAR 'P',14
MAPCHAR ' ',15
MAPCHAR '[',16      ; Lives 1
MAPCHAR ']',17      ; Lives 2
MAPCHAR ':',18

MAPCHAR 'A',19
MAPCHAR 'D',20
MAPCHAR 'E',21
MAPCHAR 'G',22
MAPCHAR 'L',23
MAPCHAR 'M',24
MAPCHAR 'N',25
MAPCHAR 'O',26
MAPCHAR 'R',27
MAPCHAR 'V',28
MAPCHAR 'W',29
MAPCHAR '-',30 ; Used for text border
MAPCHAR '|',31 ;
MAPCHAR '$',32 ;
MAPCHAR '%',33 ;
MAPCHAR '^',34 ;
MAPCHAR '&',35 ;

palBlack        = 0 eor 7        ; palette color values
palRed          = 1 eor 7
palGreen        = 2 eor 7
palYellow       = 3 eor 7
palBlue         = 4 eor 7
palMagenta      = 5 eor 7
palCyan         = 6 eor 7
palWhite        = 7 eor 7

SCREEN_ADDRESS  = $3000
CLOCK_ADDRESS   = SCREEN_ADDRESS +  3 * 4 * 8               ; Character position 3,0
LIVES_ADDRESS   = SCREEN_ADDRESS + 10 * 4 * 8               ; Character position 10,0
SCORE_ADDRESS   = SCREEN_ADDRESS + 12 * 4 * 8               ; Character position 12,0
SPECIAL_ADDRESS = SCREEN_ADDRESS + (30* 640) + 17 * 4 * 8   ; Character position 17,30
ENDING_ADDRESS1 = SCREEN_ADDRESS + (4 * 640) + 5 * 4 * 8    ; Character position 5,4
ENDING_ADDRESS2 = SCREEN_ADDRESS + (5 * 640) + 5 * 4 * 8    ; Character position 5,5
ENDING_ADDRESS3 = SCREEN_ADDRESS + (6 * 640) + 5 * 4 * 8    ; Character position 5,6

irq_A_save  = &FC

OP_INX      = $E8
OP_DEX      = $CA
OP_BEQ      = $F0
OP_BMI      = $30
OP_RTI      = $40

; Exact time for a 50Hz frame less latch load time
FramePeriod = 312*64-2

; Calculate here the timer value to interrupt at the desired line
;Timer1Value = (39-35) * 8 * 64   ; total rows - vsync row * 8 * 64us 
;            - 2*64         ; latch * 64us
;            + 28*8*64      ; row * 8 * 64us
Timer1Value = (39-34) * 8 * 64 - (2 * 64) + (28 * 8 * 64)


; Font Colours
BLACK       = $00
RED         = $03
GREEN       = $0C
YELLOW      = $0F
BLUE        = $30
MAGENTA     = $33
CYAN        = $3C
WHITE       = $3F

keyP        = &37   ; Pause     on / off
keyS        = &51   ; Sound     on / off
keyJ        = &45   ; Joystick  on / off

keyZ        = &61   ; Left
keyX        = &42   ; Right
keyColon    = &48   ; Up
keySlash    = &68   ; Down
keyReturn   = &49   ; Jump
keySpace    = &62   ; Start
keyEscape   = &70   ; Exit

KEYPRESS_JUMP   = %00000001
KEYPRESS_LEFT   = %00000010
KEYPRESS_DOWN   = %00000100
KEYPRESS_UP     = %00001000
KEYPRESS_RIGHT  = %00010000
KEYPRESS_SPACE  = %00100000

SPECIAL_KEYS_COUNTER = $15

SPECIAL_J       = %00000001
SPECIAL_S       = %00000010
SPECIAL_P       = %00000100
SPECIAL_ESCAPE  = %00001000

JOYSTICK_FIRE           = %00000001        
JOYSTICK_LEFT           = %00000010   
JOYSTICK_DOWN           = %00000100     
JOYSTICK_UP             = %00001000     
JOYSTICK_RIGHT          = %00010000      

; some defined y-positions
PLAYER_JUNGLE_GROUND    = 146
PLAYER_JUNGLE_KNEELING  = 151
PLAYER_UNDER_GROUND     = 202
JUNGLE_GROUND           = 160   
UNDER_GROUND            = 208   

WALL_LEFT               = 8     ; left wall x-position
WALL_RIGHT              = 68    ; right wall x-position
OBJECT_XPOS             = 62    ; x-position of logs, fire, cobra or treasure
   
RAND_SEED               = $C4

ID_STATIONARY           = 4     ; stationary logs (0..5 are log types)
ID_FIRE                 = 6
ID_COBRA                = 7
ID_TREASURES            = 8     ; 8..11 are treasures
ID_NOTHING              = 12

; sceneType constants:
HOLE1_SCENE             = 0
HOLE3_SCENE             = 1
CROCO_SCENE             = 4
TREASURE_SCENE          = 5

; flags for ladder:
NOLADDER                = %00000000
WITHLADDER              = %11111111

LADDER_XPOS1            = 37
LADDER_XPOS2            = 41
LADDER_YPOS1            = 162
LADDER_YPOS2            = 224

; x constants:
SCREENWIDTH             = 80
XMIN_HARRY              = 4         ; minimal position before next left scene
XMAX_HARRY              = 74        ; maximal position before next right scene

charColumn              = 2 * 8
charRow                 = SCREENWIDTH * 8

HALF_SCREEN_WIDTH       = 40


sfxJump             = 0
sfxFall             = 1
sfxVine             = 2
sfxDeath            = 3
sfxTreasure         = 4
sfxCollision        = 5
sfxGameOver         = 6

EMPTY_BLOCK         = 0     ; True Black
BLACK_BLOCK         = 1
GREEN_HASH_BLOCK    = 2
CYAN_BLOCK          = 3
YELLOW_BLOCK        = 4
YELLOW_HASH_BLOCK   = 5
RED_HASH_BLOCK      = 6
HIDDEN_YELLOW       = 7
WALL                = 8
LADDER_TOP          = 9
LADDER              = 10
HOLE_BLOCK          = 11
TREE_TRUNK          = 12
TREE_BRANCH         = 13
LEAVES00            = 2     ; Copy of GREEN_HASH_BLOCK 
LEAVES01            = 14    ; Following used for leaves
LEAVES02            = 15
LEAVES03            = 16
LEAVES04            = 17
LEAVES05            = 18
LEAVES06            = 19
LEAVES07            = 20
LEAVES08            = 21
LEAVES09            = 22
LEAVES10            = 23
HARRY_R_0           = 24    ; Harry Right 0 - Jumping
HARRY_R_1           = 25    ; Harry Right 1
HARRY_R_2           = 26    ; Harry Right 2
HARRY_R_3           = 27    ; Harry Right 3
HARRY_R_4           = 28    ; Harry Right 4
HARRY_R_5           = 29    ; Harry Right 5 - Standing
HARRY_R_6           = 30    ; Harry Right 6 - Swinging
HARRY_R_7           = 31    ; Harry Right 7 - Climb
HARRY_R_8           = 32    ; Harry Left 8  - Climb
HARRY_L_0           = 33    ; Harry Left 0  - Jumping
HARRY_L_1           = 34    ; Harry Left 1
HARRY_L_2           = 35    ; Harry Left 2
HARRY_L_3           = 36    ; Harry Left 3
HARRY_L_4           = 37    ; Harry Left 4
HARRY_L_5           = 38    ; Harry Left 5  - Standing
HARRY_L_6           = 39    ; Harry Left 6  - Swinging
LOG_0               = 40    ; Log Animation Frame 1
LOG_1               = 41    ; Log Animation Frame 2
FIRE_0              = 42    ; Fire Animation Frame 1
FIRE_1              = 43    ; Fire Animation Frame 2
COBRA_0             = 44    ; Cobra Animation Frame 1
COBRA_1             = 45    ; Cobra Animation Frame 2
CROC_0              = 46    ; Croc Animation Frame 1
CROC_1              = 47    ; Croc Animation Frame 2
MONEY_BAG           = 48    ; Money Bag Treasure
SCORPION_R_0        = 49    ; Scorpion Right Animation Frame 1
SCORPION_R_1        = 50    ; Scorpion Right Animation Frame 2
SCORPION_L_0        = 51    ; Scorpion Left Animation Frame 1
SCORPION_L_1        = 52    ; Scorpion Left Animation Frame 2
BAR_0               = 53    ; Bar (Treasure) Animation Frame 1
BAR_1               = 54    ; Bar (Treasure) Animation Frame 2
RING                = 55    ; Ring (Treasure)
POND00              = 56    ; Following used for swamp / quicksand
POND01              = 57    ; 
POND02              = 58    ; 
POND03              = 59    ; 
POND04              = 60    ; 
POND06              = 61    ; 
POND07              = 62    ; 
POND08              = 63    ; 
POND09              = 64    ; 
POND10              = 65    ; 
POND11              = 66    ; 
POND12              = 67    ; 
POND13              = 68    ; 
POND14              = 69    ; 
POND15              = 70    ; 
