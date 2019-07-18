#To be inserted at 803775a4
.include "../../../Common/Common.s"

#Check if currently unplugged
  lbz	r3, 0x000A (r25)    #Get current plugged in bool
  extsb r0,r3
  cmpwi r0,-1
  bne Original
#Check if just unplugged
  lbz	r0, 0x0041 (r26)    #Get previous poll's plugged in bool
  cmpw r3,r0
  beq Original

#Remove players nametag ID
  load r3,0x80480820      #get VS Mode CSS data
  mulli r4,r24,12
  add r4,r3,r4
  li  r3,120
  stb r3,0xA(r4)          #nametag ID
#Remove players nametag ID in the backup too
  lwz	r4, -0x77C0 (r13)
  addi r4,r4,1424+0x68
  mulli r5,r24,0x24
  add r4,r4,r5
  stb r3,0xA(r4)
#Check if major scene == VS mode
  load r4,0x80479D30
  lbz r3,0x0(r4)
  cmpwi r3,2
  bne Original
#Check if minor scene == CSS
  lbz r3,0x3(r4)
  cmpwi r3,0x0
  bne Original
#Check if CSS scene == 0 (not rules or name entry)
  lbz	r3, -0x49AA (r13)
  cmpwi r3,0
  bne Original
#Reset isUsingNametag bool
  load r4,0x803f0e8c
  mulli r3,r24,0xC
  add r3,r3,r4
  lwz r4,0x0(r3)      #pointer to CSS window gobj
  li  r3,0
  stb r3,0x1B(r4)

Original:
  lbz	r0, 0x000A (r25)
