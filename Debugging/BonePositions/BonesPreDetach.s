################################################################################
# Address: 0x800ddf94
################################################################################

.include "Common/Common.s"
.include "Debugging/BonePositions/Bones.s"

backup

lwz r3, 0(r27) # fighter entitity
bl FN_PrintFighterBones

restore
b EXIT

FN_PrintFighterBones:
FunctionBody_PrintFighterBones

EXIT:
addi r3, r27, 0