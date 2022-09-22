################################################################################
# Address: 80043238
################################################################################
.include "Common/Common.s"

.set REG_CollData, 31
.set REG_FighterData, 30

backup
mr REG_CollData,r3

#Determine type of object
  lwz r12,0x0(REG_CollData)
  cmpwi r12,0
  beq GObj_None
  lhz r0,0x0(r12)
  cmpwi r0,4
  beq GObj_Fighter

GObj_NonFighter:
  bl Text_NonFighterGObj
  mflr r3
  lhz r4,0x0(r12)
  branchl r12,0x803456a8
  b ECB_Output
  
GObj_None:
  bl Text_NoGObj
  mflr r3
  branchl r12,0x803456a8
  b ECB_Output

GObj_Fighter:
#Get Fighter Data
  lwz r3,0x0(REG_CollData)
  lwz REG_FighterData,0x2C(r3)
#Output player info
  bl Text_PlyInfo
  mflr r3
  lbz r4,0xC(REG_FighterData)
  lbz r5,0x221f(REG_FighterData)
  rlwinm. r5,r5,0,0x08
  lwz r6,0x138(REG_CollData)
  lwz r7,0x10(REG_FighterData)
  lfs f1,0x894(REG_FighterData)
  branchl r12,0x803456a8

ECB_Output:
#Output all ECB positions
  bl Text_ecbCurr
  mflr r3
  branchl r12,0x803456a8
  bl Text_top
  mflr r3
  lwz r4,0x84(REG_CollData)
  lwz r5,0x88(REG_CollData)
  branchl r12,0x803456a8
  bl Text_bot
  mflr r3
  lwz r4,0x8C(REG_CollData)
  lwz r5,0x90(REG_CollData)
  branchl r12,0x803456a8
  bl Text_right
  mflr r3
  lwz r4,0x94(REG_CollData)
  lwz r5,0x98(REG_CollData)
  branchl r12,0x803456a8
  bl Text_left
  mflr r3
  lwz r4,0x9C(REG_CollData)
  lwz r5,0xA0(REG_CollData)
  branchl r12,0x803456a8


  bl Text_ecbCurrCorrect
  mflr r3
  branchl r12,0x803456a8
  bl Text_top
  mflr r3
  lwz r4,0xA4(REG_CollData)
  lwz r5,0xA8(REG_CollData)
  branchl r12,0x803456a8
  bl Text_bot
  mflr r3
  lwz r4,0xAC(REG_CollData)
  lwz r5,0xB0(REG_CollData)
  branchl r12,0x803456a8
  bl Text_right
  mflr r3
  lwz r4,0xB4(REG_CollData)
  lwz r5,0xB8(REG_CollData)
  branchl r12,0x803456a8
  bl Text_left
  mflr r3
  lwz r4,0xBC(REG_CollData)
  lwz r5,0xC0(REG_CollData)
  branchl r12,0x803456a8

b Exit


Text_NoGObj:
blrl
.string "no gobj for colldata\n"
.align 2

Text_NonFighterGObj:
blrl
.string "colldata has gobj type %d\n"
.align 2

Text_PlyInfo:
blrl
.string "ply: %d, ms: %d, prev_collflags: 0x%08x\nstate: %d, frame %.1f\n"
.align 2

Text_ecbCurr:
blrl
.string "ecbCurr:\n"
.align 2

Text_ecbCurrCorrect:
blrl
.string "ecbCurrCorrect:\n"
.align 2

Text_top:
blrl
.string " Top  : X: 0x%08x  Y: 0x%08x\n"
.align 2

Text_bot:
blrl
.string " Bot  : X: 0x%08x  Y: 0x%08x\n"
.align 2

Text_right:
blrl
.string " Right: X: 0x%08x  Y: 0x%08x\n"
.align 2

Text_left:
blrl
.string " Left : X: 0x%08x  Y: 0x%08x\n"
.align 2


Exit:
  restore
  subi	r3, r13, 32084
