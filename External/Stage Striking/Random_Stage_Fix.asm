################################################################################
# Address: 80259B84
################################################################################

loc_0x0:
  rlwinm. r0, r3, 0, 24, 31
  beq- loc_0x3C
  mulli r4, r30, 0x1C
  addi r0, r4, 0x8
  lbzx r0, r31, r0
  cmpwi r0, 0x0
  bne- loc_0x3C
  li r0, 0x1D
  mtctr r0
  li r3, 0x0
  addi r4, r31, 0x0

loc_0x2C:
  stw r3, 4(r4)
  addi r4, r4, 0x1C
  bdnz+ loc_0x2C
  cmpwi r3, 0x0

loc_0x3C:
