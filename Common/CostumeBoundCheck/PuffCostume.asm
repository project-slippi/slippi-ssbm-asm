################################################################################
# Address: 8013c388
################################################################################
.include "Common/Common.s"

  lwz	r30, 0x002C (r28)

# check if over max costume
  lbz r3,0xC(r30)
  branchl r12,0x80032330
  branchl r12,0x80169238
  lbz r4,0x619(r30)
  cmpw r4,r3
  bge Skip
  b Exit

Skip:
  branch r12,0x8013c46c

Exit:
  lwz	r4, 0x002C (r28)
