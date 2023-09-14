.ifndef HEADER_DEBUG_INPUTS

################################################################################
# Constants
################################################################################
.set INJ_InitDebugInputs, 0x8016e774

.set CIRCULAR_BUFFER_COUNT, 16

.set DIB_ACTIVE_STATE, 0 # u8. 0 = starting, 1 = active, 2 = complete
.set DIB_FETCH_INDEX, DIB_ACTIVE_STATE + 1 # u8
.set DIB_COLOR_KEY_DTEXT_ADDR, DIB_FETCH_INDEX + 1 # u32
.set DIB_LAG_DISPLAY_DTEXT_ADDR, DIB_COLOR_KEY_DTEXT_ADDR + 4 # u32
.set DIB_LAST_POLL_TIME, DIB_LAG_DISPLAY_DTEXT_ADDR + 4 # u32
.set DIB_LAST_FETCH_TIME, DIB_LAST_POLL_TIME + 4 # u32
.set DIB_CALLBACK_PTR, DIB_LAST_FETCH_TIME + 4 # u32
.set DIB_CIRCULAR_BUFFER, DIB_CALLBACK_PTR + 4  # u32 * CIRCULAR_BUFFER_COUNT
.set DIB_INPUT_TO_RENDER_US, DIB_CIRCULAR_BUFFER + (4 * CIRCULAR_BUFFER_COUNT) # u32
.set DIB_POLL_DIFF_MIN_US, DIB_INPUT_TO_RENDER_US + 4 # u32
.set DIB_POLL_DIFF_MAX_US, DIB_POLL_DIFF_MIN_US + 4 # u32
.set DIB_FETCH_DIFF_US, DIB_POLL_DIFF_MAX_US + 4 # u32
.set DIB_POLL_TO_FETCH_US, DIB_FETCH_DIFF_US + 4 # u32
.set DIB_POLL_TO_ENGINE_US, DIB_POLL_TO_FETCH_US + 4 # u32
.set DIB_POLL_COUNT, DIB_POLL_TO_ENGINE_US + 4 # u32
.set DIB_SIZE, DIB_POLL_COUNT + 4

################################################################################
# Macros
################################################################################

# Calculates us difference from two ticks
.macro calcDiffUs reg_now, reg_ref
sub r3, \reg_now, \reg_ref # This works even if ticks overflow
mulli r3, r3, 12
lis r4, 0x8000
ori r4, r4, 0x00FC
lwz r4, 0(r4) # Grab CPU speed so that this works on Nintendont (729MHz) and GC/Wii (486MHz)
li r5, 1000
divwu r4, r4, r5
divwu r4, r4, r5 # Divide by 1000 twice because I can't li 1000000
divwu r3, r3, r4
.endm

.macro calcDiffFromFetchUs reg_dib, reg_idx
branchl r12, 0x8034c408 # OSGetTick
mulli r4, \reg_idx, 4
addi r4, r4, DIB_CIRCULAR_BUFFER
lwzx r4, \reg_dib, r4
calcDiffUs r3, r4
.endm

.endif
.set HEADER_DEBUG_INPUTS, 1
