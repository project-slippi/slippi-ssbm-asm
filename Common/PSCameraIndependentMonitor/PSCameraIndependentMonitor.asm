################################################################################
# Address: 0x801d24fc # PokemonStadium_Main replaces normal function call
################################################################################

.include "Common/Common.s"

b CODE_START

DATA_BLRL:
blrl
# Here we store the bounds which, if the main character goes outside of, will cause a monitor
# transition. These are taken from the camera limits for the stage minus a fixed amount. The point
# of this is to ensure that the zoomed in view will usually have the character in frame. This is
# no longer guaranteed for example in the case of a fast moving camera but... at least it's
# consistent across both. I bet nobody notices anyway ¯\_(ツ)_/¯
.set DO_LEFT_BOUND, 0
.float -120 # Left bound (-170) + 50
.set DO_RIGHT_BOUND, DO_LEFT_BOUND + 4
.float 120 # Right bound (170) - 50
.set DO_TOP_BOUND, DO_RIGHT_BOUND + 4
.float 80 # Top bound (120) - 40
.set DO_BOTTOM_BOUND, DO_TOP_BOUND + 4
.float -20 # Bottom bound (-60) + 40

.set REG_FIGHTERDATA, 31
.set REG_INPUT, 30
.set REG_DATA, 29

CODE_START:
backup

mr REG_INPUT, r3 # Technically not necessary since it's loaded from r30 to begin with, but w/e
bl DATA_BLRL
mflr REG_DATA

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

# Load X position
lfs f2, 0xB0(REG_FIGHTERDATA)

# Compare X position to left bound
lfs f1, DO_LEFT_BOUND(REG_DATA)
fcmpo cr0, f2, f1
blt RETURN_FALSE

# Compare X position to right bound
lfs f1, DO_RIGHT_BOUND(REG_DATA)
fcmpo cr0, f2, f1
bgt RETURN_FALSE

# Load Y position
lfs f2, 0xB4(REG_FIGHTERDATA)

# Compare Y position to top bound
lfs f1, DO_TOP_BOUND(REG_DATA)
fcmpo cr0, f2, f1
bgt RETURN_FALSE

# Compare Y position to bottom bound
lfs f1, DO_BOTTOM_BOUND(REG_DATA)
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
