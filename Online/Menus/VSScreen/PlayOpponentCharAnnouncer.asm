################################################################################
# Address: 0x80184de4 # VSMode_Think line that decides char id to announce
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_MSRB_ADDR, 31
.set REG_RESULT, 30

# Ensure that this is an online VS
getMinorMajor r12
cmpwi r12, SCENE_ONLINE_VS
bne REPLACED_CODE_LINE # If online VS, skip line

backup

# Get match state info
li r3, 0
branchl r12, FN_LoadMatchState
mr REG_MSRB_ADDR, r3

# Get the ext char ID of the remote player
lbz r3, MSRB_REMOTE_PLAYER_INDEX(REG_MSRB_ADDR)
mulli r3, r3, 0x24
addi r4, REG_MSRB_ADDR, MSRB_GAME_INFO_BLOCK + 0x60 # load char 2 id
lbzx REG_RESULT, r4, r3

# Free the buffer we allocated to get match settings
mr r3, REG_MSRB_ADDR
branchl r12, HSD_Free

# Set result
mr r3, REG_RESULT

RESTORE_AND_EXIT:
restore
b EXIT

REPLACED_CODE_LINE:
# replaced code line
lbz r3, 0x00F4 (r30)

EXIT:
