################################################################################
# Address: INJ_FREEZE_STADIUM # PokemonStadium_TransformationDecide
# Tags: [affects-gameplay]
################################################################################

.include "Common/Common.s"

b CODE_START
STATIC_MEMORY_TABLE_BLRL:
blrl
.byte 0x0 # stores whether frozen toggle is enabled. 0 = unfrozen, 1 = frozen
.align 2

CODE_START:
# First check the replaced code line. PS is always frozen in training mode.
# If in training mode, just run the normal logic
branchl r12, 0x8018841c # MenuController_TrainingModeCheck
cmpwi r3, 0
bne EXIT

# If we get here we are not in training mode, so let's load the toggle state.
# From the game's perspective, this value will replace the Training mode check. So if
# the toggle is 0x1, the game will treat it like we are in training mode, freezing PS
bl STATIC_MEMORY_TABLE_BLRL
mflr r3
lbz r3, 0(r3) # Load the toggle state

EXIT:
