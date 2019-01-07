#To be inserted at 80005600
.macro branchl reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctrl
.endm

.macro branch reg, address
lis \reg, \address @h
ori \reg,\reg,\address @l
mtctr \reg
bctr
.endm

.macro load reg, address
lis \reg, \address @h
ori \reg, \reg, \address @l
.endm

.macro loadf regf,reg,address
lis \reg, \address @h
ori \reg, \reg, \address @l
stw \reg,-0x4(sp)
lfs \regf,-0x4(sp)
.endm

.macro backup
mflr r0
stw r0, 0x4(r1)
stwu	r1,-0x100(r1)	# make space for 12 registers
stmw  r20,0x8(r1)
.endm

.macro restore
lmw  r20,0x8(r1)
lwz r0, 0x104(r1)
addi	r1,r1,0x100	# release the space
mtlr r0
.endm

.set HSD_Randi,0x80380580
.set PSData,31

backup
mr  PSData,r3

DecideTransformation:
#Decide initial transformation
  li  r3,4
  branchl r12,HSD_Randi
#Check if something
  rlwinm	r0, r3, 2, 0, 29
  lha	r3, 0x00E2 (PSData)
  load r4,0x803b7f9c
  lwzx	r4, r4, r0
  cmpw r3,r4
  beq DecideTransformation
#Store to 0xEC of PSData (stage GObjs are always 500-something bytes long, it has tons of extra space thankfully)
  stw r4,0xEC(PSData)

LoadTransformation:
#Get other ID for transformation ID
  cmpwi	r4, 3
  bne-	Check4
  li	r4, 0
  b	GetFileString
  Check4:
  cmpwi	r4, 4
  bne-	Check9
  li	r4, 1
  b	GetFileString
  Check9:
  cmpwi	r4, 9
  bne-  Check6
  li	r4, 2
  b	GetFileString
  Check6:
  cmpwi	r4, 6
  bne-  Exit
  li	r4, 3
  b	GetFileString
GetFileString:
#Get transformation file string
  load r3,0x803e1248  #Static PS Struct
  rlwinm	r0, r4, 2, 0, 29
  add	r3, r3, r0
  lwz	r3, 0x03D8 (r3)
#Setup async file load call
  lwz r4,0xCC(PSData) #dedicated mem for transformation
  addi  r5,PSData,200 #unk
  load r6,0x801d4220  #callback
  li  r7,0
  branchl r12,0x80016580

Exit:
restore
blr
