################################################################################
# Address: FN_ShouldRecord # 0x80005604 from Recording.s
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"
.include "Online/Online.s"

  getMinorMajor r3
  cmpwi r3, SCENE_VERSUS_IN_GAME
  beq ReturnTrue
  cmpwi r3, SCENE_VERSUS_SUDDEN_DEATH
  beq ReturnTrue
  cmpwi r3, SCENE_ONLINE_IN_GAME
  beq ReturnTrue
  cmpwi r3, SCENE_TARGETS_IN_GAME
  beq ReturnTrue
  cmpwi r3, SCENE_HOMERUN_IN_GAME
  beq ReturnTrue

ReturnFalse:
  li  r3,0
  b Exit

ReturnTrue:
  li  r3,1
  b Exit

Exit:
  blr
