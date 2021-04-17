################################################################################
# Address: 8009e090
################################################################################
.include "Common/Common.s"

# the fighters jobj matrix is not setup after performing dynamics calculations
# luckily for HAL, the shadow render sets up the matrix during rendering. this is
# very likely not intentional.

# this caused bone positions to not update accurately when fast forwarding because
# it wasnt rendering and setting up the matrix as a result.

# when dynamics are updated, a flag is set on some fighter bone jobjs. it only
# does this if the fighter state uses dynamics.
# this fix runs after the game processes dynamics and does the updates
# right away if the flag has been set, this will cause them to be correct even
# when ffw'ing as they no longer rely on the shadow render cleaning them up

# (vanilla shaodw mtx update during render @ 8037f8f4)

# setup mtx for fighter jobj
  lwz r3,0x28(r27)
  bl JOBJ_SetupMatrixSubAll
  b Exit

#######################
JOBJ_SetupMatrixSubAll:
# r3 = jobj
# f1 = alpha

.set REG_JObj, 31

# backup jobj
  mflr r0
  stw	r0, 0x0004 (sp)
  stwu	sp, -0x0018 (sp)
  stw	REG_JObj, 0x0014 (sp)
  mr REG_JObj,r3

# ensure some flags are set
  lwz r3,0x14(REG_JObj)
  rlwinm. r0,r3,0,0x00800000
  bne JOBJ_SetupMatrixSubAll_Skip
  rlwinm. r0,r3,0,0x40
  beq JOBJ_SetupMatrixSubAll_Skip
  mr r3,REG_JObj
  branchl r12,0x80373078
JOBJ_SetupMatrixSubAll_Skip:

# run on child
  lwz r3,0x10(REG_JObj)
  cmpwi r3,0
  beq 0x8
  bl  JOBJ_SetupMatrixSubAll
# run on sibling
  lwz r3,0x8(REG_JObj)
  cmpwi r3,0
  beq 0x8
  bl  JOBJ_SetupMatrixSubAll

JOBJ_SetupMatrixSubAll_Exit:
  lwz	REG_JObj, 0x0014 (sp)
  lwz r0,0x1C(sp)
  addi	sp, sp, 0x0018
  mtlr r0
  blr
#######################

Exit:
lmw	r24, 0x0028 (sp)
