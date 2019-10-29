################################################################################
# Address: 80261a6c
################################################################################
#Credit Achilles1515
.include "Common/Common.s"

#Check
  lbz	r5, 0x0005 (r31)
  cmpwi	r5, 2
  bne Exit
#Skip Code
  branch r12,0x80261B6C

Exit:
  mulli	r0, r19, 36
