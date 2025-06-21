################################################################################
# Address: 0x80259e34
################################################################################

.include "Common/Common.s"
.include "./SSSToggles.s"

.set REG_NDATA, 31
.set REG_JOBJ, 30
.set REG_FROZEN, 22
.set REG_NEW_ICON, 21
.set REG_DATA, 20

b CODE_START

DATA_BLRL:
blrl
.set IS_CHANGED, 0
.byte 0
.align 2

CODE_START:
  backup
  # get our static toggle data
  computeBranchTargetAddress REG_FROZEN, 0x8025a530
  addi REG_FROZEN, REG_FROZEN, 0x8

  bl DATA_BLRL
  mflr REG_DATA

# rewriting the stage name logic to include our frozen stadium toggle
  lhz	r3, 0 (REG_NDATA) # icon id
  lbz	r0, OFST_HOVERED_ICON(r13)
  mr REG_NEW_ICON, r0

  # original logic
  cmpw r0, r3
  bne ORIGINAL_EXIT # this is a new icon

# check if our frozen states are different, if they arent, animate the new name
CHECK_FOR_ALT:
  cmpwi r0, ID_GRPS # stadium?
  bne EXIT

  lbz r3, 0(REG_FROZEN)
  lbz r4, IS_CHANGED(REG_DATA)
  cmpw r3, r4
  beq EXIT # equal, exit early
  stb r3, IS_CHANGED(REG_DATA) # update our state
  cmpwi r3, 0
  beq UNFROZEN

FROZEN:
  li REG_NEW_ICON, 31
  b ANIM_OUT

UNFROZEN:
  li REG_NEW_ICON, ID_GRPS
  b ANIM_OUT

MAX_CHECK:
  cmplwi r3, 31 # max icons
  bge SETUP_NEW_NAME

  mulli r0, r3, 28
  lis	r3, 0x803F
  addi	r3, r3, 1744
  add	r3, r3, r0
  lbz	r0, 0x8(r3)
  cmplwi	r0, 2 # check locked
  blt SETUP_NEW_NAME

# animate out the old name
ANIM_OUT:
  lfs	f1, -0x363C(rtoc)
  addi	r3, r30, 0
  li	r4, 1
  branchl r12, 0x8036f7b0 # HSD_JObjReqAnimAllByFlags
  
SETUP_NEW_NAME:
  li	r3, 2
  branchl r12, SFX_Menu_CommonSound
  li	r0, 0 
  stw	r0, 0x4(REG_NDATA) # anim timer
  li	r0, 2
  sth	r0, 0x2(REG_NDATA) # state
  mr r3, REG_NEW_ICON
  branchl r12, SSS_CreateStageNameText

  b EXIT

ORIGINAL_EXIT:
  restore
  lhz	r3, 0 (r31)
  # we still run original logic because we the frozen toggle could be on, but we are coming from a different icon
  # this will get handled by CheckForFrozenOnStageName.asm
  branch r12, 0x80259e38

EXIT:
  restore
  branch r12, 0x80259ec0 # return to end of function