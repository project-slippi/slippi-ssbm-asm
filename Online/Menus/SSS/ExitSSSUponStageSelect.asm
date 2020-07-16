################################################################################
# Address: 0x80259cc8   # injecting where the NOW LOADING screen is created
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

# Ensure that this is an online SSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_SSS
bne EXIT # If not online CSS, continue as normal

# Play SFX
li  r3,1
branchl r12,SFX_Menu_CommonSound

# Get highlighted stage's external ID
lbz	r3, -0x49F2 (r13)
branchl r12,0x8025bc08
# Lock in
lwz r12, OFST_R13_CALLBACK(r13)
mtctr r12
bctrl

/*
# If locked in, show now loading
li r3, 0
branchl r12, FN_LoadMatchState
lbz r4, MSRB_IS_LOCAL_PLAYER_READY(r3)
lbz r5, MSRB_IS_REMOTE_PLAYER_READY(r3)
cmpw  r4,r5
beq EXIT
*/

# Request minor scene change
li  r3,2
stb r3, -0x49F1 (r13)
#branchl r12,0x801a4b60

# Exit function
branch  r12,0x80259d6c

EXIT:
li	r3, 4
