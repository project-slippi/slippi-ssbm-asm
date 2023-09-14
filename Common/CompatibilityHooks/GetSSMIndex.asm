################################################################################
# Address: FN_GetSSMIndex
################################################################################
# Inputs:
# r3: kind (fighter / stage)
# r4: index
################################################################################
# Returns
# r3: SSM ID
################################################################################
# Description:
# Returns SSM ID for inputted fighter/stage ID 
################################################################################

.include "Common/Common.s"

cmpwi r3,1
beq isStage

isFighter:
  load r3,0x803bb3c0
  mulli r4,r4,0x10
  lbzx r3,r3,r4
  b Exit 

isStage:
  load r3,0x803bb6b0
  mulli r4,r4,0x3
  lbzx r3,r3,r4
  b Exit 

Exit:
blr
