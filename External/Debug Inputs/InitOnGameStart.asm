################################################################################
# Address: INJ_InitDebugInputs
################################################################################

.include "Common/Common.s"
.include "./DebugInputs.s"

b CODE_START

DATA_BLRL:
blrl
.set DO_DIB_ADDR, 0
.long 0 # Buffer
.set DO_CS_X_SCALE, DO_DIB_ADDR + 4
.float 200
.set DO_CS_Y_SCALE, DO_CS_X_SCALE + 4
.float 25
.set DO_CS_COLOR, DO_CS_Y_SCALE + 4
.byte 0,0,0,255
.set DO_LD_COLOR, DO_CS_COLOR + 4
.byte 0,0,0,180
.set DO_LD_TEXT_COLOR, DO_LD_COLOR + 4
.byte 0xE2,0xE2,0xE2,0xFF
.set DO_LD_TEXT_X_SCALE, DO_LD_TEXT_COLOR + 4
.float 10
.set DO_LD_TEXT_Y_SCALE, DO_LD_TEXT_X_SCALE + 4
.float 17
.set DO_LD_STR_LATENCY, DO_LD_TEXT_Y_SCALE + 4
.string "Total Game Lag: %u us\n\n"
.set DO_LD_STR_POLL_COUNT, DO_LD_STR_LATENCY + 24
.string "Poll Count: %u\n"
.set DO_LD_STR_MIN_POLL_DIFF, DO_LD_STR_POLL_COUNT + 16
.string "Min Poll Diff: %u us\n"
.set DO_LD_STR_MAX_POLL_DIFF, DO_LD_STR_MIN_POLL_DIFF + 22
.string "Max Poll Diff: %u us\n"
.set DO_LD_STR_FETCH_DIFF, DO_LD_STR_MAX_POLL_DIFF + 22
.string "Fetch-Fetch: %u us\n"
.set DO_LD_STR_FETCH_TO_POLL_DIFF, DO_LD_STR_FETCH_DIFF + 20
.string "Poll-Fetch: %u us\n"
.set DO_LD_STR_POLL_TO_ENGINE_DIFF, DO_LD_STR_FETCH_TO_POLL_DIFF + 19
.string "Poll-Engine: %u us\n"
.align 2

################################################################################
# Function: PollingHandler
################################################################################
FN_BLRL_PollingHandler:
blrl

# This is only here to trigger the interrupt. The actual logic will happen in LogPollInterrupt.asm
# I modified it to work this way such that the poll time is logged before any poll handlers
# run in case the PadRenewRaw is called is a side effect of a poll handler such as is the case
# with tau's 0.5f lag reduction code
blr

################################################################################
# Function: UpdateLagDisplay
################################################################################
.set REG_DATA, 31
.set REG_DIB, 30
.set REG_DEVELOP_TEXT, 29

FN_BLRL_UpdateLagDisplay:
blrl
backup

bl DATA_BLRL
mflr REG_DATA
lwz REG_DIB, DO_DIB_ADDR(REG_DATA)
lwz REG_DEVELOP_TEXT, DIB_LAG_DISPLAY_DTEXT_ADDR(REG_DIB)

# Only run update if active, if complete, stop updating
lbz r3, DIB_ACTIVE_STATE(REG_DIB)
cmpwi r3, 1
bne FN_UpdateLagDisplay_EXIT

mr r3, REG_DEVELOP_TEXT
branchl r12, 0x80302bb0 # DevelopText_EraseAllText
mr r3, REG_DEVELOP_TEXT
li r4, 0
li r5, 0
branchl r12, 0x80302a3c # DevelopMode_Text_ResetCursorXY

#Set Text
mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_STR_LATENCY
lwz r5, DIB_INPUT_TO_RENDER_US(REG_DIB)
branchl r12, 0x80302d4c # DevelopText_FormatAndPrint

mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_STR_POLL_COUNT
lwz r5, DIB_POLL_COUNT(REG_DIB)
branchl r12, 0x80302d4c # DevelopText_FormatAndPrint

mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_STR_MIN_POLL_DIFF
lwz r5, DIB_POLL_DIFF_MIN_US(REG_DIB)
branchl r12, 0x80302d4c # DevelopText_FormatAndPrint

mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_STR_MAX_POLL_DIFF
lwz r5, DIB_POLL_DIFF_MAX_US(REG_DIB)
branchl r12, 0x80302d4c # DevelopText_FormatAndPrint

mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_STR_FETCH_DIFF
lwz r5, DIB_FETCH_DIFF_US(REG_DIB)
branchl r12, 0x80302d4c # DevelopText_FormatAndPrint

mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_STR_FETCH_TO_POLL_DIFF
lwz r5, DIB_POLL_TO_FETCH_US(REG_DIB)
branchl r12, 0x80302d4c # DevelopText_FormatAndPrint

mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_STR_POLL_TO_ENGINE_DIFF
lwz r5, DIB_POLL_TO_ENGINE_US(REG_DIB)
branchl r12, 0x80302d4c # DevelopText_FormatAndPrint

# Check if game over
load r3, 0x8046b6a0
lbz r3, 0x8(r3)
cmpwi r3, 0
beq SKIP_GAME_END

# Here game has ended, so let's do some cleanup. First unregister polling callback
lwz r3, DIB_CALLBACK_PTR(REG_DIB)
branchl r12, 0x80349cbc # SIUnregisterPollingHandler

# Set active state to game complete
li r3, 2
stb r3, DIB_ACTIVE_STATE(REG_DIB)
SKIP_GAME_END:

FN_UpdateLagDisplay_EXIT:
restore
blr

################################################################################
# Function: InitColorSquare
################################################################################
.set REG_DATA, 31
.set REG_DEVELOP_TEXT, 30

FN_InitColorSquare:
backup

bl DATA_BLRL
mflr REG_DATA

#Create Rectangle
li r3, 32
branchl r12, HSD_MemAlloc
mr r8, r3
li r3, 30 # ID
li r4, -210 # X Pos
li r5, -40 # Y Pos
li r6, 1
li r7, 1
branchl r12, 0x80302834 # DevelopText_CreateDataTable
mr REG_DEVELOP_TEXT, r3
#Activate Text
lwz	r3, -0x4884(r13)
mr r4, REG_DEVELOP_TEXT
branchl r12, 0x80302810 # DevelopText_Activate
#Hide blinking cursor
li r3, 0
stb r3, 0x26(REG_DEVELOP_TEXT)
#Change BG Color
mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_CS_COLOR
branchl r12, 0x80302b90 # DevelopText_StoreBGColor
#Set Stretch
lfs f1, DO_CS_X_SCALE(REG_DATA)
stfs f1, 0x8(REG_DEVELOP_TEXT)
lfs f1, DO_CS_Y_SCALE(REG_DATA)
stfs f1, 0xC(REG_DEVELOP_TEXT)
#Store Develop Text Addr
lwz r3, DO_DIB_ADDR(REG_DATA)
stw REG_DEVELOP_TEXT, DIB_COLOR_KEY_DTEXT_ADDR(r3)

restore
blr

################################################################################
# Function: InitLagDisplay
################################################################################
.set REG_DATA, 31
.set REG_DEVELOP_TEXT, 30

FN_InitLagDisplay:
backup

bl DATA_BLRL
mflr REG_DATA

#Create Rectangle
li r3, 1000
branchl r12, HSD_MemAlloc
mr r8, r3
li r3, 31 # ID
li r4, 0 # X Pos
li r5, 0 # Y Pos
li r6, 29 # Width
li r7, 9 # Height
branchl r12, 0x80302834 # DevelopText_CreateDataTable
mr REG_DEVELOP_TEXT, r3
#Activate Text
lwz	r3, -0x4884(r13)
mr r4, REG_DEVELOP_TEXT
branchl r12, 0x80302810 # DevelopText_Activate
#Hide blinking cursor
li r3, 0
stb r3, 0x26(REG_DEVELOP_TEXT)
#Change BG Color
mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_COLOR
branchl r12, 0x80302b90 # DevelopText_StoreBGColor
#Store text scale
mr r3, REG_DEVELOP_TEXT
lfs f1, DO_LD_TEXT_X_SCALE(REG_DATA)
lfs f2, DO_LD_TEXT_Y_SCALE(REG_DATA)
branchl r12, 0x80302b10 # DevelopText_StoreTextScale
#Set Text Color
mr r3, REG_DEVELOP_TEXT
addi r4, REG_DATA, DO_LD_TEXT_COLOR
branchl r12, 0x80302b64 # DevelopText_StoreTextColor
#Show text
mr r3, REG_DEVELOP_TEXT
branchl r12, 0x80302af0 # DevelopText_ShowText
#Store Develop Text Addr
lwz r3, DO_LD_DIB_ADDR(REG_DATA)
stw REG_DEVELOP_TEXT, DIB_LAG_DISPLAY_DTEXT_ADDR(r3)

# Create GObj
li r3, 19 # GObj Type
li r4, 20 
li r5, 0 # some type of priority
branchl r12, GObj_Create

#Create Proc to update display
bl FN_BLRL_UpdateLagDisplay
mflr r4 # Function
li r5, 7 # Priority
branchl	r12, GObj_AddProc

restore
blr

CODE_START:

.set REG_DIB, 30

backup
# logf "Init..."

li r3, DIB_SIZE
branchl r12, HSD_MemAlloc

bl DATA_BLRL
mflr r4
stw r3, 0(r4) # Write address to static address
mr REG_DIB, r3

li r4, DIB_SIZE
branchl r12, Zero_AreaLength

bl FN_InitColorSquare
bl FN_InitLagDisplay

# I thought this would fire twice per frame (same as polling), but it doesn't and idk what it does
bl FN_BLRL_PollingHandler
mflr r3
stw r3, DIB_CALLBACK_PTR(REG_DIB) # Store so we can unregister later
branchl r12, 0x80349bf0 # SIRegisterPollingHandler

restore

EXIT:
lfs f1, -0x5738(rtoc)