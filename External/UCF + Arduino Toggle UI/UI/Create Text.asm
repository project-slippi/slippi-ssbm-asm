################################################################################
# Address: 802652ec
################################################################################
.include "Common/Common.s"

.set text,31
.set textProperties,30

backup

#GET PROPERTIES TABLE
  bl TEXTPROPERTIES
  mflr textProperties

#CREATE TEXT OBJECT, RETURN POINTER TO STRUCT IN r3
	li r3,0
	li r4,0
	branchl r12, Text_CreateStruct

#BACKUP STRUCT POINTER
	mr text,r3

#####################
## Create UCF Text ##
#####################

	#convert player number into float (f1)
		mr    r3,r29
		bl	IntToFloat

	#Get Correct Y Offset
		lfs f2,0xC(textProperties) #distance between players
		fmuls f1,f1,f2  #multiply by player number
		lfs f2,0x0(textProperties) #X offset of text
		fadds f1,f1,f2  #add player offset to original offset
		lfs f2,0x4(textProperties) #Y offset of text

	#Create Text
		mr r3,text       #struct pointer
		bl TEXT.UCF
		mflr r4 #pointer to ASCII
		branchl r12, Text_InitializeSubtext

########################
## Create On/Off Text ##
########################

	#Convert player number into float (f1)
		mr    r3,r29
		bl	IntToFloat

	#Get Correct Y Offset
		lfs f2,0xC(textProperties) #distance between players
		fmuls f1,f1,f2  #multiply by player number
		lfs f2,0x10(textProperties) #X offset of text
		fadds f1,f1,f2  #add player offset to original offset
		lfs f2,0x14(textProperties) #Y offset of On/Off

	#Create Text
		mr r3,text       #struct pointer
		bl TEXT.OFF
		mflr r4 #pointer to ASCII
		branchl r12, Text_InitializeSubtext

	#SET TEXT SPACING TO TIGHT
		li r4,0x1
		stb r4,0x49(text)

  #SET TEXT TO CENTER AROUND X
    li r4,0x1
    stb r4,0x4A(text)

	#SET DEFAULT AS INVISIBLE
		li r4,0x1
		stb r4,0x4D(text)

	#set size/scaling
		lfs   f1,0x8(textProperties) #get text scaling value from table
		stfs f1,0x24(text) #store text scale X
		stfs f1,0x28(text) #store text scale Y

	#store pointers to r13 (start at 804d6700)
		subi r3,r13,UCFTextPointers
		mulli r4,r29,0x4
		stwx text,r3,r4

b end

#**************************************************#
TEXTPROPERTIES:
blrl
.long 0xc3dc0000 #x offset of "UCF" (-500)
.long 0x43EA0000 #y offset of "UCF" (464)
.long 0x3D3851EC #text scaling
.long 0x43AC8000 #distance between players (350)
.long 0xC3DC0000 #x offset of Toggle Status (-500)
.long 0x43FA0000 #y offset of Toggle Status (500)

TEXT.UCF:
blrl
.string "Fixes:"
.align 2

TEXT.OFF:
blrl
.string "Off"
.align 2

#**************************************************#

IntToFloat:
stwu	r1,-0x100(r1)	# make space for 12 registers
stfs  f2,0x8(r1)

lis	r0, 0x4330
lfd	f2, -0x6758 (rtoc)
xoris	r3, r3,0x8000
stw	r0,0xF0(sp)
stw	r3,0xF4(sp)
lfd	f1,0xF0(sp)
fsubs	f1,f1,f2		#Convert To Float

lfs  f2,0x8(r1)
addi	r1,r1,0x100	# release the space
blr

#**************************************************#
end:

restore
li	r3, 0
