################################################################################
# Address: FN_IsVSMode # 0x80005604 from Recording.s
################################################################################
.include "Recording/Recording.s"

#Check scenes
  lis r4, 0x8048          # load address to offset from for scene controller
  lbz r3, -0x62D0(r4)
  cmpwi r3, 0x2           # the major scene for VS Mode is 0x2
  bne- NotVSMode          # if not in VS Mode, ignore everything
  lbz r3, -0x62CD(r4)
  cmpwi r3, 0x2           # the minor scene for in-game is 0x2
  bne- NotVSMode

IsVSMode:
  li  r3,1
  b Exit

NotVSMode:
  li  r3,0
  b Exit

Exit:
  blr
