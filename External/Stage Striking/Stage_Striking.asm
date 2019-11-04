################################################################################
# Address: 80259C40
################################################################################

loc_0x0:
  li r11, 0x0
  lis r10, 0x8045
  ori r10, r10, 0xC388
  li r3, 0x0
  lis r4, 0x803F
  ori r4, r4, 0x6D0
  cmplwi r0, 19
  bne- loc_0x28
  li r11, 0x1
  b loc_0x34

loc_0x28:
  cmplwi r0, 0
  bne- loc_0xEC
  b loc_0x64

loc_0x34:
  cmpwi r3, 0x1D
  bge- loc_0xEC
  cmpwi r11, 0x2
  beq- loc_0x8C
  mulli r5, r3, 0x1C
  add r5, r5, r4
  lbz r6, 10(r5)
  lwz r5, 0(r10)
  srw r5, r5, r6
  rlwinm. r5, r5, 0, 31, 31
  bne- loc_0xE4
  b loc_0x8C

loc_0x64:
  lwz r3, -18944(r13)
  rlwinm. r0, r3, 0, 21, 21
  bne- loc_0x88
  rlwinm. r0, r3, 0, 27, 27
  bne- loc_0x7C
  b loc_0xEC

loc_0x7C:
  li r11, 0x2
  li r3, 0x0
  b loc_0x34

loc_0x88:
  lbz r3, -18930(r13)

loc_0x8C:
  cmpwi r3, 0x1D
  bge- loc_0xEC
  mulli r5, r3, 0x1C
  add r5, r5, r4
  li r6, 0x0
  cmpwi r11, 0x2
  bne- loc_0xAC
  li r6, 0x2

loc_0xAC:
  stb r6, 8(r5)
  lwz r5, 0(r5)
  cmpwi r3, 0x16
  blt- loc_0xC0
  lwz r5, 16(r5)

loc_0xC0:
  lis r6, 0x4400
  cmpwi r11, 0x2
  bne- loc_0xD0
  li r6, 0x0

loc_0xD0:
  stw r6, 56(r5)
  li r6, 0x1E
  stb r6, -18930(r13)
  cmpwi r11, 0x0
  beq- loc_0xEC

loc_0xE4:
  addi r3, r3, 0x1
  b loc_0x34

loc_0xEC:
  cmplwi r0, 0
