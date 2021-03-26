################################################################################
# Address: INJ_InitInGameDelay
################################################################################

.include "Common/Common.s"
.include "Common/UseInGameDelay/InGameDelay.s"

b CODE_START
STATIC_MEMORY_TABLE_BLRL:
blrl
.long 0x80000000 # Placeholder for allocated memory pointer

LOCAL_MEMORY_TABLE_BLRL:
blrl
# text config stuff
.set DOFST_TEXT_BASE_Z, 0
.float 0
.set DOFST_TEXT_BASE_CANVAS_SCALING, DOFST_TEXT_BASE_Z + 4
.float 0.1

# delay values
.set DOFST_TEXT_X_POS, DOFST_TEXT_BASE_CANVAS_SCALING + 4
.float 270
.set DOFST_TEXT_Y_POS, DOFST_TEXT_X_POS + 4
.float 207
.set DOFST_TEXT_SIZE, DOFST_TEXT_Y_POS + 4
.float 0.33

# strings
.set DOFST_TEXT_DELAYSTRING, DOFST_TEXT_SIZE + 4
.string "Delay: %df"
.align 2

#########################################
COBJ_CB:
blrl
.set  REG_GOBJ,31

backup

mr  REG_GOBJ, r3

/*
# Check if paused
li  r3,1
branchl r12,0x801a45e8
cmpwi r3,2
beq COBJ_CB_Exit
*/
# Check if paused
lbz	r0, -0x4934 (r13)
cmpwi r0,1
beq COBJ_CB_Exit

# Draw camera
mr  r3, REG_GOBJ
branchl r12,0x803910d8

COBJ_CB_Exit:
restore
blr
#########################################

CODE_START:
# Original codeline
mr	r31, r3

# Short circuit conditions
getMajorId r3
cmpwi r3, 0x8
beq EXIT # Don't run this while online, it has its own built-in delay

################################################################################
# Logic Start
################################################################################
.set REG_IGDB_ADDR, 31
.set REG_DELAY_RESULT, 30
.set REG_DATA_ADDR, 29
.set REG_TEXT_STRUCT, 28
.set REG_Canvas, 27
.set REG_COBJ, 26
.set REG_GOBJ, 25

backup

################################################################################
# Initialize 
################################################################################
# Prep the IGDB
li r3, IGDB_SIZE
branchl r12, HSD_MemAlloc
mr REG_IGDB_ADDR, r3
li r4, IGDB_SIZE
branchl r12, Zero_AreaLength

# Write the IGDB address to static memory
bl STATIC_MEMORY_TABLE_BLRL
mflr r3
stw REG_IGDB_ADDR, 0(r3)

################################################################################
# Fetch delay frames setting
################################################################################
# We will just use the IGDB to do the EXI transfer to avoid making another buf
li r3, CONST_SlippiCmdGetDelay
stb r3, 0(REG_IGDB_ADDR)

# Request delay
mr r3, REG_IGDB_ADDR # Use the receive buffer to send the command
li r4, 1
li r5, CONST_ExiWrite
branchl r12, FN_EXITransferBuffer

# Get delay response
mr r3, REG_IGDB_ADDR # Use the receive buffer to send the command
li r4, 2
li r5, CONST_ExiRead
branchl r12, FN_EXITransferBuffer

################################################################################
# Set up number of delay frames
################################################################################
# First fetch the result (note that this value should be 0 if EXI didn't exist)
lbz REG_DELAY_RESULT, 0x1(REG_IGDB_ADDR)

# Zero our the IGDB again to clear out any other EXI values
mr r3, REG_IGDB_ADDR
li r4, IGDB_SIZE
branchl r12, Zero_AreaLength

# Handle delay limits
cmpwi REG_DELAY_RESULT, MIN_DELAY_FRAMES
blt DELAY_FRAMES_MIN_LIMIT
cmpwi REG_DELAY_RESULT, MAX_DELAY_FRAMES
bgt DELAY_FRAMES_MAX_LIMIT
b SET_DELAY_FRAMES
DELAY_FRAMES_MIN_LIMIT:
li REG_DELAY_RESULT, MIN_DELAY_FRAMES
b SET_DELAY_FRAMES
DELAY_FRAMES_MAX_LIMIT:
li REG_DELAY_RESULT, MAX_DELAY_FRAMES

# Write delay result to IGDB
SET_DELAY_FRAMES:
stb REG_DELAY_RESULT, IGDB_DELAY_FRAMES(REG_IGDB_ADDR)

################################################################################
# Terminate logic if delay is zero or less
################################################################################
cmpwi REG_DELAY_RESULT, 0
ble RESTORE_EXIT

################################################################################
# Prepare canvas for displaying delay
################################################################################
# CObj stuff
.set  COBJ_GXPRI, 8
.set  TEXT_GXPRI, 80
.set  TEXT_GXLINK, 12

# Get HUD CObjDesc
load  r3, 0x804d6d5c
lwz r3, 0x0 (r3)
load  r4, 0x803f94d0
branchl r12,0x80380358
# Create CObj
lwz r3,0x4(r3)
lwz r3,0x0(r3)
branchl r12,0x8036a590
mr  REG_COBJ,r3
# Create GObj
li  r3,19
li  r4,20
li  r5,0
branchl r12,0x803901f0
mr  REG_GOBJ,r3
# Add object
mr  r3,REG_GOBJ
lbz r4,-0x3E55(r13)
mr  r5,REG_COBJ
branchl r12,0x80390a70
# Init camera
mr  r3,REG_GOBJ
bl  COBJ_CB
mflr  r4
li  r5, COBJ_GXPRI
branchl r12,0x8039075c
# Store COBJs GXLinks
load  r3, 1 << TEXT_GXLINK
stw r3, 0x24 (REG_GOBJ)

# Create canvas
li  r3,2
mr  r4,REG_GOBJ
li  r5, 9
li  r6, 13
li  r7, 0
li  r8, TEXT_GXLINK
li  r9, TEXT_GXPRI
li  r10, COBJ_GXPRI
branchl r12, 0x803a611c
mr  REG_Canvas, r3

################################################################################
# Prepare delay display
################################################################################
bl LOCAL_MEMORY_TABLE_BLRL
mflr REG_DATA_ADDR

# Start prepping text struct
li r3, 2
mr  r4,REG_Canvas
branchl r12, Text_CreateStruct
mr REG_TEXT_STRUCT, r3

# Set text kerning to close
li r4, 0x1
stb r4, 0x49(REG_TEXT_STRUCT)
# Set text to align right
li r4, 0x2
stb r4, 0x4A(REG_TEXT_STRUCT)

# Store Base Z Offset
lfs f1, DOFST_TEXT_BASE_Z(REG_DATA_ADDR) #Z offset
stfs f1, 0x8(REG_TEXT_STRUCT)

# Scale Canvas Down
lfs f1, DOFST_TEXT_BASE_CANVAS_SCALING(REG_DATA_ADDR)
stfs f1, 0x24(REG_TEXT_STRUCT)
stfs f1, 0x28(REG_TEXT_STRUCT)

# Initialize header
lfs f1, DOFST_TEXT_X_POS(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_Y_POS(REG_DATA_ADDR)
mr r3, REG_TEXT_STRUCT
addi r4, REG_DATA_ADDR, DOFST_TEXT_DELAYSTRING
mr r5, REG_DELAY_RESULT
branchl r12, Text_InitializeSubtext

# Set header text size
mr r3, REG_TEXT_STRUCT
li r4, 0
# Scale text X based on Aspect Ratio
lfs f1, DOFST_TEXT_SIZE(REG_DATA_ADDR)
lfs f2, DOFST_TEXT_SIZE(REG_DATA_ADDR)
branchl r12, Text_UpdateSubtextSize

RESTORE_EXIT:
restore
EXIT:
mr	r3, r31  # replaced code line