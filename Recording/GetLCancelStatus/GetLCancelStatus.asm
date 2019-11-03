################################################################################
# Address: 8008d698
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

#Check if L-Cancelled
  cmpw	r5, r0
  bge FailedLCancel

SucceededLCancel:
  li  r7,1
  b StoreLCancelStatus
FailedLCancel:
  li  r7,2
StoreLCancelStatus:
  lwz r8,0x2C(r3)
  stb r7,LCancelStatus(r8)

#Original
  cmpw	r5, r0
