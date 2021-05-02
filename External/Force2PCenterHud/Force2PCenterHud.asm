################################################################################
# Address: 0x8016E9AC
################################################################################

# First check if only ports 1 and 2 have players
lbz r3, 0x61(r31) # Load port 1 player type
cmpwi r3, 3
beq RUN_ORIGINAL # if port 1 is empty, run original
lbz r3, (0x61 + (1 * 0x24))(r31)
cmpwi r3, 3
beq RUN_ORIGINAL # if port 2 is empty, run original
lbz r3, (0x61 + (2 * 0x24))(r31)
cmpwi r3, 3
bne RUN_ORIGINAL # if port 3 is not empty, run original
lbz r3, (0x61 + (3 * 0x24))(r31)
cmpwi r3, 3
bne RUN_ORIGINAL # if port 4 is not empty, run original

# All conditions are met, force the centered HUD
li r3, 0x2
b EXIT

RUN_ORIGINAL:
# Original
lbz	r3, 0 (r31)
rlwinm	r3, r3, 30, 29, 31

EXIT: