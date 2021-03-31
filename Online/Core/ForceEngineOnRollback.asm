################################################################################
# Address: 0x801a4db4
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

################################################################################
# Short Circuit Conditions
################################################################################
# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne ORIGINAL

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne ORIGINAL

################################################################################
# Break out of loop on a rollback
################################################################################
branchl r12, OSDisableInterrupts
mr r26, r3 # r26 will be set to 0 at line 801a4ddc anyway so it's safe to use I think

lwz r5, OFST_R13_ODB_ADDR(r13) # data buffer address

cmpwi r27, 0
bgt PREPARE_ENGINE_LOOPS # If we had inputs, just prepare for loops immediately

# If we have no inputs and rollback is not active, we don't need to start engine
lbz r4, ODB_ROLLBACK_IS_ACTIVE(r5)
cmpwi r4, 0
beq HANDLE_NO_ROLLBACK_NO_INPUTS

# load one into r27. This will allow us to do one full rollback iteration and
# stop on the rollback termination frame at line 801a501c
li r27, 1

PREPARE_ENGINE_LOOPS:
# Copy the values that get updated in pad alarm to non-volatile locations so
# that they don't change during the loop iteration
lbz r4, ODB_ROLLBACK_IS_ACTIVE(r5)
stb r4, ODB_STABLE_ROLLBACK_IS_ACTIVE(r5)
lwz r4, ODB_ROLLBACK_END_FRAME(r5)
stw r4, ODB_STABLE_ROLLBACK_END_FRAME(r5)
lbz r4, ODB_ROLLBACK_SHOULD_LOAD_STATE(r5)
stb r4, ODB_STABLE_ROLLBACK_SHOULD_LOAD_STATE(r5)
lwz r4, ODB_SAVESTATE_FRAME(r5)
stw r4, ODB_STABLE_SAVESTATE_FRAME(r5)
lwz r4, ODB_RXB_ADDR(r5)
lwz r4, RXB_OPNT_FRAME_NUMS(r4)
stw r4, ODB_STABLE_OPNT_FRAME_NUMS(r5)
b RESTORE_AND_EXIT

HANDLE_NO_ROLLBACK_NO_INPUTS:
# Check to see if we got a pad alarm during a rollback and should trigger a
# renew PAD call
lbz r4, ODB_SHOULD_FORCE_PAD_RENEW(r5)
cmpwi r4, 0
beq RESTORE_AND_EXIT

li r4, 0
stb r4, ODB_SHOULD_FORCE_PAD_RENEW(r5)
branchl r12, RenewInputs_Prefunction
#logf LOG_LEVEL_NOTICE, "Forced a pad renew..."

RESTORE_AND_EXIT:
mr r3, r26 # We will set r26 to 0 later so it's fine to use here
branchl r12, OSRestoreInterrupts

ORIGINAL:
cmpwi r27, 0 # Check if we have no inputs
bne EXEC_ENGINE
branch r12, 0x801a4da8 # If no pad inputs, loop to keep waiting

EXEC_ENGINE:
