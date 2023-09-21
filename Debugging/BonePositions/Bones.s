.ifndef HEADER_BONES

.macro FunctionBody_PrintFighterBones
backup

# Prepare callback context to keep track of count
li r4, 0
stw r4, BKP_FREE_SPACE_OFFSET(sp)

bl 8f # FN_LogJObjPosition_BLRL
mflr r4
lwz r3, 0x28(r3) # Get Root JObj from Entity
addi r5, sp, BKP_FREE_SPACE_OFFSET
branchl r12, 0x8036f0f0 # HSD_JObjWalkTree

restore
blr

8: # FN_LogJObjPosition_BLRL:
blrl
backup

mr r27, r4 # Ptr to iteration count
mr r28, r3 # Store JObj address

# TEMP: Only print first 3 bones
# lwz r3, 0(r27)
# cmpwi r3, 3
# bgt 9f # FN_LogJObjPosition_EXIT

mr r3, r28
li r4, 0
addi r5, sp, BKP_FREE_SPACE_OFFSET
branchl r12, 0x8000b1cc # GetEntityPosition

lwz r5, frameIndex(r13)
lwz r6, 0(r27)
mr r7, r28
lfs f1, BKP_FREE_SPACE_OFFSET(sp) # Get posX
lfs f2, BKP_FREE_SPACE_OFFSET+4(sp) # Get posY
lfs f3, BKP_FREE_SPACE_OFFSET+8(sp) # Get posZ
logf LOG_LEVEL_WARN, "[%d] [BonePosThrown] Idx: %d (0x%x), Pos: (%f, %f, %f)"
# logf LOG_LEVEL_WARN, "[%d] [BonePosThrown] %f, %f, %f"

# TEMP: Print anim translation
# lfs f1, 0x38(r28)
# lfs f2, 0x3c(r28)
# lfs f3, 0x40(r28)
# logf LOG_LEVEL_WARN, "Anim: (%f, %f, %f)"

# Increment count
lwz r3, 0(r27)
addi r3, r3, 1
stw r3, 0(r27)

9: # FN_LogJObjPosition_EXIT:
restore
blr
.endm

.endif
.set HEADER_BONES, 1
