################################################################################
# Address: 0x8022b044 # MainMenuThink, clear old menu condition
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# If menu IDs are not matching, it is a normal menu transition, clear menu
bne CLEAR

# Check force bool
lbz r3, OFST_R13_FORCE_MENU_CLEAR(r13)
cmpwi r3, 0
bne CLEAR

# Skip clear handling
branch r12, 0x8022B11C

CLEAR:
# Menu clear, clear force bool
li r3, 0
stb r3, OFST_R13_FORCE_MENU_CLEAR(r13)
