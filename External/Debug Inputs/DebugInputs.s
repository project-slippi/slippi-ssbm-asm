
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

.set INJ_InitDebugInputs, 0x8016e774

.set CIRCULAR_BUFFER_COUNT, 10

.set DIB_IS_READY, 0 # u8
.set DIB_POLL_INDEX, DIB_IS_READY + 1 # u8
.set DIB_ENGINE_INDEX, DIB_POLL_INDEX + 1 # u8
.set DIB_CIRCULAR_BUFFER, DIB_ENGINE_INDEX + 1 # u32 * CIRCULAR_BUFFER_COUNT
.set DIB_SIZE, DIB_CIRCULAR_BUFFER + (4 * CIRCULAR_BUFFER_COUNT)