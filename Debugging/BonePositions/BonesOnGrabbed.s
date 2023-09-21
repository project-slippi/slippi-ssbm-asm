################################################################################
# Address: 0x800db040
################################################################################

.include "Common/Common.s"

backup

li r27, 0

LOOP:
# Load linked player entity address
lwz r3, 0x2c(r30) # char data for main fighter
lwz r3, 0x1a58(r3) # linked fighter entity (grabber)
mr r4, r27
branchl r12, 0x80086630 # BoneId -> Jobj Address
mr r28, r3 # Move jobj address to r28
li r4, 0
addi r5, sp, BKP_FREE_SPACE_OFFSET
branchl r12, 0x8000b1cc # GetEntityPosition

lwz r5, frameIndex(r13)
mr r6, r27
lfs f1, 44(r28) # Get scaleX
lfs f2, 48(r28) # Get scaleY
lfs f3, 52(r28) # Get scaleZ
lfs f4, BKP_FREE_SPACE_OFFSET(sp) # Get posX
lfs f5, BKP_FREE_SPACE_OFFSET+4(sp) # Get posY
lfs f6, BKP_FREE_SPACE_OFFSET+8(sp) # Get posZ
logf LOG_LEVEL_WARN, "[%d] [BonePosThrown] Idx: %d, Scale: (%f, %f, %f), Pos: (%f, %f, %f)"

addi r27, r27, 1
cmpwi r27, 89 # Marth bone count
ble LOOP

restore

EXIT:
addi r3, r31, 0 # Replaced