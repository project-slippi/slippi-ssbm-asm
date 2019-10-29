################################################################################
# Address: 8010fc44
################################################################################
.include "Common/Common.s"

#Check if PAL
  lbz r4,PALToggle(rtoc)
  cmpwi r4,0x0
  beq original

  load r0,0x80110074     #callback to remove GFX
  b exit

original:
  subi	r0, r3, 10380    #callback to remove GFX and punch charge

exit:
