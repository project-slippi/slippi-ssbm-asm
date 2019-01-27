#To be inserted at 800C9A44
.include "../../../Common/Common.s"

# Check for toggle bool
  lwz r4, 44(r3)
  lbz r4,0x618(r4)        #get player port
  subi r5,rtoc,UCFBools   #get UCF toggle bool base address
  lbzx r4,r4,r5	          #get players UCF toggle bool
  cmpwi r4,0x1
  bne loc_0x108

loc_0x0:
  lhz r4, 1000(r31)
  cmpwi r4, 0x4000
  bne- loc_0x108
  lwz r4, -20812(r13)
  lfs f1, 1568(r31)
  lfs f2, 9028(r31)
  fmuls f1, f1, f2
  lfs f2, 60(r4)
  fcmpo cr0, f1, f2
  cror 2, 1, 2
  bne- loc_0x108
  lbz r5, 1648(r31)
  cmpwi r5, 0x2
  bge- loc_0x108
  lbz r4, 8735(r31)
  rlwinm. r4, r4, 0, 28, 28
  beq+ loc_0x48
  b loc_0x108

loc_0x48:
  lis r4, 0x804C
  ori r4, r4, 0x1F78
  lbz r5, 1(r4)
  stb r5, -8(r1)
  b loc_0x94

loc_0x5C:
  subi r5, r5, 0x1
  cmpwi r5, 0x0
  bge- loc_0x6C
  addi r5, r5, 0x5

loc_0x6C:
  lis r4, 0x8046
  ori r4, r4, 0xB108
  mulli r5, r5, 0x30
  add r4, r4, r5
  lbz r5, 12(r31)
  mulli r5, r5, 0xC
  add r4, r4, r5
  lbz r5, 2(r4)
  extsb r5, r5
  blr

loc_0x94:
  subi r5, r5, 0x2
  bl loc_0x5C
  stw r5, -12(r1)
  lbz r5, -8(r1)
  bl loc_0x5C
  lwz r4, -12(r1)
  sub r5, r5, r4
  mullw r5, r5, r5
  cmpwi r5, 0x15F9
  ble- loc_0x108
  li r0, 0x1
  stw r0, 9048(r31)
  stw r0, 9024(r31)
  lbz r4, 7(r31)
  cmpwi r4, 0xA
  bne+ loc_0x108
  lwz r4, 16(r3)
  lwz r4, 44(r4)
  lwz r4, 7884(r4)
  stfs f0, 24(r4)
  lwz r5, 24(r4)
  lis r12, 0x3F80
  cmpw r5, r12
  beq- loc_0x100
  li r5, 0x80
  stb r5, 6(r4)
  b loc_0x108

loc_0x100:
  li r5, 0x7F
  stb r5, 6(r4)

loc_0x108:
  stfs f0, 44(r31)
