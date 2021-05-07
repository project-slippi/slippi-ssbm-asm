################################################################################
# Address: 0x80229c40 #0x8022f568 # Address in CSSRules_CustomRulesThink after instant
# controller inputs have been set
################################################################################
# 804a04fc address that saves animation states of css custom rles mneu
.include "Common/Common.s"
.include "Online/Online.s"

.set REG_RULES_ADDR, 30

START:

backup
# Ensure that this is an online CSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_CSS
bne EXIT # If not online CSS, continue as normal

lbz r4, OFST_R13_ONLINE_MODE(r13)
cmpwi r4, ONLINE_MODE_DIRECT
blt EXIT # exit if not on DIRECT or TEAMS mode

load r3, 0x804a04f0 # current menu id
lbz r3, 0x0(r3)
cmpwi r3, 0x12 # Exit if we are on name entry
beq EXIT

lbz r3, -0x49B0(r13) # get input of player that opened the menu
branchl	r12, 0x801A36A0 # Inputs_GetPlayerInstantInputs
cmpwi r4, 0x10 # check if BTN_Z was pressed
bne EXIT

# If Z is Pressed, then Restore Tournament Rules
li	r3, 6 # snapshot sound
branchl r12, SFX_Menu_CommonSound

# TODO: Consider using mem copy instead

bl DATA
mflr r3

load REG_RULES_ADDR, 0x8045BF10

lwz r4, 0x0(r3)
stw r4, 0x0(REG_RULES_ADDR)
lwz r4, 0x4(r3)
stw r4, 0x4(REG_RULES_ADDR)
lwz r4, 0x8(r3)
stw r4, 0x8(REG_RULES_ADDR)
lwz r4, 0xC(r3)
stw r4, 0xC(REG_RULES_ADDR)

# Starts at 8045c370
lwz r4, 0x10(r3)
stw r4, 0x460 + 0x0(REG_RULES_ADDR)
lwz r4, 0x14(r3)
stw r4, 0x460 + 0x8(REG_RULES_ADDR)
lwz r4, 0x18(r3)
stw r4, 0x460 + 0xC(REG_RULES_ADDR)
lwz r4, 0x1C(r3)
stw r4, 0x460 + 0x10(REG_RULES_ADDR)
lwz r4, 0x20(r3)
stw r4, 0x460 + 0x14(REG_RULES_ADDR)
lwz r4, 0x24(r3)
stw r4, 0x460 + 0x18(REG_RULES_ADDR)

branchl r12, 0x8022f4cc # CSSRules_CleanupAndReturnToMajor
restore
branch r3, 0x80229da0 # move to end of function

DATA:
blrl
.long 0x00350102 # Custom Rules 1
.long 0x04000A00 # Custom Rules 2
.long 0x08010000 # Additional Rules 1
.long 0x00000808 # Additional Rules 2

.long 0xFF000000 # Items Speed Switch
.long 0xffffffff # Items Selections 1
.long 0xffffffff # Items Selections 2
.long 0x01010101 # Rumble Settings (ignore)
.long 0x00010100 # Screen Settings (ignore)
.long 0xE70000B0 # Stage Selections

EXIT:
restore
addi r3,r28, 0

