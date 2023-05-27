################################################################################
# Address: 800998A4
################################################################################

loc_0x0:
  bl loc_0x3C
  stmw r26, -13107(r12)
  bc 21, 0, 0x8
  subi r6, r17, 0x48E9
  .word 0x00000000
  .word 0x00000000

loc_0x18:
  fabs f1, f1
  lfs f2, 4(r6)
  lfs f3, 8(r6)
  fmsubs f1, f1, f2, f3
  fctiwz f1, f1
  stfd f1, 12(r6)
  lwz r7, 16(r6)
  addi r7, r7, 0x2
  blr 

loc_0x3C:
  lwz r4, 44(r3)
  mflr r6
  lwz r5, -20812(r13)
  lfs f0, 1596(r4)
  lfs f1, 788(r5)
  fcmpo cr0, f0, f1
  ble- loc_0xC4
  lbz r0, 1648(r4)
  lwz r7, 800(r5)
  cmpw r0, r7
  blt- loc_0xC4
  lfs f1, 1572(r4)
  lfs f0, 0(r6)
  fcmpo cr0, f1, f0
  ble- loc_0xC4
  lwz r0, 2108(r4)
  cmpwi r0, 0xFFFF
  beq- loc_0xC4
  lwz r0, 2112(r4)
  rlwinm. r0, r0, 0, 23, 23
  beq- loc_0xC4
  bl loc_0x18
  mullw r0, r7, r7
  lfs f1, 1568(r4)
  bl loc_0x18
  mullw r7, r7, r7
  add r0, r0, r7
  cmpwi r0, 0x1900
  ble- loc_0xC4
  lwz r7, 28(r1)
  addi r1, r1, 0x18
  addi r7, r7, 0x8
  mtlr r7
  blr 

loc_0xC4:

