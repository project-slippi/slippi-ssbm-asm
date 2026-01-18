.include "Common/Common.s"
.include "Online/Online.s"

################################################################################
# Address: 0x8000568C
################################################################################
# Inputs:
# r3 - Character ID
# r4 - Language (0 = JP | 1 = EN)
################################################################################
# Output:
# r5 - Shift-JIS string pointer to character name
################################################################################
# Description:
# Gets a character's Shift-JIS name string from memory
################################################################################

.set EN_CHAR_STRING_TABLE, 0x803d4fdc
.set JP_CHAR_STRING_TABLE, 0x803d4d74

# Load English strings by default
load r5, EN_CHAR_STRING_TABLE # Load EN base addr into r4

# Multiply char id by size of shift-jis string ptr to get offset
mulli r3, r3, 4
# Check if language is Japanese
cmpwi r4, 0
bne EN_LANG

JP_LANG:
load r5, JP_CHAR_STRING_TABLE # Load JP base addr into r4
EN_LANG: # Skip to this label if language is English

add r5, r3, r5 # Add ptr offset to base addr
lwz r5, 0(r5)
blr