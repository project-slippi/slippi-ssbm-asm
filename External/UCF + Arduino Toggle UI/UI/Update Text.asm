################################################################################
# Address: 802604e8
################################################################################
.include "Common/Common.s"

#r5 = player number
#r6 = player number * 0x4
#r3 = player text pointer

####################################
#CHECK IF PLAYER CHANGED UCF TOGGLE#
####################################

#Only When CSP Window is Open
  lbz	r3, 0x0004 (r31) #get player number
  mulli r3,r3,0x24
  load r4,0x803f0e08
  add r3,r3,r4
  lbz r3,0x0(r3)
  cmpwi r3,3
  beq exit

#Get player's input struct
  load r4,0x804c20bc
  lbz	r5, 0x0004 (r31) #get player number
  mulli r5,r5,68
  add r4,r4,r5

#Check Players Inputs
  lwz r3,0x8(r4) #get players instant inputs
  rlwinm. r0,r3,0,30,30 #check dpad right
  bne toggleRight
  rlwinm. r0,r3,0,31,31 #check dpad left
  bne toggleLeft
  b updateText

toggleRight:
#Get Current Toggle Value
  lbz	r4, 0x0004 (r31) #get player number
  subi r5,rtoc,ControllerFixOptions #get UCF toggle bool base address
  lbzx r3,r5,r4	   #get players UCF toggle bool
  addi r3,r3,1
  cmpwi r3,2
  bgt updateText
  stbx r3,r5,r4	   #set players UCF toggle bool
  b playSFX

toggleLeft:
#Get Current Toggle Value
  lbz	r4, 0x0004 (r31) #get player number
  subi r5,rtoc,ControllerFixOptions #get UCF toggle bool base address
  lbzx r3,r5,r4	   #get players UCF toggle bool
  subi r3,r3,1
  cmpwi r3,0
  blt updateText
  stbx r3,r5,r4	   #set players UCF toggle bool
  b playSFX

playSFX:
  li  r3,2
  branchl r12, SFX_Menu_CommonSound


#############
#UPDATE TEXT#
#############

updateText:
#Get Player's Text Pointer
  lbz	r5, 0x0004 (r31) #get player number
  mulli r3,r5,0x4 #get offset
  subi r4,r13,UCFTextPointers #get pointers
  lwzx r3,r3,r4 #get players pointer

#Get Toggle Status
  subi r4,rtoc,ControllerFixOptions #get UCF toggle bool base address
  lbzx r4,r4,r5	        #get players UCF toggle bool

#Get Text Associated With Toggle Status
  bl  Text
  mflr  r6
  mulli r4,r4,0x8
  add r5,r4,r6

#Update Text
  li  r4,0x1    #Subtext ID 1
  branchl r12, Text_UpdateSubtextContents

b exit

##############

Text:
blrl

#Off
.long 0x4f666600
.long 0x

#UCF
.long 0x55434600
.long 0x

#Dween
.long 0x44776565
.long 0x6e000000

##############

exit:
lbz	r4, 0x0004 (r31)
