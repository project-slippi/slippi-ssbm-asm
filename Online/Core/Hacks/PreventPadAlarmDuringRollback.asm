################################################################################
# Address: 0x80019608
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Replaced code line
stwu	sp, -0x0008 (sp)

# Ensure that this is an online match
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT

load r3, 0x80479d64
lwz r3, 0x0(r3) # 0x80479d64 - Believed to be some loading state
cmpwi r3, 0 # Loading state should be zero when game starts
bne EXIT

# Check to see if this call came from VI callback, if not, just execute
# Kinda jank but it should do the job. Alternative would be creating a wrapper
# function for the RenewInputs_Prefunction call and setting that as the
# VI callback, but then I'd need to use non-standard lag reduction code
load r3, 0x80375e00
cmpwi r0, r3
bne EXIT

# Check if a rollback is active, if a rollback is active, do not renew inputs
# now as it may mess up the rollback logic. Instead let's store that inputs
# should be renewed at the earliest possible time.
lwz r5, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_ROLLBACK_IS_ACTIVE(r5)
cmpwi r3, 0
beq EXIT

# Here we have gotten a VI retrace callback while executing a rollback
# logf LOG_LEVEL_NOTICE, "VI retrace CB during rollback..."
li r3, 1
stb r3, ODB_SHOULD_FORCE_PAD_RENEW(r5)

# Skip PAD renew
branch r12, 0x80019618

EXIT:
li r3, 0 # Reset r3 to 0, was originally set at line 80019600
