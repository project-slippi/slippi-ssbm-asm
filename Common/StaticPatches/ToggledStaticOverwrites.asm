#To be inserted at 8016e750
.include "../Common.s"
.include "../Preload Stadium Transformations/Transformation.s"

# TODO: I don't really like this implementation too much. I think possibly
# TODO: we should figure out a way to use this same injection to call different
# TODO: patchers that may or may not have been included. One possible idea is
# TODO: to have this injection check a static block of memory for branch
# TODO: instructions. If the value is 0, do nothing, if the value has a branch
# TODO: instruction, call it with branchl. Then the static patches would inject
# TODO: into that static memory block and return with blr

#Check if PAL
  lbz r3,PALToggle(rtoc)
  cmpwi r3,0x0
  beq GetNTSCChanges
GetPALChanges:
  bl  PALChanges
  mflr r3
  bl ApplyChanges
  b CheckPSPreload
GetNTSCChanges:
  bl  NTSCChanges
  mflr r3
  bl ApplyChanges
  b CheckPSPreload

CheckPSPreload:
#Check if PS is Preloaded
  lbz r3,PSPreloadToggle(rtoc)
  cmpwi r3,0x0
  beq GetPSPreloadDisable
GetPSPreload:
  bl  PSPreloadChanges
  mflr r3
  bl ApplyChanges
  b CheckFrozenPS
GetPSPreloadDisable:
  bl  PSPreloadDisableChanges
  mflr r3
  bl ApplyChanges

CheckFrozenPS:
#Check if PS is frozen
  lbz r3,FSToggle(rtoc)
  cmpwi r3,0x0
  beq GetFrozenPSDisable
GetFrozenPS:
  bl  FrozenPSChanges
  mflr r3
  bl ApplyChanges
  b Injection_Exit
GetFrozenPSDisable:
  bl  FrozenPSDisable
  mflr r3
  bl ApplyChanges

  b Injection_Exit

#################################################################

#**********************#
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
#**********************#
PSPreloadChanges:
blrl
.long 0x801d4610
b 0x4C
.long 0x801d4724
b 0x3C
.long 0x801d460c
lwz r4,TransformationID(r31)
.long 0xFFFFFFFF
PSPreloadDisableChanges:
blrl
.long 0x801d4610
addi	r4, r3, 32668
.long 0x801d4724
lbz	r0, 0x00C4 (r27)
.long 0x801d460c
lis	r3, 0x803B
.long 0xFFFFFFFF
#**********************#
FrozenPSChanges:
blrl
.long 0x801d45fc
b 0x9dc
.long 0xFFFFFFFF
FrozenPSDisable:
blrl
.long 0x801d45fc
bge- 0x9dc
.long 0xFFFFFFFF
#**********************#

#################################################################

ApplyChanges:
.set REG_Overwrites,5

#Init Loop
  subi  REG_Overwrites,r3,4
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
  blr

##########################################

Injection_Exit:
#Now flush the instruction cache
  lis r3,0x8000
  load r4,0x3b722c    #might be overkill but flush the entire dol file
  branchl r12,0x80328f50

#Original Codelines
  lis r3, 0x8017 #execute replaced code line
  lis	r4, 0x8017
