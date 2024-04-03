################################################################################
# Address: 0x802FC9E4
################################################################################

loc_0x0:
  addi r28, r4, 0x0
  mflr r0
  stw r0, 4(r1)
  stwu r1, -176(r1)
  stmw r20, 8(r1)
  mr r30, r3
  lis r3, 0x8048
  lwz r3, -25296(r3)
  rlwinm r3, r3, 8, 16, 31
  cmpwi r3, 0x208
  bne- loc_0xCC
  lis r12, 0x8016
  ori r12, r12, 0xB168
  mtctr r12
  bctrl 
  cmpwi r3, 0x0
  beq- loc_0xCC
  lwz r3, -18916(r13)
  lbz r3, 0(r3)
  cmpw r3, r30
  beq- loc_0xCC
  lis r12, 0x8003
  ori r12, r12, 0x3370
  mtctr r12
  bctrl 
  mr r29, r3
  mr r3, r30
  lis r12, 0x8003
  ori r12, r12, 0x3370
  mtctr r12
  bctrl 
  cmpw r3, r29
  bne- loc_0xCC
  mulli r3, r30, 0xE
  lis r4, 0x8046
  ori r4, r4, 0xB6A0
  add r5, r3, r4
  lbz r3, 60(r5)
  ori r3, r3, 0x10
  stb r3, 60(r5)
  mulli r3, r29, 0x4
  add r3, r3, r31
  lfs f1, 100(r3)
  lmw r20, 8(r1)
  lwz r0, 180(r1)
  addi r1, r1, 0xB0
  mtlr r0
  lis r12, 0x802F
  ori r12, r12, 0xCA84
  mtctr r12
  bctr 

loc_0xCC:
  mr r3, r30
  lmw r20, 8(r1)
  lwz r0, 180(r1)
  addi r1, r1, 0xB0
  mtlr r0