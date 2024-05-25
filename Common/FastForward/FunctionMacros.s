.macro FunctionBody_ExecCameraTasks
FN_ExecCameraTasks:
backup

# try to execute update camera functions
branchl r12,0x80030a50 # Camera_LoadCameraEntity

# The commented line under is the parent function for all this bullshit
# we need to call to keep gameplay logic in-sync during a ffw. Unfortunately
# calling it directly makes FFW speed over 3x worse. This likely means there
# are some minor bugs while FFW'ing since ideally we would call this function.
# Additionally calling this function causes a bunch of flashing during rollbacks
# with stuff becoming invisible and coming back in
# branchl r12,0x800301d0 # DrawCamera+ECBDevelopBoxes

branchl r12,0x8002a4ac # Updates camera values used in tag position calculation

# call Player_SetOffscreenBool for all characters. This happens as part of the
# camera tasks after the main updateFunction loop so it doesn't run during
# a FFW normally. It is responsible for deciding whether to display the
# offscreen bubble

# Set current CObj to main camera. This is for a condition in
# Player_SetOffscreenBool at line 80086ad4
branchl r12,0x80030a50 # Camera_LoadCameraEntity
lwz r3, 0x28(r3)
branchl r12, 0x80368458 # HSD_CObjSetCurrent

FNPGX_LoopStart:
.set REG_FighterGObj, 20
.set REG_FighterData, 21
# Get first created fighter gobj
lwz	r3, -0x3E74 (r13)
lwz	REG_FighterGObj, 0x0020 (r3)
b FNPGX_LoopCheck
FNPGX_Loop:
# get data
lwz REG_FighterData,0x2C(REG_FighterGObj)

# if not sleep, update camera stuff
lbz r3,0x221F(REG_FighterData)
rlwinm. r0,r3,0,0x10
bne FNPGX_Loop_NoOffscreen
mr  r3,REG_FighterGObj
branchl r12, 0x80086a8c # Player_SetOffscreenBool
FNPGX_Loop_NoOffscreen:

FNPGX_LoopNext:
# get next gobj
lwz	REG_FighterGObj, 0x8 (REG_FighterGObj)
FNPGX_LoopCheck:
# if gobj exists, process it
cmpwi REG_FighterGObj,0
bne FNPGX_Loop

restore
blr
.endm
