################################################################################
# Address: 801b1574
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_MSRB_ADDR, 31 # r31 is about to get restored so it's safe to use

# Ensure that this is an online SSS
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_SSS
bne EXIT # If not online CSS, continue as normal

# Get match state info
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

# Write data for left character

# Write selected character to where ScenePrep_ClassicMode function will read from
branchl r12, 0x8017eb30

lbz r4, MSRB_GAME_INFO_BLOCK + 0x60(REG_MSRB_ADDR) # load char id
stb r4, 0(r3) # write char id
lbz r4, MSRB_GAME_INFO_BLOCK + 0x63(REG_MSRB_ADDR) # load char color
stb r4, 1(r3) # write char color

li r4, 0
stb r4, 2(r3) # difficulty, unused, could maybe leave unset
li r4, 3
stb r4, 5(r3) # stocks, unused, could maybe leave unset
li r4, 0x78
stb r4, 4(r3) # name to show under char. 0x78 = char name, 0 = nametag

# Write data for right character

# Prepare to write to data used to set up right character
load r4, 0x803ddec8
lwz r4, 0xc(r4)

lbz r3, MSRB_GAME_INFO_BLOCK + 0x60 + 0x24(REG_MSRB_ADDR) # load char 2 id
stb r3, 2(r4)
li r3, 0x2121 # store empty slots for chars 2/3
sth r3, 3(r4)

# Here we write P2 color. this was done in sort of a hacky way. the PreventP2Color
# file will prevent us setting this value early from getting overwritten.
# I'm not sure what the function at line 801b364c does but it seems to always
# return zero. Ideally we would set a mem location here that would cause that
# function to return the color we want, but I couldn't figure out how
load r4, 0x80490880
lbz r3, MSRB_GAME_INFO_BLOCK + 0x63 + 0x24(REG_MSRB_ADDR) # load char 2 color
stb r3, 0x16(r4)

# Free the buffer we allocated to get match settings
mr r3, REG_MSRB_ADDR
branchl r12, HSD_Free

# This will cause the next scene to be the splash screen instead of VS mode
load r4, 0x80479d30
li r3, 0x05
stb r3, 0x5(r4)

EXIT:
lwz	r0, 0x001C (sp)
