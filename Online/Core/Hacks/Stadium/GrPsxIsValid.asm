################################################################################
# Address: 0x801d4760
################################################################################
# The original code returns a bool indicating whether or not the stage file
# was loaded properly.
################################################################################

.include "Common/Common.s"

.set Stage_GetGObj, 0x801c2ba4
.set Stage_GetMapHead, 0x801c6330

.set OFST_DATA, 0x2C
.set OFST_ID, 0x14

CODE_START:

# get the transformation map_head archive pointer
  li r3, 2
  branchl r12, Stage_GetGObj
  lwz r3, OFST_DATA(r3)
  lwz r3, OFST_ID(r3)
  
  branchl r12, Stage_GetMapHead
  lwz r3, 0(r3)

  cmpwi r3, 0 # not loaded, something wrong happened
  beq EXIT

# buffer exists, lets check if there is a size
  lwz r3, 0(r3)
  cmpwi r3, 0
  beq EXIT # not good, archive wasnt initialized properly

# archive exists and was initialized properly
  li r3, 1

EXIT:
  