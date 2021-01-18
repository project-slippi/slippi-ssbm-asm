################################################################################
# Address: 0x8016d888 # Happens when a game ends, after recording ends
################################################################################

.include "Common/Common.s"
.include "Online/Online.s"

.set REG_IDX, 31
.set REG_RGB_ADDR, 30
.set REG_RGPB_ADDR, 29

################################################################################
# Define report game buffer offsets and length
################################################################################
.set RGPB_IS_ACTIVE, 0 # bool, is player active
.set RGPB_STOCKS_REMAINING, RGPB_IS_ACTIVE + 1 # byte
.set RGPB_DAMAGE_DONE, RGPB_STOCKS_REMAINING + 1 # float
.set RGPB_SIZE, RGPB_DAMAGE_DONE + 4

.set RGB_COMMAND, 0 # byte
.set RGB_FRAME_LENGTH, RGB_COMMAND + 1 # s32, number of frames in game
.set RGB_P1_RGPB, RGB_FRAME_LENGTH + 4 # RGPB_SIZE
.set RGB_P2_RGPB, RGB_P1_RGPB + RGPB_SIZE # RGPB_SIZE
.set RGB_SIZE, RGB_P2_RGPB + RGPB_SIZE

# Ensure that this is an online in-game
getMinorMajor r3
cmpwi r3, SCENE_ONLINE_IN_GAME
bne EXIT # If not online in game

# Ensure that this is an unranked game
lbz r3, OFST_R13_ONLINE_MODE(r13)
cmpwi r3, ONLINE_MODE_UNRANKED
bne EXIT

# Check to make sure game ended
load r3, 0x8046b6a0
lbz r3, 0x8(r3)
cmpwi r3,0
beq EXIT

################################################################################
# Code start
################################################################################
backup

# Prepare buffer for EXI transfer
li r3, RGB_SIZE
branchl r12, HSD_MemAlloc
mr REG_RGB_ADDR, r3

# We can just use the receive buffer to send request command
li r3, CONST_SlippiCmdReportMatch
stb r3, RGB_COMMAND(REG_RGB_ADDR)

lwz r3, OFST_R13_ODB_ADDR(r13)
lwz r3, ODB_FRAME(r3)
stw r3, RGB_FRAME_LENGTH(REG_RGB_ADDR) # Store frame length

PLAYER_LOOP_INIT:
li REG_IDX, 0
addi REG_RGPB_ADDR, REG_RGB_ADDR, RGB_P1_RGPB

PLAYER_LOOP:
mr r3, REG_IDX
branchl r12, 0x80031724

# Store isActive
li r4, 1
stb r4, RGPB_IS_ACTIVE(REG_RGPB_ADDR)

# Store stocks remaining
lbz r4, 0x8E(r3)
stb r4, RGPB_STOCKS_REMAINING(REG_RGPB_ADDR)

# Store damage done
lwz r4, 0xC6C+188(r3)
stw r4, RGPB_DAMAGE_DONE(REG_RGPB_ADDR)

PLAYER_LOOP_INC:
addi REG_IDX, REG_IDX, 1
addi REG_RGPB_ADDR, REG_RGPB_ADDR, RGPB_SIZE

PLAYER_LOOP_CHECK:
cmpwi REG_IDX, 2
blt PLAYER_LOOP

# Execute match reporting
mr r3, REG_RGB_ADDR
li r4, RGB_SIZE
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Don't need to free, scene change will handle that automatically

restore

EXIT:
lwz	r12, 0x2514 (r31)
cmplwi r12, 0
