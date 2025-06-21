################################################################################
# Address: 0x801d1500
################################################################################

.include "Common/Common.s"

.set REG_DATA, 31
.set REG_MSRB, 30

b CODE_START

CODE_START:
  backup
  stb	r0, 0x00C4(r31) # original code

  computeBranchTargetAddress REG_DATA, 0x801d457c # FreezeStadium.asm
  addi REG_DATA, REG_DATA, 0x8

  getMinorMajor r3
  cmpwi r3, SCENE_ONLINE_IN_GAME
  bne OFFLINE_CHECK

  # we are online, so lets get the toggle state from the MSRB
  li r3, 0
  branchl r12, FN_LoadMatchState
  mr REG_MSRB, r3

  lbz r3, MSRB_ALT_STAGE_MODE(REG_MSRB)
  stb r3, IS_FROZEN(REG_DATA)

  b EXIT

OFFLINE_CHECK:
  # we can grab this directly from the SSS
  computeBranchTargetAddress r3, 0x8025a530
  addi r3, r3, 0x8
  lbz r4, 0(r3)
  stb r4, IS_FROZEN(REG_DATA)


EXIT:
  restore
