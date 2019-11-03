################################################################################
# Address: 800998a4
################################################################################
.include "Common/Common.s"

.set  REG_PlayerData,31
.set  REG_PlayerGObj,30
.set  REG_Floats,29

backup

#Init
  mr  REG_PlayerGObj,r3
  lwz REG_PlayerData,0x2C(REG_PlayerGObj)
  bl  Floats
  mflr  REG_Floats

# Check for toggle bool
  lbz r4,0x618(r31)          #get player port
  subi r3,rtoc,ControllerFixOptions     #get UCF toggle bool base address
  lbzx r3,r3,r4	            #get players UCF toggle bool
  cmpwi r3,0x1
  beq Start # if equal, skip to start of handler
# Check for dashback bool (set by slp playback)
  subi r3,rtoc,ShieldDropOptions     #get UCF toggle bool base address
  lbzx r3,r3,r4	            #get players ShieldDrop toggle bool
  cmpwi r3,0x1
  bne EnterSpotdodge

Start:
#Check if cstick is
  lfs f1, 0x63C (REG_PlayerData)
  lwz	r3, -0x514C (r13)
  lfs f0, 0x314 (r3)
  fcmpo cr0, f1, f0
  ble- EnterSpotdodge

#Check if left stick X is ?
  lfs f1, 0x620(REG_PlayerData)
  bl  DoSomething
  stfs  f1,0x90(sp)
#Check if left stick Y is ?
  lfs f1, 0x624(REG_PlayerData)
  bl  DoSomething
  lfs  f2,0x90(sp)

#Check if stick was pushed slow enough?
  fmuls f2, f2, f2
  fmuls f1, f1, f1
  fadds f1, f1, f2
  lfs f2,OFST_1fp(REG_Floats)
  fcmpo cr0, f1, f2
  blt EnterSpotdodge
#Check if stick has been pushed horizontally for over 3 frames
  lbz r4, 0x670(REG_PlayerData)
  cmpwi r4, 3
  ble- EnterSpotdodge
#Check if stick Y is below -0.8
  lfs f0,OFST_Unk4(REG_Floats)
  lfs f1, 0x624(REG_PlayerData)
  fcmpo cr0, f0, f1
  bge- EnterSpotdodge

#Exit spotdodge function without entering the state
# this is very hacky and is how UCF 0.73 functions.
# the reason this is in place is because the spotdodge function is called
# from 2 different places, so instead of making 2 injections, this is done.
	restore
  lwz	r3, 0x001C (sp)
	lwz	r31, 0x0014 (sp)
	addi	sp, sp, 24
	addi	r3,r3,0x8			#skip to the end of the function we are coming from
	mtlr	r3
	blr

#############################
DoSomething:
#f1 = input

  fabs f0, f1
#Multiply by 80
  lfs f1,OFST_Unk1(REG_Floats)
  fmuls f0, f0, f1
#Subtract 0.0001
  lfs f1,OFST_Unk2(REG_Floats)
  fsubs f0, f0, f1
#Floor value
  fctiwz  f0,f0
  stfd  f0,0x80(sp)
  lwz r3,0x84(sp)
#Add 2
  addi  r3,r3,2
#Cast back
  lis	r0, 0x4330
  lfd	f2, OFST_MagicNumber (REG_Floats)
  xoris	r3, r3,0x8000
  stw	r0,0x80(sp)
  stw	r3,0x84(sp)
  lfd	f1,0x80(sp)
  fsubs	f0,f1,f2		#Convert To Float
#Divide by 80
  lfs f1,OFST_Unk1(REG_Floats)
  fdivs f1, f0, f1
#Exit
  blr
#############################

Floats:
blrl
.set  OFST_Unk1,0x0
.set  OFST_Unk2,0x4
.set  OFST_Unk3,0x8
.set  OFST_1fp,0xC
.set  OFST_Unk4,0x10
.set  OFST_MagicNumber,0x14
.float 80
.long 0x37270000
.float 176
.float 1
.float -0.8
.long 0x43300000
.long 0x80000000

EnterSpotdodge:
  mr	r3, REG_PlayerGObj
	mr	r4,	REG_PlayerData
  restore
