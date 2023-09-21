################################################################################
# Address: 0x800de1ac
################################################################################

.include "Common/Common.s"
.include "Debugging/BonePositions/Bones.s"

backup

# Print the bone 2 translations
lfs f1, 0x2174(r27)
lfs f2, 0x2178(r27)
lfs f3, 0x217C(r27)
logf LOG_LEVEL_WARN, "Bone 2 Anim: (%f, %f, %f)"

lwz r3, 0(r27) # fighter entitity
bl FN_PrintFighterBones

restore
b EXIT

FN_PrintFighterBones:
FunctionBody_PrintFighterBones

EXIT:
mr	r3, r27 # replaced