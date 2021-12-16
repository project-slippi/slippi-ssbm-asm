################################################################################
# Address: 0x800d4d68
################################################################################
.include "Common/Common.s"
.include "Online/Online.s"

/*
During DeadUpFall, after the fighter hits the screen

0x2348 = previously used variable, now storing Y velocity
0x234C = previously used variable, now storing Z velocity
0x2350 = position vector
0x235c = temp velocity vector (contents cleared when leaving function so cant use this across frames)
*/

# orig instruction
  lfs	f1, 0x0034 (r30)  # gravity
  lfs	f2, 0x0038 (r30)  # terminal velocity
  lfs	f3, 0x2348 (r31)  # curr Y velocity

# subtract gravity
  fsub	f3, f3, f1  
  fneg f2, f2        # negate terminal velocity
  fcmpo cr0, f3, f2  # limit velocity
  bgt StoreVelocity
# use terminal velocity
  fmr f3, f2
StoreVelocity:
  stfs	f3, 0x2348 (r31)

UpdateVector:
# update Y position
  lfs f1, 0x2360 (r31)    # y component of temp velocity
  lfs	f2, 0x2348 (r31)    # curr Y velocity
  fadds f1,f1,f2
  stfs f1, 0x2360 (r31)   # y component of temp velocity
# update Z position 
  lfs	f1, 0x234C (r31)   # curr Z velocity
  lfs f2, 0x2364 (r31)   # Z component of temp velocity
  fadds f1,f1,f2
  stfs f1, 0x2364 (r31)   # Z component of temp velocity


Exit:
  branch r12,0x800d4d84