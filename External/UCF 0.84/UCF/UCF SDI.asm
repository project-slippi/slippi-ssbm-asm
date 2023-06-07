################################################################################
# Address: 8008E54C
# Tags: [affects-gameplay]
################################################################################

loc_0x0:
  cmpw r0, r5
  blt- loc_0xE0
  lbz r9, 1651(r3)
  cmplwi r9, 1
  ble- loc_0x24
  lbz r9, 1652(r3)
  lis r10, 0x6000
  cmplwi r9, 1
  bgt- loc_0xDC

loc_0x24:
  lfs f12, 1580(r3)
  lis r10, 0x6000
  lfs f0, 1576(r3)
  fmuls f12, f12, f12
  fmadds f0, f0, f0, f12
  lfs f12, 1200(r4)
  fmuls f12, f12, f12
  fcmpu cr0, f12, f0
  ble- loc_0xDC
  lis r8, 0x8007
  lbz r10, 1560(r3)
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
  subi r7, r8, 0x2
  add r8, r10, r8
  rlwinm r7, r7, 0, 30, 31
  rlwinm r8, r8, 1, 0, 30
  add r10, r10, r7
  add r6, r9, r8
  rlwinm r10, r10, 1, 0, 30
  lbzx r8, r9, r8
  add r7, r9, r10
  lbzx r9, r9, r10
  extsb r8, r8
  lbz r10, 1(r7)
  extsb r9, r9
  sub r9, r8, r9
  lbz r8, 1(r6)
  extsb r10, r10
  mullw r9, r9, r9
  extsb r8, r8
  sub r10, r8, r10
  mullw r10, r10, r10
  add r9, r9, r10
  lis r10, 0x6000
  cmpwi r9, 0x15F9
  ble- loc_0xDC
  lis r10, 0x8000

loc_0xDC:
  .long 0x7d580120

loc_0xE0:
