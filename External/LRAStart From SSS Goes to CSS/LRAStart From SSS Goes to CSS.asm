#To be inserted at 8025B8BC
.include "../../Common/Common.s"

#Load first minor of current major
  load r3,0x80479d30
  lbz r3,0x0(r3)
