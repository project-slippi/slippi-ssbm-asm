################################################################################
# Address: FN_ProcessGecko # Inject static fn at the end of the tournament mode section
################################################################################

################################################################################
# Inputs:
# r3 - optional callback executed for each gecko code
################################################################################
# Outputs:
# r3 - total size of code section
# r4 - number of codes
################################################################################

.include "Common/Common.s"

.set REG_Callback, 30
.set REG_Cursor, 29
.set REG_CodeCount, 28

backup

# Move optional callback into reg
mr REG_Callback, r3
li REG_CodeCount, 0

load REG_Cursor, GeckoCodeSectionStart

LOOP_START:
lwz r4, 0(REG_Cursor)
rlwinm r3, r4, 8, 0xFF

cmpwi r3, 0xC2
beq CODE_HANDLER_C2

cmpwi r3, 0x02
beq CODE_HANDLER_04

cmpwi r3, 0x04
beq CODE_HANDLER_04

cmpwi r3, 0x06
beq CODE_HANDLER_06

# Here we have not matched any supported code types, in this case is the
# best idea to just exit? Should make sure we support all code types people use
b LOOP_EXIT

CODE_HANDLER_C2:
lwz r3, 0x4(REG_Cursor) # Get line count
mulli r3, r3, 8 # multiply line count by number of bytes per line
addi r3, r3, 8 # add bytes taken up by first line
add REG_Cursor, REG_Cursor, r3

b CODE_HANDLER_EXIT

CODE_HANDLER_04:
addi REG_Cursor, REG_Cursor, 8

b CODE_HANDLER_EXIT

CODE_HANDLER_06:

CODE_HANDLER_EXIT:
# Increment code count by 1
addi REG_CodeCount, REG_CodeCount, 1

# Skip callback if passed in as null
cmpwi REG_Callback, 0
beq LOOP_START

# Execute callback
mtctr REG_Callback
bctrl
b LOOP_START

LOOP_EXIT:

# Prepare return values
load r3, GeckoCodeSectionStart
sub r3, REG_Cursor, r3 # Total size
mr r4, REG_CodeCount # Number of lines

restore
