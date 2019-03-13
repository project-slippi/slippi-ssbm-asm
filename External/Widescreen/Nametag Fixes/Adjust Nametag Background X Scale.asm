#To be inserted at 802fcfc4

#Override X Scale
  bl  Floats
  mflr r3
  lfs f0,0x0(r3)
  b END

Floats:
blrl
.float 7.5

END:
