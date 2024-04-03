################################################################################
# Address: FN_ProcessGecko # Inject static fn at the end of the tournament mode section
################################################################################

################################################################################
# Inputs:
# r3 - location of the start of the gecko code list
# r4 - optional callback executed for each gecko code
################################################################################
# Outputs:
# r3 - total size of code section
################################################################################

.include "Common/Common.s"

.set REG_Callback, 30
.set REG_Cursor, 29
.set REG_CodeCount, 28

.set REG_NextCodeDistance, 27
.set REG_StartAddress, 26
.set REG_ReplaceSize, 25

backup

mr REG_Cursor, r3
mr REG_StartAddress, r3

# Move optional callback into reg
mr REG_Callback, r4
li REG_CodeCount, 0

LOOP_START:
lwz r3, 0(REG_Cursor)
rlwinm r3, r3, 8, 0xFE # Load code type into r3. We ignore the last bit because that's the address modification bit

li REG_NextCodeDistance, 8 # Normally it's 8 but this wouldn't work for codes that are longer
li REG_ReplaceSize, 0

cmpwi r3, 0xC0
beq CODE_HANDLER_C0

cmpwi r3, 0xC2
beq CODE_HANDLER_C2

cmpwi r3, 0x04
beq CODE_HANDLER_04

cmpwi r3, 0x06
beq CODE_HANDLER_06

cmpwi r3, 0x08
beq CODE_HANDLER_08

# Here we have not matched a codetype. We look for the exit string and if
# it is not the exit string, we expect to progress by 8 spots to find the
# next code, in this case the callback will not be fired

# Checks if the first word is 0xFX000000
lwz r3, 0(REG_Cursor)
rlwinm r3, r3, 4, 0x0FFFFFFF # Rotate the don't care all the way to the left
cmpwi r3, 0xF
bne CODE_HANDLER_DEFAULT

CHECK_SECOND_EXIT_WORD:
lwz r3, 0x4(REG_Cursor)
cmpwi r3, 0x0
beq LOOP_EXIT

CODE_HANDLER_DEFAULT:
b CODE_HANDLER_COMPLETE

CODE_HANDLER_C0:
lwz r3, 0x4(REG_Cursor) # Get line count
mulli r3, r3, 8 # multiply line count by number of bytes per line
addi REG_NextCodeDistance, r3, 8 # add bytes taken up by first line

b CODE_HANDLER_COMPLETE

CODE_HANDLER_C2:
lwz r3, 0x4(REG_Cursor) # Get line count
mulli r3, r3, 8 # multiply line count by number of bytes per line
addi REG_NextCodeDistance, r3, 8 # add bytes taken up by first line

li REG_ReplaceSize, 4

b CODE_HANDLER_COMPLETE

CODE_HANDLER_04:
li REG_ReplaceSize, 4

b CODE_HANDLER_COMPLETE

CODE_HANDLER_06:
# Use data size and round up to the next address of 8 to fill out a line
lwz r3, 4(REG_Cursor)
addi r3, r3, 7
rlwinm r3, r3, 0, 0xFFFFFFF8 # Remove last 3 bits to round up to next 8
addi REG_NextCodeDistance, r3, 8 # add bytes taken up by first line

lwz REG_ReplaceSize, 4(REG_Cursor)

b CODE_HANDLER_COMPLETE

CODE_HANDLER_08:
li REG_NextCodeDistance, 16

CODE_HANDLER_COMPLETE:
# Increment code count by 1
addi REG_CodeCount, REG_CodeCount, 1

# Skip callback if passed in as null
cmpwi REG_Callback, 0
beq LOOP_CONTINUE

# Execute callback
# Inputs:
# - r3 - Codetype
# - r4 - Code Address
# - r5 - Replaced Code Size
lwz r3, 0(REG_Cursor)
rlwinm r3, r3, 8, 0xFE # Codetype Input
mr r4, REG_Cursor # Code Address Input
mr r5, REG_ReplaceSize
mtctr REG_Callback
bctrl

LOOP_CONTINUE:
add REG_Cursor, REG_Cursor, REG_NextCodeDistance
b LOOP_START

LOOP_EXIT:

# Prepare return values
sub r3, REG_Cursor, REG_StartAddress # Total size

restore
blr
