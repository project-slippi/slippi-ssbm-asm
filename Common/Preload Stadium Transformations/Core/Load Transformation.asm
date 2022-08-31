################################################################################
# Address: 801d45ec
# Tags: [affects-gameplay]
################################################################################
.include "Common/Common.s"
.include "Common/Preload Stadium Transformations/Transformation.s"

.set PSData,31

#Check if Transformation is decided/loaded
  lbz r3,isLoaded(PSData)
  cmpwi r3,0
  bne Original

DecideTransformation:
#Decide initial transformation
  li  r3,4
  branchl r12, HSD_Randi
#Check if something
  rlwinm	r0, r3, 2, 0, 29
  lha	r3, 0x00E2 (PSData)
  load r4,0x803b7f9c
  lwzx	r4, r4, r0
  cmpw r3,r4
  beq DecideTransformation
#Store to 0xEC of PSData (stage GObjs are always 500-something bytes long, it has tons of extra space thankfully)
  stw r4,TransformationID(PSData)

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
  branchl r12, FileLoad_ToPreAllocatedSpace

#Set as loaded
  li  r3,1
  stb r3,isLoaded(PSData)

Original:
  lwz	r3, 0x00D8 (r31)
