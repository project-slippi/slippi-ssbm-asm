################################################################################
# Address: 800C9A44
################################################################################

loc_0x0:
  lbz r9, 8735(r31)
  stfs f0, 44(r31)
  andi. r9, r9, 0x8
  bne- loc_0xFC
  lwz r10, 2196(r31)
  lis r9, 0x4000
  cmpw r10, r9
  bne- loc_0xFC
  lfs f12, 1568(r31)
  lwz r9, -20812(r13)
  fmuls f0, f0, f12
  lfs f12, 60(r9)
  fcmpu cr0, f0, f12
  blt- loc_0xFC
  lbz r9, 1648(r31)
  cmplwi r9, 1
  bgt- loc_0xFC
  lis r8, 0x8007
  lbz r10, 1560(r31)
  subi r8, r8, 0x52F0
  lwzu r9, 1040(r8)
  rlwinm r9, r9, 6, 0, 25
  srawi r9, r9, 6
  addi r9, r9, 0x4
  add r9, r9, r8
  mulli r8, r10, 0xC
  mulli r10, r10, 0x6
  add r8, r9, r8
  lbz r8, 8(r8)
  add r7, r10, r8
  subi r8, r8, 0x2
  rlwinm r8, r8, 0, 30, 31
  rlwinm r7, r7, 1, 0, 30
  add r10, r10, r8
  lbzx r7, r9, r7
  rlwinm r10, r10, 1, 0, 30
  lbzx r9, r9, r10
  extsb r7, r7
  extsb r9, r9
  sub r9, r7, r9
  mullw r9, r9, r9
  cmpwi r9, 0x15F9
  ble- loc_0xFC
  stwu r1, -8(r1)
  li r9, 0x1
  li r4, 0x1
  stw r9, 9024(r31)
  stw r9, 9048(r31)
  lis r9, 0x8003
  addi r9, r9, 0x418C
  lbz r3, 12(r31)
  mtctr r9
  bctrl 
  cmpwi r3, 0x0
  beq- loc_0xF8
  lwz r9, 44(r3)
  lwz r10, 7884(r9)
  lwz r9, 44(r31)
  stw r9, 24(r10)
  rlwinm r9, r9, 1, 31, 31
  addi r9, r9, 0x7F
  stb r9, 6(r10)

loc_0xF8:
  addi r1, r1, 0x8

loc_0xFC:

