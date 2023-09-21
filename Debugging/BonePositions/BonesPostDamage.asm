################################################################################
# Address: 0x8006d990
################################################################################

.include "Common/Common.s"
.include "Debugging/BonePositions/Bones.s"

# Only run for P1
lbz r3, 0xC(r30)
cmpwi r3, 0
bne EXIT

backup

# Print the bone 2 translations
lfs f1, 0x2174(r30)
lfs f2, 0x2178(r30)
lfs f3, 0x217C(r30)
logf LOG_LEVEL_WARN, "Bone 2 Anim: (%f, %f, %f)"

mr r3, r31 # fighter entitity
bl FN_PrintFighterBones

restore
b EXIT

FN_PrintFighterBones:
FunctionBody_PrintFighterBones

EXIT:
lmw	r25, 0x0034 (sp) # replaced