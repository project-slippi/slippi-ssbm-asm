################################################################################
# Address: 0x803786a4 # HSD_PadRumbleInterpret1
################################################################################
# This function would infinite loop on the VS splash screen for unknown reasons.
# This hack prevents the game from hanging. I tried some "cleaner" options like
# not calling HSD_PadRumbleInterpret1 at all but this didn't work so w/e.
# Additionally this method allows for rumble to happen on VS splash which
# I guess is a nice indicator that the game has started

.include "Common/Common.s"
.include "Online/Online.s"

# If in VS Splash, try to prevent the infinite loop
getMinorMajor r12
cmpwi r12, SCENE_ONLINE_VS
beq BREAK_LOOP

# If in SSS, try to prevent the infinite loop
getMinorMajor r12
cmpwi r12, SCENE_ONLINE_SSS
beq BREAK_LOOP

# If not one of the above scenes, just exit
b EXIT

BREAK_LOOP:
# Just break out of loop entirely
branch r12, 0x803786ac

EXIT:
cmplwi r0, 0
