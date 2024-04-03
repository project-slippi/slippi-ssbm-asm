################################################################################
# Address: 8016ded4
################################################################################
.include "Common/Common.s"

backup

###################
## Costume Bound ##
###################

.set REG_Loop, 31
.set REG_CostmeID,30
BoundLoop_Init:
  li REG_Loop,0
BoundLoop:
  # Ensure player exists
    mr r3,REG_Loop
    branchl r12,0x8003241c
    cmpwi r3,3
    beq BoundLoop_Inc
  # Get this fighters costume id
    mr r3,REG_Loop
    branchl r12,0x80033198
    mr REG_CostmeID,r3
  # Get max costume
    mr r3,REG_Loop
    branchl r12,0x80032330
    branchl r12,0x80169238
  # Check if over
    cmpw REG_CostmeID,r3
    blt BoundLoop_Inc
  # Set to default costume
    mr r3,REG_Loop
    li r4,0
    branchl r12,0x80033208
BoundLoop_Inc:
  addi REG_Loop,REG_Loop,1
BoundLoop_Check:
  cmpwi REG_Loop,6
  blt BoundLoop


#######################
## Correct Conflicts ##
#######################

# Check each fighter for a conflicting costume
.set REG_Loop, 31
.set REG_FighterID, 30
.set REG_CostumeID, 29
.set REG_SubcolorID, 28
Loop_Init:
  li REG_Loop,0

Loop:
  # ensure player exists
    mr r3,REG_Loop
    branchl r12,0x8003241c
    cmpwi r3,3
    beq Loop_Inc

  # Get this fighters ext id
    mr r3,REG_Loop
    branchl r12,0x80032330
    mr REG_FighterID,r3
  # Get this fighters costume id
    mr r3,REG_Loop
    branchl r12,0x80033198
    mr REG_CostumeID,r3
  # Get this fighters subcolor id
    mr r3,REG_Loop
    branchl r12,0x80033284
    mr REG_SubcolorID,r3

  .set REG_CostumeLoop, 27
  CostumeLoop_Init:
    li REG_CostumeLoop,0
  CostumeLoop_Loop:
  # Not me
    cmpw REG_Loop,REG_CostumeLoop
    beq CostumeLoop_Inc

  # ensure player exists
    mr r3,REG_CostumeLoop
    branchl r12,0x8003241c
    cmpwi r3,3
    beq CostumeLoop_Inc
  
  # Check fighter ID
    mr r3,REG_CostumeLoop
    branchl r12,0x80032330
    cmpw r3,REG_FighterID
    bne CostumeLoop_Inc
  # Check costume ID
    mr r3,REG_CostumeLoop
    branchl r12,0x80033198
    cmpw r3,REG_CostumeID
    bne CostumeLoop_Inc
  # Check subcolor ID
    mr r3,REG_CostumeLoop
    branchl r12,0x80033284
    cmpw r3,REG_SubcolorID
    bne CostumeLoop_Inc
  # Found a match, if subcolor matches, increment *their* subcolor
    addi r4,r3,1
    mr r3,REG_CostumeLoop
    branchl r12,0x800332f4
  CostumeLoop_Inc:
    addi REG_CostumeLoop,REG_CostumeLoop,1
  CostumeLoop_Check:
    cmpwi REG_CostumeLoop,6
    blt CostumeLoop_Loop

Loop_Inc:
  addi REG_Loop,REG_Loop,1
Loop_Check:
  cmpwi REG_Loop,6
  blt Loop


Exit:
  restore
  lwz	r0, 0x001C (sp)