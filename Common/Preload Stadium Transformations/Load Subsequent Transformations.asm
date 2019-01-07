#To be inserted at 801d4f6c
.include "../Common.s"

.set PSData,31

#Load Transformation
  mr  r3,PSData
  branchl r12,0x80005600

#Exit
  li	r3, 85
