################################################################################
# Address: 8009A0B8
# Tags: [affects-gameplay]
################################################################################

loc_0x0:
  bl loc_0x9C
  .float -0.609375
  .float 0.0001
  .float 80
  
loc_0x10:
  lfs f0, 0(r3)
  lfs f11, 8(r30)
  fabs f0, f0
  lfs f12, 4(r30)
  stwu r1, -16(r1)
  fmsubs f0, f0, f11, f12
  addi r9, r1, 0x8
  addi r10, r1, 0xC
  fctiwz f0, f0
  stfiwx f0, 0, r9
  lfs f0, 4(r3)
  lwz r9, 8(r1)
  fabs f0, f0
  addi r9, r9, 0x2
  mullw r9, r9, r9
  fmsubs f0, f0, f11, f12
  fctiwz f0, f0
  stfiwx f0, 0, r10
  lwz r3, 12(r1)
  addi r1, r1, 0x10
  addi r3, r3, 0x2
  mullw r3, r3, r3
  add r3, r3, r9
  subi r9, r3, 0x1901
  nor r3, r3, r9
  rlwinm r3, r3, 1, 31, 31
  blr 

loc_0x7C:
  lfs f12, 4(r3)
  lfs f0, 0(r30)
  fcmpu cr0, f12, f0
  cror 2, 1, 3
  beq+ loc_0x94
  b loc_0x10

loc_0x94:
  li r3, 0x0
  blr 

loc_0x9C:
  stwu r1, -40(r1)
  stw r29, 28(r1)
  stw r30, 8(r1)
  mflr r30
  cror 2, 0, 2
  beq- loc_0xD8
  lbz r9, 1649(r4)
  mr r29, r4
  cmplwi r9, 2
  bgt+ loc_0xD4
  addi r3, r4, 0x620
  bl loc_0x7C
  cmpwi r3, 0x0
  bne- loc_0xE8

loc_0xD4:
  #crclr 2, 2
  .float 50873864

loc_0xD8:
  lwz r30, 8(r1)
  lwz r29, 28(r1)
  addi r1, r1, 0x28
  b loc_0x100

loc_0xE8:
  addi r3, r29, 0x628
  bl loc_0x7C
  cmpwi r3, 0x0
  beq- loc_0xD4
  #crset 2, 2
  .float 50874632
  b loc_0xD8

loc_0x100:

