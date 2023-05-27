################################################################################
# Address: 80093294
################################################################################

loc_0x0:
  cmpw r3, r0
  blt- loc_0x98
  lbz r9, 1651(r4)
  lis r6, 0x6000
  cmplwi r9, 1
  bgt- loc_0x94
  lfs f12, 1576(r4)
  lfs f0, 1200(r5)
  fcmpu cr0, f12, f0
  bge- loc_0x94
  lis r8, 0x8007
  lbz r10, 1560(r4)
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
  ble- loc_0x94
  lis r6, 0x8000

loc_0x94:
  .word 0x7cd80120

loc_0x98:
