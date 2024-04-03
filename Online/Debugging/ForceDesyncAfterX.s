################################################################################
# Address: 0x8006d378 # Right after damage to be applied is loaded into f31
################################################################################

# This will force desyncs on hit after 15 seconds since the game started. Keeping this file
# as a .s prevents it from being included into the codeset

.include "Common/Common.s"
.include "Online/Online.s"

loadGlobalFrame r3 # Load current frame
cmpwi r3, 15 * 60 # Check for 15 seconds in
blt EXIT

lwz r11, OFST_R13_ODB_ADDR(r13) # data buffer address
lbz r3, ODB_LOCAL_PLAYER_INDEX(r11)
cmpwi r3, 0
bne EXIT # Only player 1

# Player 1 will see ALL damage applied as doubled
fadds f31, f31, f31

EXIT:
# Replaced codeline
mr r3, r30
fmr f1, f31
