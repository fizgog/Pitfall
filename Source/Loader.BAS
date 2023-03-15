REM Pitfall Loader
REM BBC Conversion Shaun Lindsley
REM (c) 2022/2023
REM Greets to ChrisB, Kieranhj, Lovebug, oss003, Rich Talbot-Watkins
REM TobyLobster, Tricky 
REM and the rest of the Stardot community
MODE 2:ON ERROR GOTO 20
VDU23;8202;0;0;0;
*LOAD PITSCR
T%=TIME:*FX15,0
REPEAT UNTIL TIME>T%+1000 OR INKEY(10)<>-1

20MODE7:ON ERROR GOTO 700
VDU23;8202;0;0;0;28,0,31,19,17

PRINTTAB(7,0);CHR$(146);"h,|l4l<hl<4l<l h4 l< (|$"
PRINTTAB(7,1);CHR$(146);CHR$(255);" ";CHR$(255);" ";CHR$(255);"j5 j5 j50 ";CHR$(255);"o j5  ";CHR$(255)
PRINTTAB(7,2);CHR$(146);"  ";CHR$(255);"/!j5 j5 j7%_wz0j5  ";CHR$(255)
PRINTTAB(7,3);CHR$(146);" _";CHR$(255);"0 zu zu zu z7kuj}p4";CHR$(255);"tx"
PRINTTAB(5,5)CHR$134"BBC Conversion Shaun Lindsley"'
PRINTTAB(5,23);CHR$133;CHR$(136);"Press SPACE BAR to continue"
VDU28,0,22,39,7
PRINTCHR$135"SCENARIO:"'
PRINTCHR$130"Picture this! You are deep in the"
PRINTCHR$130"recesses of a forbidden jungle an"
PRINTCHR$130"unforgiven place for few explorers"
PRINTCHR$130"ever survive. But you've got courage,"
PRINTCHR$130"because you're with Pitfall Harry, the"
PRINTCHR$130"worlds famous jungle explorer and"
PRINTCHR$130"fortune hunter extraordinaire."'
PRINTCHR$130"The lure of hidden treasure draws you"
PRINTCHR$130"and Harry deeper and deeper into the"
PRINTCHR$130"bush." 
REPEAT:UNTIL GET=32:CLS:*FX15

PRINTCHR$130"But, being a great explorer, you"
PRINTCHR$130"wouldn't think of starting such a "
PRINTCHR$130"difficult journey without reading the"
PRINTCHR$130"this manual."'
PRINTCHR$130"The object of Pitfall! is to guide"
PRINTCHR$130"Harry through a maze of jungle scenes,"
PRINTCHR$130"jumping over or avoiding many deadly"
PRINTCHR$130"dangers, and helping Harry grab the"
PRINTCHR$130"most treasures in the shortest"
PRINTCHR$130"possible time."
REPEAT:UNTIL GET=32:CLS:*FX15

PRINTCHR$135"THE HAZARDS OF PITFALL!:"'
PRINTCHR$130"Pitfall Harry's Jungle Adventure is"
PRINTCHR$130"fraught with danger. Some hazards will"
PRINTCHR$130"slow him down and rob you of points,"
PRINTCHR$130"while others will stop him cold in his"
PRINTCHR$130"tracks. The ""lesser"" hazards are the"
PRINTCHR$130"open holes in the ground and rolling"
PRINTCHR$130"logs. The catastrophic hazards are the"
PRINTCHR$130"scorpions, fires, cobra rattlers,"
PRINTCHR$130"crocodiles, swamps, quicksand and tar"
PRINTCHR$130"pits."
PRINTCHR$130"These obstacles will not cost you"
PRINTCHR$130"points, BUT they will cost one of"
PRINTCHR$130"Harry's 3 lives."
REPEAT:UNTIL GET=32:CLS:*FX15

PRINTCHR$135"SCORING:"'
PRINTTAB(5);CHR$131"DIAMOND RING............5000"
PRINTTAB(5);CHR$131"GOLD BAR................4000"
PRINTTAB(5);CHR$131"SILVER BAR..............3000"
PRINTTAB(5);CHR$131"MONEY BAG...............2000"'

PRINTCHR$135"TIME:"'
PRINTCHR$130"You have 20 minutes to complete each"
PRINTCHR$130"adventure. Harry has 3 lives in each"
PRINTCHR$130"game. The game is over when Harry is"
PRINTCHR$130"""lost"" for the third time or when"
PRINTCHR$130"time runs out."
REPEAT:UNTIL GET=32:CLS:*FX15

700REM
VDU28,0,24,39,7:CLS:*FX15
PRINTTAB(13)CHR$133"Game Controls"'
PRINTTAB(17)CHR$130"Z - Left"
PRINTTAB(17)CHR$130"X - Right"
PRINTTAB(17)CHR$130": - Up"
PRINTTAB(17)CHR$130"/ - Down"'
PRINTTAB(12)CHR$131"RETURN - Jump"'
PRINTTAB(12)CHR$129"ESCAPE - Exit the game"'
PRINTTAB(17)CHR$129"S - Sound on/off" 
PRINTTAB(17)CHR$129"P - Pause on/off"     
PRINTTAB(17)CHR$129"J - Joystick/Keyboard"
PRINTTAB(7,16);CHR$133;"Press SPACE BAR to start"
REPEAT:UNTIL GET=32:*FX15
*RUN PITFALL