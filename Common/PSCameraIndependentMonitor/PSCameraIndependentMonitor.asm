################################################################################
# Address: 0x801d24fc # PokemonStadium_Main replaces normal function call
################################################################################

.include "Common/Common.s"

.set REG_FIGHTERDATA, 31
.set REG_INPUT, 30

backup

mr REG_INPUT, r3 # Technically not necessary since it's loaded from r30 to begin with, but w/e

# First fetch the fighter data address for the "main character"
lwz r3, 0x2C(REG_INPUT)
lha r3, 0xEE(r3)
branchl r12, 0x80034110 # PlayerBlock_LoadMainCharDataOffsetStart
lwz REG_FIGHTERDATA, 0x2C(r3)

# Call replaced function (seems to be responsible for handling the main character tracking)
mr r3, REG_INPUT
branchl r12, 0x801d32d0 # PokemonStadium_CheckIfPlayerIsDamaged

# The replaced function previously decided whether or not we transition off of the zoomed-in
# view. But we're going to replace that part with our own logic below in a way that is camera
# independent. We need to do this because using the camera to decide this could cause RNG desyncs
# between widescreen and non-widescreen gameplay given that the screen transition logic does
# some Rand calls before Pri1. So a desynced monitor can (rarely) cause desynced gameplay

# Compare the players X position to the left camera bound
branchl r12, 0x80224a54 # StageInfo_CameraLimitLeft_Load
lfs f2, 0xB0(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
blt RETURN_FALSE

branchl r12, 0x80224a68 # StageInfo_CameraLimitRight_Load
lfs f2, 0xB0(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
bgt RETURN_FALSE

branchl r12, 0x80224a80 # StageInfo_CameraLimitTop_Load
lfs f2, 0xB4(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
bgt RETURN_FALSE

branchl r12, 0x80224a98 # StageInfo_CameraLimitBottom_Load
lfs f2, 0xB4(REG_FIGHTERDATA)
fcmpo cr0, f2, f1
blt RETURN_FALSE

# Here we are inside the camera bounds, so return false
RETURN_TRUE:
li r3, 1
b RESTORE_AND_EXIT

RETURN_FALSE:
li r3, 0

RESTORE_AND_EXIT:
restore

EXIT:
