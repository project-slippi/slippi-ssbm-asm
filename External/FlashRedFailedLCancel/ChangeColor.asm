################################################################################
# Address: 0x800C0148 # Changes color to flash red
################################################################################

loc_0x0:
  addi r3, r31, 0x488
  lbz r15, 1380(r30)
  cmpwi r15, 0xD4
  beq- loc_0x14
  b loc_0x5C

loc_0x14:
  li r15, 0x91
  stb r15, 1380(r30)
  lis r15, 0x437F
  stw r15, 1304(r30)
  lis r15, 0xC200
  stw r15, 1316(r30)
  lis r15, 0x0
  stw r15, 1308(r30)
  stw r15, 1312(r30)
  stw r15, 1320(r30)
  stw r15, 1324(r30)
  stw r15, 1328(r30)
  lis r15, 0xC280
  stw r15, 1332(r30)
  lis r15, 0x800C
  ori r15, r15, 0x150
  mtctr r15
  bctr

loc_0x5C:
