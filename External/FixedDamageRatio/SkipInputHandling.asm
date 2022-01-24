################################################################################
# Address: 0x8022f958
################################################################################
# Handles the case where the damage ratio option is selected. If it is,
# the logic for handling inputs will just be skipped entirely. This makes it
# so the damage ratio can never be changed from the menu.
################################################################################

.include "Common/Common.s"

################################################################################
# ASM Research
################################################################################
# Menu Controls Struct at 0x804a04f0 (currently r4)
# 0x2 (u16): The current vertical selection index
# 0x4 (u8): Value of the current horizontal selection
#
# r5 currently contains the 0x2 value (vertical selection)

# At this injection, r5 is the currently selected line for options (3 is damage ratio)
cmpwi r5, 3
bne EXIT

# Exit the CSS function, skipping the part where inputs are checked to decide whether to change val
branch r12, 0x8022fb68

EXIT:
cmplwi r5, 5 # replaced code line