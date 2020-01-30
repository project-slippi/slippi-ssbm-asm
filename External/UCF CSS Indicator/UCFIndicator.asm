################################################################################
# Address: 802662D0
################################################################################
# Description: Indicates at the top of the CSS the version of UCF
################################################################################
.include "Common/Common.s"

.set text,31
.set textProperties,30

backup

#GET PROPERTIES TABLE
	bl TEXTPROPERTIES
	mflr textProperties

########################
## Create Text Object ##
########################

#CREATE TEXT OBJECT, RETURN POINTER TO STRUCT IN r3
	li r3,0
	li r4,0
	branchl r14, Text_CreateStruct

#BACKUP STRUCT POINTER
	mr text,r3

#SET TEXT SPACING TO TIGHT
	li r4,0x1
	stb r4,0x49(text)

#SET TEXT TO CENTER AROUND X LOCATION
	li r4,0x1
	stb r4,0x4A(text)

#Scale Canvas Down
	lfs f1,0xC(textProperties)
	stfs f1,0x24(text)
	stfs f1,0x28(text)

####################################
## INITIALIZE PROPERTIES AND TEXT ##
####################################

#Initialize Line of Text
	mr r3,text       #struct pointer
	bl 	TEXT
	mflr 	r4		#pointer to ASCII
	lfs f1,0x0(textProperties) #X offset of text
	lfs f2,0x4(textProperties) #Y offset of text
	branchl r14, Text_InitializeSubtext

#Set Size/Scaling
  mr  r4,r3
  mr	r3,text
	lfs   f1,0x8(textProperties) #get text scaling value from table
	lfs   f2,0x8(textProperties) #get text scaling value from table
  branchl	r12, Text_UpdateSubtextSize

b end


#**************************************************#
TEXTPROPERTIES:
blrl

.long 0x42180000 #x offset
.long 0xC3898000 #y offset
.long 0x3EE66666 #text scaling
.long 0x3DCCCCCD #canvas scaling


TEXT:
blrl
.string "UCF 0.74"
.align 2


#**************************************************#
end:

restore

addi	r4, r24, 0
