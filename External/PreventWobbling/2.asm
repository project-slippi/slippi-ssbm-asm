################################################################################
# Address: 0x8008F090
# Tags: [alters-gameplay]
################################################################################

loc_0x0:
  lwz r3, 16(r27)
  cmpwi r3, 0xDF
  blt- loc_0xDC
  cmpwi r3, 0xE4
  bgt- loc_0xDC
  lwz r3, 6744(r27)
  cmpwi r3, 0x0
  beq- loc_0xDC
  lwz r3, 44(r3)
  lbz r4, 8738(r3)
  rlwinm. r4, r4, 0, 29, 29
  beq- loc_0xDC
  lbz r3, 12(r3)
  li r4, 0x1
  lis r12, 0x8003
  ori r12, r12, 0x418C
  mtctr r12
  bctrl 
  cmpwi r3, 0x0
  beq- loc_0xDC
  lwz r4, 6248(r27)
  cmpw r3, r4
  beq- loc_0x8C
  lhz r5, 0(r4)
  cmpwi r5, 0x6
  bne- loc_0xDC
  lwz r5, 44(r4)
  lwz r4, 1304(r5)
  cmpw r3, r4
  bne- loc_0xDC
  lhz r3, 3496(r5)
  lhz r4, 9042(r27)
  cmpw r3, r4
  beq- loc_0xDC
  b loc_0xA0

loc_0x8C:
  lwz r5, 44(r3)
  lhz r3, 8328(r5)
  lhz r4, 9042(r27)
  cmpw r3, r4
  beq- loc_0xDC

loc_0xA0:
  sth r3, 9042(r27)
  lbz r3, 9040(r27)
  addi r3, r3, 0x1
  stb r3, 9040(r27)
  cmpwi r3, 0x3
  blt- loc_0xDC
  lwz r3, 6744(r27)
  lis r12, 0x800D
  ori r12, r12, 0xA698
  mtctr r12
  bctrl 
  lis r12, 0x8008
  ori r12, r12, 0xF0C8
  mtctr r12
  bctr 

loc_0xDC:
  lwz r0, 16(r27)

