################################################################################
# Constants
################################################################################
.set INJ_InitDebugInputs, 0x8016e774

.set CIRCULAR_BUFFER_COUNT, 16

.set DIB_ACTIVE_STATE, 0 # u8. 0 = starting, 1 = active, 2 = complete
.set DIB_POLL_INDEX, DIB_ACTIVE_STATE + 1 # u8
.set DIB_COLOR_KEY_DTEXT_ADDR, DIB_POLL_INDEX + 1 # u32
.set DIB_LAG_DISPLAY_DTEXT_ADDR, DIB_COLOR_KEY_DTEXT_ADDR + 4 # u32
.set DIB_LAST_POLL_TIME, DIB_LAG_DISPLAY_DTEXT_ADDR + 4 # u32
.set DIB_CALLBACK_PTR, DIB_LAST_POLL_TIME + 4 # u32
.set DIB_CALLBACK_COUNT, DIB_CALLBACK_PTR + 4 # u32
.set DIB_CIRCULAR_BUFFER, DIB_CALLBACK_COUNT + 4  # u32 * CIRCULAR_BUFFER_COUNT
.set DIB_INPUT_TO_RENDER_US, DIB_CIRCULAR_BUFFER + (4 * CIRCULAR_BUFFER_COUNT) # float
.set DIB_SIZE, DIB_INPUT_TO_RENDER_US + 4

################################################################################
# Macros
################################################################################
.macro incrementByte reg, reg_address, offset, limit
lbz \reg, \offset(\reg_address)
addi \reg, \reg, 1
cmpwi \reg, \limit
blt 0f
li \reg, 0
0:
stb \reg, \offset(\reg_address)
.endm

.macro calcDiffTicksToUs reg_dib, reg_idx
branchl r12, 0x8034c408 # OSGetTick
mulli r4, \reg_idx, 4
addi r4, r4, DIB_CIRCULAR_BUFFER
lwzx r4, \reg_dib, r4
sub r3, r3, r4 # This works even if ticks overflow
mulli r3, r3, 12
li r4, 486
divwu r3, r3, r4
.endm