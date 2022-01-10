################################################################################
# Address: FN_ShouldRecord # 0x80005604 from Recording.s
################################################################################
.include "Common/Common.s"
.include "Recording/Recording.s"

  getMinorMajor r3
  cmpwi r3, 0x0202 # Versus
  beq ReturnTrue
  cmpwi r3, 0x0302 # Sudden Death
  beq ReturnTrue
  cmpwi r3, 0x0208 # Versus Online
  beq ReturnTrue
  cmpwi r3, 0x010f # Break the Targets
  beq ReturnTrue

ReturnFalse:
  li  r3,0
  b Exit

ReturnTrue:
  li  r3,1
  b Exit

Exit:
  blr
