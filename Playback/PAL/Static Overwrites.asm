#To be inserted at 8016e750
.include "../../Common/Common.s"

.set REG_Overwrites,5

#Check if PAL
  lbz r3,PALToggle(rtoc)
  cmpwi r3,0x1
  beq GetPALChanges

GetNTSCChanges:
  bl  NTSCChanges
  mflr REG_Overwrites
  b ApplyChanges

GetPALChanges:
  bl  PALChanges
  mflr REG_Overwrites
  b ApplyChanges

#################################################################

PALChanges:
blrl
#Samus Bomb Jump
.long 0x803ce4d4
.long 0x00240464
#Detection Hitboxes
.long 0x800796e0
nop
#Samus Extender 1
.long 0x802b7e54
b 0x88
#Samus Extender 2
.long 0x802b808c
b 0x84
#DK Up B
.long 0x8010fc48
nop
#DK Up B
.long 0x8010fb68
nop
#Freeze Glitch
.long 0x801239a8
nop
#End
.long 0xFFFFFFFF

NTSCChanges:
blrl
#Samus Bomb Jump
.long 0x803ce4d4
.long 0x00200000
#Detection Hitboxes
.long 0x800796e0
li	r18, 1
#Samus Extender 1
.long 0x802b7e54
lbz	r3, 0x2240 (r31)
#Samus Extender 2
.long 0x802b808c
cmpwi	r3, 2
#DK Up B
.long 0x8010fc48
stw	r0, 0x21DC (r5)
#DK Up B
.long 0x8010fb68
stw	r0, 0x21DC (r5)
#Freeze Glitch
.long 0x801239a8
stw	r0, 0x1A5C (r31)
#End
.long 0xFFFFFFFF

#################################################################

ApplyChanges:
#Init Loop
  subi  REG_Overwrites,REG_Overwrites,4
#Loop
ApplyChanges_Loop:
#Get next address
  lwzu r3,0x4(REG_Overwrites)
#Check if end of list
  cmpwi r3,-1
  beq ApplyChanges_Exit
#Get and place value
  lwzu r4,0x4(REG_Overwrites)
  stw r4,0x0(r3)
  b ApplyChanges_Loop

ApplyChanges_Exit:
#Now flush the instruction cache
  lis r3,0x8000
  load r4,0x3b722c    #might be overkill but flush the entire dol file
  branchl r12,0x80328f50

#Original Codelines
  lis r3, 0x8017 #execute replaced code line
  lis	r4, 0x8017
