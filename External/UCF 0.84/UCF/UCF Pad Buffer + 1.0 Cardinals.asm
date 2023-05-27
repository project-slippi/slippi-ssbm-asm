################################################################################
# Address: 8006B460
################################################################################

loc_0x0:
  bl loc_0xB0
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .long 0x00000000
  .float -0.609375
  .float 0.0001
  .float 80

loc_0x40:
  addi r9, r3, 0x4F
  rlwinm r9, r9, 0, 24, 31
  cmplwi r9, 158
  ble- loc_0x78
  addi r4, r4, 0x6
  rlwinm r4, r4, 0, 24, 31
  cmplwi r4, 12
  bgtlr- 
  rlwinm r3, r3, 0, 0, 0
  li r9, 0x0
  xoris r3, r3, 16256
  stw r9, 4(r5)
  stw r3, 0(r5)
  blr 

loc_0x78:
  addi r9, r4, 0x4F
  rlwinm r9, r9, 0, 24, 31
  cmplwi r9, 158
  blelr- 
  addi r3, r3, 0x6
  rlwinm r3, r3, 0, 24, 31
  cmplwi r3, 12
  bgtlr- 
  rlwinm r4, r4, 0, 0, 0
  li r9, 0x0
  xoris r4, r4, 16256
  stw r9, 0(r5)
  stw r4, 4(r5)
  blr 

loc_0xB0:
  stwu r1, -64(r1)
  stmw r25, 36(r1)
  stw r28, 20(r1)
  mflr r28
  lis r9, 0x800A
  mr r3, r31
  addi r9, r9, 0x2040
  mtctr r9
  bctrl 
  cmpwi r3, 0x0
  bne- loc_0x278
  lis r9, 0x804C
  lbz r30, 1560(r31)
  addi r9, r9, 0x1F78
  mr r26, r31
  lbz r8, 1(r9)
  cmpwi r8, 0x0
  subi r10, r8, 0x1
  bne+ loc_0x100
  li r10, 0x4

loc_0x100:
  mulli r10, r10, 0x30
  lwz r9, 8(r9)
  mulli r27, r30, 0xC
  addi r29, r28, 0x0
  add r9, r9, r10
  mulli r30, r30, 0x6
  add r8, r9, r27
  lwzx r10, r9, r27
  lwz r9, 8(r8)
  lwz r7, 4(r8)
  add r8, r29, r27
  stw r9, 16(r1)
  lbz r9, 8(r8)
  stw r10, 8(r1)
  addi r9, r9, 0x1
  stw r7, 12(r1)
  rlwinm r9, r9, 0, 30, 31
  stb r9, 8(r8)
  rlwinm r25, r9, 0, 24, 31
  add r9, r30, r9
  rlwinm r9, r9, 1, 0, 30
  sthx r10, r29, r9
  lwz r9, 4(r26)
  cmpwi r9, 0x13
  bne+ loc_0x170
  lwz r9, 16(r26)
  cmpwi r9, 0x15D
  beq+ loc_0x1A0

loc_0x170:
  lbz r4, 11(r1)
  addi r5, r26, 0x620
  lbz r3, 10(r1)
  extsb r4, r4
  extsb r3, r3
  bl loc_0x40
  lbz r4, 13(r1)
  lbz r3, 12(r1)
  addi r5, r26, 0x638
  extsb r4, r4
  extsb r3, r3
  bl loc_0x40

loc_0x1A0:
  lfs f0, 1572(r26)
  li r10, 0x0
  lfs f12, 48(r28)
  fcmpu cr0, f0, f12
  bgt- loc_0x270
  lfs f12, 1568(r26)
  fabs f0, f0
  lfs f10, 56(r28)
  addi r9, r1, 0x18
  fabs f12, f12
  lfs f11, 52(r28)
  fmsubs f0, f0, f10, f11
  fmsubs f12, f12, f10, f11
  fctiwz f0, f0
  fctiwz f12, f12
  stfiwx f12, 0, r9
  addi r9, r1, 0x1C
  lwz r8, 24(r1)
  stfiwx f0, 0, r9
  addi r8, r8, 0x2
  lwz r9, 28(r1)
  mullw r8, r8, r8
  addi r9, r9, 0x2
  mullw r9, r9, r9
  add r9, r9, r8
  cmpwi r9, 0x1900
  ble- loc_0x270
  add r9, r29, r27
  lbz r10, 9(r9)
  rlwinm r9, r10, 0, 24, 31
  cmpwi r9, 0x0
  bne- loc_0x26C
  lbz r9, 1649(r26)
  cmplwi r9, 1
  bgt+ loc_0x270
  subi r9, r25, 0x2
  add r8, r30, r25
  rlwinm r9, r9, 0, 30, 31
  rlwinm r8, r8, 1, 0, 30
  add r30, r30, r9
  add r8, r29, r8
  rlwinm r30, r30, 1, 0, 30
  lbz r8, 1(r8)
  add r30, r29, r30
  lbz r9, 1(r30)
  extsb r8, r8
  extsb r9, r9
  sub r9, r8, r9
  mullw r9, r9, r9
  cmpwi r9, 0x790
  ble- loc_0x270

loc_0x26C:
  addi r10, r10, 0x1

loc_0x270:
  add r29, r29, r27
  stb r10, 9(r29)

loc_0x278:
  lbz r3, 1656(r31)
  lwz r28, 20(r1)
  lwz r25, 36(r1)
  lwz r26, 40(r1)
  lwz r27, 44(r1)
  lwz r29, 52(r1)
  lwz r30, 56(r1)
  addi r1, r1, 0x40

