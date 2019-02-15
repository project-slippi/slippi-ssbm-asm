#To be inserted at 802fccd8
.include "../../Common/Common.s"

#Check if Doubles
  load r3,0x8046b6a0
  lbz r3,0x24D0(r3)
  cmpwi r3, 0x1
  beq Original
#Get PLayer
  lbz r3, 0(r31)
  branchl r12,0x80034110
#Get Player Data
  lwz r3,0x2C(r3)
#Get Invis Bit
  lbz r3,0x221E(r3)
  rlwinm. r3, r3, 0, 24, 24
  beq- Original
#Is Invisible, Hide Tag
  lis r12, 0x802F
  ori r12, r12, 0xCCC8
  mtctr r12
  bctr

Original:
  cmplwi	r30, 0
