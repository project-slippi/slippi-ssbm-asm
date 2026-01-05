################################################################################
# Address: 0x800C0148 # Changes color to flash red
################################################################################

loc_0x0:
  addi r3, r31, 0x488
  lbz r12, 1380(r30)
  cmpwi r12, 0xD4
  beq- loc_0x14
  b loc_0x5C

loc_0x14:
  li r12, 0x91
  stb r12, 1380(r30)
  lis r12, 0x437F
  stw r12, 1304(r30)
  lis r12, 0xC200
  stw r12, 1316(r30)
  lis r12, 0x0
  stw r12, 1308(r30)
  stw r12, 1312(r30)
  stw r12, 1320(r30)
  stw r12, 1324(r30)
  stw r12, 1328(r30)
  lis r12, 0xC280
  stw r12, 1332(r30)
  lis r12, 0x800C
  ori r12, r12, 0x150
  mtctr r12
  bctr

loc_0x5C:
