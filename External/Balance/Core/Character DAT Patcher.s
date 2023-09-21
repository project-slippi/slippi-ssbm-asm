################################################################################
# Address: 80068f30
################################################################################
.include "Common/Common.s"

backup

lwz r31,0x10C(r30)
lwz r31,0x8(r31)
subi r31,r31,0x20
lwz r3,0x0(r29)			#get character internal ID
cmpwi r3,0x1b			#check if master hand, crazy hand, wireframes, giga or sandbag
bge exit			#exit if so

bl SkipTable
bl diffMario
bl diffFox
bl diffCaptain
bl diffDK
bl diffKirby
bl diffBowser
bl diffLink
bl diffSheik
bl diffNess
bl diffPeach
bl diffPopo
bl diffNana
bl diffPikachu
bl diffSamus
bl diffYoshi
bl diffJigglypuff
bl diffMewtwo
bl diffLuigi
bl diffMarth
bl diffZelda
bl diffYLink
bl diffDoc
bl diffFalco
bl diffPichu
bl diffGaW
bl diffGanon
bl diffRoy

SkipTable:
mflr	r4		#Jump Table Start in r4
mulli	r3,r3,0x4		#Each Pointer is 0x4 Long
add	r4,r4,r3		#Get Event's Pointer Address
lwz	r5,0x0(r4)		#Get bl Instruction
rlwinm	r5,r5,0,6,29		#Mask Bits 6-29 (the offset)
add	r5,r4,r5		#Gets Address in r4

################
## Patch Loop ##
################

continue:
patchLoop:
lwz r3,0x0(r5)
lwz r4,0x4(r5)

cmpwi r3,0xFF
beq endPatchLoop

add r3,r3,r31
stw r4,0x0(r3)
addi r5,r5,0x8
b patchLoop

endPatchLoop:
b exit


#################
## DIFF TABLES ##
#################
diffMario:

.long 0x000000FF

diffFox:

.long 0x000000FF

diffCaptain:

.long 0x000000FF

diffDK:

.long 0x000000FF

diffKirby:

.long 0x000000FF

diffBowser:

.long 0x000000FF

diffLink:

.long 0x000000FF

diffSheik:

.long 0x000000FF

diffNess:

.long 0x000000FF

diffPeach:

.long 0x000000FF

diffPopo:

.long 0x000000FF

diffNana:

.long 0x000000FF


diffPikachu:

.long 0x000000FF

diffSamus:

.long 0x000000FF

diffYoshi:

.long 0x000000FF

diffJigglypuff:

.long 0x00003914
.long 0x00000003 # Number of Jumps
.long 0x000000FF

diffMewtwo:

.long 0x000000FF

diffLuigi:

.long 0x000000FF

diffMarth:

.long 0x000000FF

diffZelda:

.long 0x000000FF

diffYLink:

.long 0x000000FF

diffDoc:

.long 0x000000FF

diffFalco:

.long 0x000000FF

diffPichu:

.long 0x000000FF

diffGaW:

.long 0x000000FF

diffGanon:

.long 0x000000FF

diffRoy:

.long 0x000000FF

exit:
restore

original:
lis	r3, 0x803C
