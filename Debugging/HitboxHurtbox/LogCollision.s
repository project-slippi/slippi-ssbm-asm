################################################################################
# Address: 0x80008210
################################################################################

.include "Common/Common.s"

# Call replaced function, this function returns 1 if the hitbox collides with the hurtbox
branchl r12, 0x80006e58 # Hitbox_CalculateHitboxCollisionWithHurtbox

# r30 -> hitboxData
# r31 -> hurtboxData

# Log out position information before worrying about the collision
addi r12, r30, 0x4c # hitboxData->base
lfs f1, 0(r12)
lfs f2, 4(r12)
lfs f3, 8(r12)
addi r12, r30, 0x58 # hitboxData->tip
lfs f4, 0(r12)
lfs f5, 4(r12)
lfs f6, 8(r12)
logf LOG_LEVEL_WARN, "[HitboxCheck] Base: (%f, %f, %f) Tip: (%f, %f, %f)"

addi r12, r31, 0x28 # hurtboxData->base
lfs f1, 0(r12)
lfs f2, 4(r12)
lfs f3, 8(r12)
addi r12, r31, 0x34 # hurtboxData->tip
lfs f4, 0(r12)
lfs f5, 4(r12)
lfs f6, 8(r12)
lwz r5, 64(r31) # hurtboxData->boneId
logf LOG_LEVEL_WARN, "[HurtboxCheck] Bone: %d Base: (%f, %f, %f) Tip: (%f, %f, %f)"

cmpwi r3, 0
beq EXIT

lwz r5, 64(r31) # hurtboxData->boneId
logf LOG_LEVEL_NOTICE, "Hitbox P? (Id ?) -> Hurtbox P? (Bone %d) | HitboxBone: ?"

lwz r5, 8(r30) # hitboxData->damage
lwz r6, 32(r30) # hitboxData->angle
lfs f1, 28(r30) # hitboxData->size
lfs f2, 16(r30) # hitboxData->x
lfs f3, 20(r30) # hitboxData->y
lfs f4, 24(r30) # hitboxData->z
logf LOG_LEVEL_NOTICE, "HitboxDetails. Damage: %d, Angle: %d, Size: %f, Offset: (%f, %f, %f)"

EXIT: